using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class MicroLearningService : IMicroLearningService
    {
        private readonly IUnitOfWork _unitOfWork;

        public MicroLearningService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        private async Task EnsureSeedDataAsync()
        {
            var existingCards = await _unitOfWork.MicroLearningCards.GetAllAsync();
            if (existingCards.Any())
            {
                return;
            }

            throw new InvalidOperationException(
                "Micro-learning cards are empty. Please run the seed script at backend/database/49_micro_learning_cards.sql before starting the app."
            );
        }

        public async Task<IEnumerable<MicroLearningCardResponse>> GetRecommendedCardsAsync(Guid userId)
        {
            await EnsureSeedDataAsync();

            var healthProfile = (await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId)).FirstOrDefault();
            var aiProfile = (await _unitOfWork.UserAiProfiles.FindAsync(p => p.UserId == userId)).FirstOrDefault();
            var isOfficeUser = string.Equals(aiProfile?.EatingPattern?.Trim().Trim('"'), "office", StringComparison.OrdinalIgnoreCase);
            var allergies = (await _unitOfWork.Allergies.FindAsync(a => a.UserId == userId && a.IsActive)).ToList();

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var threeDaysAgo = today.AddDays(-2);
            var logs = (await _unitOfWork.MealLogs.FindAsync(l =>
                l.UserId == userId &&
                l.LoggedAt.HasValue &&
                DateOnly.FromDateTime(l.LoggedAt.Value) >= threeDaysAgo &&
                DateOnly.FromDateTime(l.LoggedAt.Value) <= today)).ToList();

            // 1. Quét phát hiện vấn đề
            bool isProteinDeficient = false;
            bool isFatExcess = false;
            bool hasMilkAllergy = allergies.Any(a => a.Name.Contains("sữa", StringComparison.OrdinalIgnoreCase) || a.Name.Contains("milk", StringComparison.OrdinalIgnoreCase));
            bool hasSeafoodAllergy = allergies.Any(a => a.Name.Contains("hải sản", StringComparison.OrdinalIgnoreCase) || a.Name.Contains("seafood", StringComparison.OrdinalIgnoreCase) || a.Name.Contains("tôm", StringComparison.OrdinalIgnoreCase) || a.Name.Contains("cá", StringComparison.OrdinalIgnoreCase));

            if (logs.Any() && healthProfile != null)
            {
                var avgProtein = logs.Sum(l => l.ProteinG ?? 0) / 3m;
                var avgFat = logs.Sum(l => l.FatG ?? 0) / 3m;

                if (healthProfile.TargetProteinG > 0 && avgProtein < (decimal)healthProfile.TargetProteinG * 0.7m)
                {
                    isProteinDeficient = true;
                }

                if (healthProfile.TargetFatG > 0 && avgFat > (decimal)healthProfile.TargetFatG * 1.2m)
                {
                    isFatExcess = true;
                }
            }

            // 2. Xác định các Category được đề xuất
            var targetCategories = new List<string> { "General", "Hydration" };
            if (isOfficeUser) targetCategories.Add("Office");
            if (isProteinDeficient) targetCategories.Add("Protein");
            if (isFatExcess) targetCategories.Add("Sodium");
            if (hasMilkAllergy || hasSeafoodAllergy) targetCategories.Add("Allergy");

            // 3. Lấy tất cả card thuộc các category này
            var allCards = (await _unitOfWork.MicroLearningCards.FindAsync(c => c.IsActive && targetCategories.Contains(c.Category))).ToList();

            // 4. Lấy tương tác của user
            var interactions = (await _unitOfWork.UserCardInteractions.FindAsync(i => i.UserId == userId)).ToDictionary(i => i.CardId);

            var recommendedList = new List<MicroLearningCard>();

            foreach (var card in allCards)
            {
                // Bỏ qua nếu user đã Dismiss
                if (interactions.TryGetValue(card.Id, out var interaction) && interaction.IsDismissed)
                {
                    continue;
                }

                // Nếu là thẻ dị ứng sữa nhưng user không dị ứng sữa, bỏ qua
                if (card.Category == "Allergy" && card.Title.Contains("sữa", StringComparison.OrdinalIgnoreCase) && !hasMilkAllergy)
                {
                    continue;
                }

                // Nếu là thẻ dị ứng hải sản nhưng user không dị ứng hải sản, bỏ qua
                if (card.Category == "Allergy" && card.Title.Contains("hải sản", StringComparison.OrdinalIgnoreCase) && !hasSeafoodAllergy)
                {
                    continue;
                }

                recommendedList.Add(card);
            }

            // 5. Sắp xếp thứ tự ưu tiên:
            // - Ưu tiên các thẻ giải quyết vấn đề sức khỏe trước (Protein, Sodium, Allergy) so với các thẻ General/Hydration
            // - Ưu tiên thẻ chưa đọc
            // - Ưu tiên thẻ chưa hoàn thành quiz
            var sortedList = recommendedList
                .OrderByDescending(c => isOfficeUser && c.Category == "Office")
                .ThenByDescending(c => c.Category == "Protein" || c.Category == "Sodium" || c.Category == "Allergy")
                .ThenBy(c => interactions.TryGetValue(c.Id, out var inter) && inter.IsRead ? 1 : 0)
                .ThenBy(c => interactions.TryGetValue(c.Id, out var inter) && inter.IsQuizCompleted ? 1 : 0)
                .Take(3)
                .ToList();

            // Nếu không đủ 3 thẻ, lấy thêm bất kỳ thẻ active nào chưa bị dismiss
            if (sortedList.Count < 3)
            {
                var extraCards = (await _unitOfWork.MicroLearningCards.FindAsync(c => c.IsActive)).ToList();
                foreach (var card in extraCards)
                {
                    if (sortedList.Any(s => s.Id == card.Id)) continue;
                    if (interactions.TryGetValue(card.Id, out var inter) && inter.IsDismissed) continue;
                    
                    sortedList.Add(card);
                    if (sortedList.Count >= 3) break;
                }
            }

            return sortedList.Select(c => MapToResponse(c, interactions.TryGetValue(c.Id, out var inter) ? inter : null));
        }

        public async Task<MicroLearningCardResponse> GetCardByIdAsync(Guid id, Guid userId)
        {
            await EnsureSeedDataAsync();
            var card = await _unitOfWork.MicroLearningCards.GetByIdAsync(id) ?? throw new Exception("Micro-learning card not found.");
            
            var interactions = await _unitOfWork.UserCardInteractions.FindAsync(i => i.UserId == userId && i.CardId == id);
            var interaction = interactions.FirstOrDefault();

            return MapToResponse(card, interaction);
        }

        public async Task<IEnumerable<MicroLearningCategoryResponse>> GetCategoriesAsync()
        {
            await EnsureSeedDataAsync();
            var cards = await _unitOfWork.MicroLearningCards.FindAsync(c => c.IsActive);
            var cardList = cards.ToList();

            var categories = new List<MicroLearningCategoryResponse>
            {
                new MicroLearningCategoryResponse
                {
                    Name = "Protein",
                    DisplayName = "Chất đạm (Protein)",
                    Description = "Mẹo bổ sung đạm tinh khiết, hỗ trợ tăng cơ và kiểm soát mỡ thừa.",
                    Icon = "fitness_center",
                    TotalCards = cardList.Count(c => c.Category == "Protein")
                },
                new MicroLearningCategoryResponse
                {
                    Name = "Sodium",
                    DisplayName = "Muối & Natri (Sodium)",
                    Description = "Nhận diện Natri ẩn trong đồ chế biến sẵn, phòng ngừa giữ nước và cao huyết áp.",
                    Icon = "opacity",
                    TotalCards = cardList.Count(c => c.Category == "Sodium")
                },
                new MicroLearningCategoryResponse
                {
                    Name = "Allergy",
                    DisplayName = "Dị ứng dinh dưỡng",
                    Description = "Giải pháp thay thế dưỡng chất thiết yếu khi cơ thể dị ứng sữa bò, hải sản, gluten.",
                    Icon = "warning",
                    TotalCards = cardList.Count(c => c.Category == "Allergy")
                },
                new MicroLearningCategoryResponse
                {
                    Name = "Hydration",
                    DisplayName = "Nước & Khoáng",
                    Description = "Phương pháp bù nước đúng cách nâng cao hiệu suất trao đổi chất.",
                    Icon = "local_drink",
                    TotalCards = cardList.Count(c => c.Category == "Hydration")
                },
                new MicroLearningCategoryResponse
                {
                    Name = "General",
                    DisplayName = "Dinh dưỡng cơ bản",
                    Description = "Kiến thức nhập môn giúp xây dựng chế độ ăn uống cân bằng.",
                    Icon = "menu_book",
                    TotalCards = cardList.Count(c => c.Category == "General")
                }
            };

            return categories;
        }

        public async Task<bool> RecordCardActionAsync(Guid userId, Guid cardId, string action)
        {
            var card = await _unitOfWork.MicroLearningCards.GetByIdAsync(cardId) ?? throw new Exception("Micro-learning card not found.");

            var interactions = await _unitOfWork.UserCardInteractions.FindAsync(i => i.UserId == userId && i.CardId == cardId);
            var interaction = interactions.FirstOrDefault();
            bool isNew = false;

            if (interaction == null)
            {
                interaction = new UserCardInteraction
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    CardId = cardId,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.UserCardInteractions.AddAsync(interaction);
                isNew = true;
            }

            switch (action.Trim().ToLower())
            {
                case "read":
                    interaction.IsRead = true;
                    break;
                case "save":
                    interaction.IsSaved = true;
                    break;
                case "unsave":
                    interaction.IsSaved = false;
                    break;
                case "dismiss":
                    interaction.IsDismissed = true;
                    break;
                default:
                    throw new ArgumentException("Invalid action. Only 'read', 'save', 'unsave', 'dismiss' are accepted.");
            }

            interaction.UpdatedAt = DateTime.UtcNow;
            if (!isNew)
            {
                _unitOfWork.UserCardInteractions.Update(interaction);
            }
            await _unitOfWork.CompleteAsync();

            return true;
        }

        public async Task<IEnumerable<MicroLearningCardResponse>> GetSavedCardsAsync(Guid userId)
        {
            await EnsureSeedDataAsync();
            var interactions = (await _unitOfWork.UserCardInteractions.FindAsync(i => i.UserId == userId && i.IsSaved)).ToList();
            if (!interactions.Any())
            {
                return Enumerable.Empty<MicroLearningCardResponse>();
            }

            var cardIds = interactions.Select(i => i.CardId).ToList();
            var cards = (await _unitOfWork.MicroLearningCards.FindAsync(c => cardIds.Contains(c.Id) && c.IsActive)).ToDictionary(c => c.Id);
            var interactionMap = interactions.ToDictionary(i => i.CardId);

            return cards.Values.Select(c => MapToResponse(c, interactionMap[c.Id]));
        }

        public async Task<QuizSubmitResponse> SubmitQuizAnswerAsync(Guid userId, Guid cardId, int selectedOptionIndex)
        {
            var card = await _unitOfWork.MicroLearningCards.GetByIdAsync(cardId) ?? throw new Exception("Micro-learning card not found.");
            if (!card.CorrectOptionIndex.HasValue || string.IsNullOrEmpty(card.QuizQuestion))
            {
                throw new Exception("This micro-learning card does not have an attached quiz question.");
            }

            var interactions = await _unitOfWork.UserCardInteractions.FindAsync(i => i.UserId == userId && i.CardId == cardId);
            var interaction = interactions.FirstOrDefault();
            bool isNew = false;

            if (interaction == null)
            {
                interaction = new UserCardInteraction
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    CardId = cardId
                };
                await _unitOfWork.UserCardInteractions.AddAsync(interaction);
                isNew = true;
            }

            if (interaction.IsQuizCompleted)
            {
                throw new Exception("You have already completed this quiz question.");
            }

            bool isCorrect = card.CorrectOptionIndex.Value == selectedOptionIndex;
            int pointsEarned = isCorrect ? card.PointsReward : 0;

            interaction.IsQuizCompleted = true;
            interaction.SelectedQuizOption = selectedOptionIndex;
            interaction.IsQuizCorrect = isCorrect;
            interaction.UpdatedAt = DateTime.UtcNow;

            if (!isNew)
            {
                _unitOfWork.UserCardInteractions.Update(interaction);
            }
            await _unitOfWork.CompleteAsync();

            string feedback = isCorrect
                ? "Chính xác! Chúc mừng bạn đã trả lời đúng câu hỏi và tích lũy được điểm thói quen."
                : $"Chưa chính xác. Đáp án đúng là phương án số {card.CorrectOptionIndex.Value + 1}. Hãy đọc lại thẻ kiến thức để nắm vững thông tin nhé.";

            return new QuizSubmitResponse
            {
                IsCorrect = isCorrect,
                CorrectOptionIndex = card.CorrectOptionIndex.Value,
                Feedback = feedback,
                PointsEarned = pointsEarned
            };
        }

        public async Task<MicroLearningCardResponse> CreateCardAsync(MicroLearningCardUpsertRequest request)
        {
            var card = new MicroLearningCard
            {
                Id = Guid.NewGuid(),
                Title = request.Title,
                Summary = request.Summary,
                Category = request.Category,
                Tips = request.Tips,
                ImageUrl = request.ImageUrl,
                QuizQuestion = request.QuizQuestion,
                QuizOptions = request.QuizOptions,
                CorrectOptionIndex = request.CorrectOptionIndex,
                PointsReward = request.PointsReward,
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MicroLearningCards.AddAsync(card);
            await _unitOfWork.CompleteAsync();

            return MapToResponse(card, null);
        }

        public async Task<MicroLearningCardResponse> UpdateCardAsync(Guid id, MicroLearningCardUpsertRequest request)
        {
            var card = await _unitOfWork.MicroLearningCards.GetByIdAsync(id)
                ?? throw new Exception("Micro-learning card not found.");

            card.Title = request.Title;
            card.Summary = request.Summary;
            card.Category = request.Category;
            card.Tips = request.Tips;
            card.ImageUrl = request.ImageUrl;
            card.QuizQuestion = request.QuizQuestion;
            card.QuizOptions = request.QuizOptions;
            card.CorrectOptionIndex = request.CorrectOptionIndex;
            card.PointsReward = request.PointsReward;
            card.IsActive = request.IsActive;

            _unitOfWork.MicroLearningCards.Update(card);
            await _unitOfWork.CompleteAsync();

            // Lấy interaction map để trả về đầy đủ thông tin
            var interactionMap = (await _unitOfWork.UserCardInteractions
                .FindAsync(i => i.CardId == id))
                .ToDictionary(i => i.UserId);

            // Note: MapToResponse hiện tại chỉ nhận 1 interaction, 
            // với admin view thì IsSaved/IsRead thường là false
            return MapToResponse(card, null);
        }

        public async Task<bool> DeleteCardAsync(Guid id)
        {
            var card = await _unitOfWork.MicroLearningCards.GetByIdAsync(id)
                ?? throw new Exception("Micro-learning card not found.");

            _unitOfWork.MicroLearningCards.Remove(card);
            await _unitOfWork.CompleteAsync();

            return true;
        }

        public async Task<PagedResult<MicroLearningCardResponse>> GetAllCardsAsync(int page, int pageSize)
        {
            var query = await _unitOfWork.MicroLearningCards.GetAllAsync();
            var totalCount = query.Count();

            var cards = query
                .OrderByDescending(c => c.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            return new PagedResult<MicroLearningCardResponse>
            {
                Items = cards.Select(c => MapToResponse(c, null)).ToList(),
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        private static MicroLearningCardResponse MapToResponse(MicroLearningCard card, UserCardInteraction? interaction)
        {
            var tipsList = string.IsNullOrWhiteSpace(card.Tips)
                ? new List<string>()
                : card.Tips.Split('|', StringSplitOptions.RemoveEmptyEntries).Select(t => t.Trim()).ToList();

            var optionsList = string.IsNullOrWhiteSpace(card.QuizOptions)
                ? new List<string>()
                : card.QuizOptions.Split('|', StringSplitOptions.RemoveEmptyEntries).Select(o => o.Trim()).ToList();

            return new MicroLearningCardResponse
            {
                Id = card.Id,
                Title = card.Title,
                Summary = card.Summary,
                Category = card.Category,
                Tips = tipsList,
                ImageUrl = card.ImageUrl,
                QuizQuestion = card.QuizQuestion,
                QuizOptions = optionsList,
                PointsReward = card.PointsReward,
                IsSaved = interaction?.IsSaved ?? false,
                IsRead = interaction?.IsRead ?? false,
                IsQuizCompleted = interaction?.IsQuizCompleted ?? false,
                IsQuizCorrect = interaction?.IsQuizCorrect,
                SelectedQuizOption = interaction?.SelectedQuizOption
            };
        }
    }
}
