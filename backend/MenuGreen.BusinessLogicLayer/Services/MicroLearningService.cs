using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
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

            var seedCards = new List<MicroLearningCard>
            {
                new MicroLearningCard
                {
                    Id = Guid.NewGuid(),
                    Title = "Làm sao tăng đạm không tăng mỡ?",
                    Summary = "Để tăng cơ hoặc hỗ trợ giảm béo mà không nạp quá nhiều calo, việc chọn đúng nguồn đạm tinh khiết là vô cùng quan trọng. Bạn nên ưu tiên đạm trắng từ ức gà, cá, lòng trắng trứng, hoặc các nguồn đạm thực vật từ đậu hũ, các loại đậu hạt thay vì đạm đỏ từ thịt bò, thịt heo nhiều mỡ.",
                    Category = "Protein",
                    Tips = "Ưu tiên ức gà bỏ da và các loại cá hấp thay vì chiên rán|Bổ sung đạm thực vật để đa dạng dinh dưỡng|Tránh thịt đỏ chế biến sẵn như xúc xích, thịt xông khói",
                    ImageUrl = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c",
                    QuizQuestion = "Nguồn đạm nào sau đây ít calo và chất béo bão hòa nhất?",
                    QuizOptions = "Thịt ba chỉ heo|Ức gà bỏ da|Thịt bò bít tết nhiều vân mỡ|Lạp xưởng rán",
                    CorrectOptionIndex = 1,
                    PointsReward = 10,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new MicroLearningCard
                {
                    Id = Guid.NewGuid(),
                    Title = "Nhận diện Natri ẩn trong đồ ăn ngoài",
                    Summary = "Ăn ngoài quán hoặc dùng đồ ăn chế biến sẵn thường khiến bạn nạp quá nhiều muối (Natri) mà không hề hay biết. Natri ẩn rất nhiều trong nước lèo hủ tiếu/phở, nước sốt chấm, dưa muối, và các gia vị tẩm ướp sẵn để tăng vị đậm đà.",
                    Category = "Sodium",
                    Tips = "Không húp hết nước lèo khi ăn bún, phở ngoài tiệm|Yêu cầu ít sốt hoặc để sốt chấm riêng khi gọi món|Đọc kỹ nhãn dinh dưỡng và tránh sản phẩm có lượng Natri vượt quá 20% DV",
                    ImageUrl = "https://images.unsplash.com/photo-1502741126161-b048400d085d",
                    QuizQuestion = "Muối ẩn (Natri) thường xuất hiện nhiều nhất ở đâu khi đi ăn ngoài tiệm?",
                    QuizOptions = "Rau xà lách sống|Nước lèo bún, phở và nước sốt chấm|Cơm trắng|Nước lọc nguội",
                    CorrectOptionIndex = 1,
                    PointsReward = 10,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new MicroLearningCard
                {
                    Id = Guid.NewGuid(),
                    Title = "Thay thế Canxi khi bị dị ứng sữa bò",
                    Summary = "Nếu bạn bị dị ứng sữa bò hoặc bất dung nạp đường lactose, sữa không còn là nguồn canxi an toàn. Tuy nhiên, bạn vẫn có thể nạp đủ canxi từ thực vật và các loại sữa thay thế lành mạnh khác.",
                    Category = "Allergy",
                    Tips = "Sử dụng sữa hạt được bổ sung canxi (như sữa đậu nành, sữa hạnh nhân)|Tăng cường ăn rau lá xanh đậm như rau cải xoăn, cải bó xôi|Bổ sung các loại cá ăn cả xương như cá mòi, cá diếc",
                    ImageUrl = "https://images.unsplash.com/photo-1550583724-b2692b85b150",
                    QuizQuestion = "Thực phẩm thực vật nào sau đây là nguồn cung cấp canxi dồi dào phù hợp cho người dị ứng sữa bò?",
                    QuizOptions = "Khoai tây chiên|Rau cải xoăn (kale) và cải bó xôi|Cơm nếp|Bột mì trắng",
                    CorrectOptionIndex = 1,
                    PointsReward = 10,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new MicroLearningCard
                {
                    Id = Guid.NewGuid(),
                    Title = "Bí quyết thay đạm khi dị ứng hải sản",
                    Summary = "Hải sản là nguồn cung cấp axit béo Omega-3 (EPA và DHA) dồi dào giúp bảo vệ tim mạch. Nếu bị dị ứng hải sản, bạn cần tìm nguồn cung cấp chất béo lành mạnh từ thực vật hoặc dầu tảo thay thế.",
                    Category = "Allergy",
                    Tips = "Sử dụng dầu tảo (algae oil) chứa DHA tinh khiết từ thực vật|Bổ sung hạt lanh, hạt chia, và quả óc chó trong thực đơn|Sử dụng dầu hạt cải hoặc dầu đậu nành để nấu ăn",
                    ImageUrl = "https://images.unsplash.com/photo-1534422298391-e4f8c172dddb",
                    QuizQuestion = "Nguồn chất béo thực vật nào sau đây giàu Omega-3 (ALA) thích hợp cho người dị ứng hải sản?",
                    QuizOptions = "Mỡ heo|Hạt chia và hạt lanh|Bơ thực vật chứa nhiều chất béo chuyển hóa|Dầu dừa tinh luyện",
                    CorrectOptionIndex = 1,
                    PointsReward = 10,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new MicroLearningCard
                {
                    Id = Guid.NewGuid(),
                    Title = "Nguyên tắc uống nước 8x8 khoa học",
                    Summary = "Nước đóng vai trò thiết yếu giúp thải độc, hỗ trợ tiêu hóa và kiểm soát cơn đói. Quy tắc 8x8 khuyên bạn nên uống 8 ly nước mỗi ly khoảng 240ml (khoảng 2 lít nước) mỗi ngày, phân bổ đều thay vì uống dồn dập một lúc.",
                    Category = "Hydration",
                    Tips = "Uống 1 ly nước ấm ngay khi thức dậy|Uống nước trước bữa ăn 30 phút để hỗ trợ tiêu hóa và tránh ăn quá nhiều|Mang theo bình nước cá nhân để nhắc nhở bản thân uống đều đặn",
                    ImageUrl = "https://images.unsplash.com/photo-1548839134-2472e395222f",
                    QuizQuestion = "Thời điểm nào uống nước tốt nhất giúp hỗ trợ hệ tiêu hóa và hạn chế ăn quá đà?",
                    QuizOptions = "Ngay sau khi ăn no xong|30 phút trước bữa ăn|Trong khi đang nhai đồ ăn|Chỉ uống khi thấy thật khát",
                    CorrectOptionIndex = 1,
                    PointsReward = 10,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                }
            };

            foreach (var card in seedCards)
            {
                await _unitOfWork.MicroLearningCards.AddAsync(card);
            }
            await _unitOfWork.CompleteAsync();
        }

        public async Task<IEnumerable<MicroLearningCardResponse>> GetRecommendedCardsAsync(Guid userId)
        {
            await EnsureSeedDataAsync();

            var healthProfile = (await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId)).FirstOrDefault();
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
                .OrderByDescending(c => c.Category == "Protein" || c.Category == "Sodium" || c.Category == "Allergy")
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
            var card = await _unitOfWork.MicroLearningCards.GetByIdAsync(id) ?? throw new Exception("Không tìm thấy thẻ kiến thức.");
            
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
            var card = await _unitOfWork.MicroLearningCards.GetByIdAsync(cardId) ?? throw new Exception("Không tìm thấy thẻ kiến thức.");

            var interactions = await _unitOfWork.UserCardInteractions.FindAsync(i => i.UserId == userId && i.CardId == cardId);
            var interaction = interactions.FirstOrDefault();

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
                    throw new ArgumentException("Hành động không hợp lệ. Chỉ chấp nhận 'read', 'save', 'unsave', 'dismiss'.");
            }

            interaction.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.UserCardInteractions.Update(interaction);
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
            var card = await _unitOfWork.MicroLearningCards.GetByIdAsync(cardId) ?? throw new Exception("Không tìm thấy thẻ kiến thức.");
            if (!card.CorrectOptionIndex.HasValue || string.IsNullOrEmpty(card.QuizQuestion))
            {
                throw new Exception("Thẻ kiến thức này không đính kèm câu hỏi đố vui.");
            }

            var interactions = await _unitOfWork.UserCardInteractions.FindAsync(i => i.UserId == userId && i.CardId == cardId);
            var interaction = interactions.FirstOrDefault();

            if (interaction == null)
            {
                interaction = new UserCardInteraction
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    CardId = cardId
                };
                await _unitOfWork.UserCardInteractions.AddAsync(interaction);
            }

            if (interaction.IsQuizCompleted)
            {
                throw new Exception("Bạn đã hoàn thành câu hỏi đố vui này trước đó.");
            }

            bool isCorrect = card.CorrectOptionIndex.Value == selectedOptionIndex;
            int pointsEarned = isCorrect ? card.PointsReward : 0;

            interaction.IsQuizCompleted = true;
            interaction.SelectedQuizOption = selectedOptionIndex;
            interaction.IsQuizCorrect = isCorrect;
            interaction.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.UserCardInteractions.Update(interaction);
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
