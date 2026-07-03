using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class AiAssistantService : IAiAssistantService
    {
        private const string DefaultWorkerChatUrl = "http://127.0.0.1:8000/worker/chat";
        private readonly ApplicationDbContext _db;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
        {
            PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        };

        public AiAssistantService(
            ApplicationDbContext db,
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration)
        {
            _db = db;
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
        }

        // ==========================================
        // A. Conversation Lifecycle
        // ==========================================

        public async Task<AiConversationResponse> CreateConversationAsync(Guid userId, CreateConversationRequest request)
        {
            var title = "Hội thoại mới";
            if (!string.IsNullOrWhiteSpace(request.FirstMessage))
            {
                title = BuildConversationTitle(request.FirstMessage);
            }

            var conversation = new AiConversation
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = title,
                CreatedAt = DateTimeOffset.UtcNow
            };

            _db.AiConversations.Add(conversation);

            // If a first message was provided, save it as a user message
            if (!string.IsNullOrWhiteSpace(request.FirstMessage))
            {
                var userMsg = new AiMessage
                {
                    Id = Guid.NewGuid(),
                    ConversationId = conversation.Id,
                    Role = "user",
                    Content = request.FirstMessage.Trim(),
                    CreatedAt = DateTimeOffset.UtcNow
                };
                _db.AiMessages.Add(userMsg);
            }

            await _db.SaveChangesAsync();

            return new AiConversationResponse
            {
                Id = conversation.Id,
                UserId = conversation.UserId,
                Title = conversation.Title,
                CreatedAt = conversation.CreatedAt ?? DateTimeOffset.UtcNow
            };
        }

        public async Task<IEnumerable<AiConversationResponse>> GetConversationsAsync(Guid userId)
        {
            var list = await _db.AiConversations
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync();

            return list.Select(x => new AiConversationResponse
            {
                Id = x.Id,
                UserId = x.UserId,
                Title = x.Title,
                CreatedAt = x.CreatedAt ?? DateTimeOffset.UtcNow
            });
        }

        public async Task<AiConversationResponse> GetConversationByIdAsync(Guid userId, Guid conversationId)
        {
            var conversation = await _db.AiConversations
                .FirstOrDefaultAsync(x => x.UserId == userId && x.Id == conversationId);

            if (conversation == null)
            {
                throw new Exception("Conversation not found.");
            }

            return new AiConversationResponse
            {
                Id = conversation.Id,
                UserId = conversation.UserId,
                Title = conversation.Title,
                CreatedAt = conversation.CreatedAt ?? DateTimeOffset.UtcNow
            };
        }

        public async Task DeleteConversationAsync(Guid userId, Guid conversationId)
        {
            var conversation = await _db.AiConversations
                .FirstOrDefaultAsync(x => x.UserId == userId && x.Id == conversationId);

            if (conversation != null)
            {
                _db.AiConversations.Remove(conversation);
                await _db.SaveChangesAsync();
            }
        }

        public async Task<AiConversationResponse> UpdateConversationTitleAsync(Guid userId, Guid conversationId, string newTitle)
        {
            var conversation = await _db.AiConversations
                .FirstOrDefaultAsync(x => x.UserId == userId && x.Id == conversationId);

            if (conversation == null)
            {
                throw new Exception("Conversation not found.");
            }

            conversation.Title = newTitle.Trim();
            _db.AiConversations.Update(conversation);
            await _db.SaveChangesAsync();

            return new AiConversationResponse
            {
                Id = conversation.Id,
                UserId = conversation.UserId,
                Title = conversation.Title,
                CreatedAt = conversation.CreatedAt ?? DateTimeOffset.UtcNow
            };
        }

        // ==========================================
        // B. Message Workflow
        // ==========================================

        public async Task<AiMessageResponse> SendMessageAsync(Guid userId, Guid conversationId, SendMessageRequest request)
        {
            var conversation = await _db.AiConversations
                .FirstOrDefaultAsync(x => x.UserId == userId && x.Id == conversationId);

            if (conversation == null)
            {
                throw new Exception("Conversation not found.");
            }

            var context = await BuildUserContextAsync(userId);
            var conversationHistory = await BuildConversationHistoryAsync(conversationId, context);

            // 1. Save User Message
            var userMessage = new AiMessage
            {
                Id = Guid.NewGuid(),
                ConversationId = conversationId,
                Role = "user",
                Content = request.Message.Trim(),
                CreatedAt = DateTimeOffset.UtcNow
            };
            _db.AiMessages.Add(userMessage);
            await _db.SaveChangesAsync();

            // 2. Query AI Worker
            var workerResponse = await CallWorkerAsync(
                userId,
                request.Message,
                conversationId,
                conversationHistory,
                request.Language,
                request.Stream);

            // 3. Save Assistant Message
            var assistantMessage = new AiMessage
            {
                Id = Guid.NewGuid(),
                ConversationId = conversationId,
                Role = "assistant",
                Content = workerResponse.Response,
                CreatedAt = DateTimeOffset.UtcNow
            };
            _db.AiMessages.Add(assistantMessage);

            // Auto-update title if it's default
            if (conversation.Title == "Hội thoại mới" || string.IsNullOrWhiteSpace(conversation.Title))
            {
                conversation.Title = BuildConversationTitle(request.Message);
                _db.AiConversations.Update(conversation);
            }

            await _db.SaveChangesAsync();

            return new AiMessageResponse
            {
                Id = assistantMessage.Id,
                ConversationId = conversationId,
                Role = "assistant",
                Content = assistantMessage.Content ?? string.Empty,
                TokensUsed = 0,
                CreatedAt = assistantMessage.CreatedAt ?? DateTimeOffset.UtcNow,
                Feedback = null
            };
        }

        public async Task<IEnumerable<AiMessageResponse>> GetMessagesAsync(Guid userId, Guid conversationId)
        {
            var conversation = await _db.AiConversations
                .AnyAsync(x => x.UserId == userId && x.Id == conversationId);

            if (!conversation)
            {
                throw new Exception("Conversation not found.");
            }

            var messages = await _db.AiMessages
                .Where(x => x.ConversationId == conversationId)
                .OrderBy(x => x.CreatedAt)
                .ToListAsync();

            return messages.Select(x => new AiMessageResponse
            {
                Id = x.Id,
                ConversationId = x.ConversationId,
                Role = x.Role ?? "user",
                Content = x.Content ?? string.Empty,
                TokensUsed = x.TokensUsed,
                CreatedAt = x.CreatedAt ?? DateTimeOffset.UtcNow,
                Feedback = null // In real implementation, can check linked feedbacks if any
            });
        }

        public async Task<AiMessageResponse> RegenerateMessageAsync(Guid userId, Guid conversationId, Guid messageId)
        {
            var conversation = await _db.AiConversations
                .FirstOrDefaultAsync(x => x.UserId == userId && x.Id == conversationId);

            if (conversation == null)
            {
                throw new Exception("Conversation not found.");
            }

            var targetMsg = await _db.AiMessages
                .FirstOrDefaultAsync(x => x.ConversationId == conversationId && x.Id == messageId);

            if (targetMsg == null || targetMsg.Role != "assistant")
            {
                throw new Exception("Assistant message not found.");
            }

            // Find preceding user message to prompt AI again
            var prevUserMsg = await _db.AiMessages
                .Where(x => x.ConversationId == conversationId && x.CreatedAt < targetMsg.CreatedAt && x.Role == "user")
                .OrderByDescending(x => x.CreatedAt)
                .FirstOrDefaultAsync();

            var promptText = prevUserMsg?.Content ?? "Hãy tư vấn dinh dưỡng cho tôi.";

            // Call AI worker again
            var context = await BuildUserContextAsync(userId);
            var conversationHistory = await BuildConversationHistoryAsync(conversationId, context, targetMsg.CreatedAt);
            var workerResponse = await CallWorkerAsync(userId, promptText, conversationId, conversationHistory);

            // Update content and timestamp of the assistant message
            targetMsg.Content = workerResponse.Response;
            targetMsg.CreatedAt = DateTimeOffset.UtcNow;
            _db.AiMessages.Update(targetMsg);
            await _db.SaveChangesAsync();

            return new AiMessageResponse
            {
                Id = targetMsg.Id,
                ConversationId = conversationId,
                Role = "assistant",
                Content = targetMsg.Content ?? string.Empty,
                CreatedAt = targetMsg.CreatedAt ?? DateTimeOffset.UtcNow
            };
        }

        public async Task FeedbackMessageAsync(Guid userId, Guid conversationId, Guid messageId, MessageFeedbackRequest request)
        {
            var conversationExists = await _db.AiConversations
                .AnyAsync(x => x.UserId == userId && x.Id == conversationId);

            if (!conversationExists)
            {
                throw new Exception("Conversation not found.");
            }

            var msg = await _db.AiMessages
                .FirstOrDefaultAsync(x => x.ConversationId == conversationId && x.Id == messageId);

            if (msg == null)
            {
                throw new Exception("Message not found.");
            }

            await CreateWorkerFeedbackAsync(userId, conversationId, msg, request);
        }

        // ==========================================
        // C. Context & Profile
        // ==========================================

        public async Task<AiAssistantContextResponse> GetContextAsync(Guid userId)
        {
            var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(x => x.Id == userId);
            var profile = await _db.Profiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var healthProfile = await _db.HealthProfiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var allergies = await _db.Allergies.AsNoTracking()
                .Where(x => x.UserId == userId && x.IsActive)
                .Select(x => x.Name)
                .ToListAsync();
            var recentNutrition = await _db.NutritionSnapshots.AsNoTracking()
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.SnapshotDate)
                .FirstOrDefaultAsync();

            var aiProfile = await _db.UserAiProfiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var hasAllergies = allergies.Count > 0;
            var allergyCount = allergies.Count;
            var hasSnapshot = recentNutrition != null;
            var allergiesAcknowledged = UserAiProfilePreferencesHelper.TryGetAllergiesAcknowledged(aiProfile?.Preferences);

            var completedSteps = new List<string>();
            if (profile != null && !string.IsNullOrWhiteSpace(profile.FullName) && !string.IsNullOrWhiteSpace(profile.Gender))
            {
                completedSteps.Add("Profile");
            }
            if (healthProfile != null && healthProfile.HeightCm.HasValue && healthProfile.WeightKg.HasValue && !string.IsNullOrWhiteSpace(healthProfile.ActivityLevel))
            {
                completedSteps.Add("HealthProfile");
            }
            if (hasAllergies || allergiesAcknowledged)
            {
                completedSteps.Add("Allergies");
            }
            if (healthProfile != null && !string.IsNullOrWhiteSpace(healthProfile.Goal) && healthProfile.TargetCalories.HasValue)
            {
                completedSteps.Add("Goal");
            }
            if (aiProfile != null && UserAiProfilePreferencesHelper.HasMeaningfulAiProfile(aiProfile.Preferences, aiProfile.EatingPattern, aiProfile.DislikedFoods))
            {
                completedSteps.Add("UserAiProfile");
            }
            if (hasSnapshot)
            {
                completedSteps.Add("NutritionSnapshot");
            }

            ProfileSummaryResponse? profSummary = null;
            if (profile != null)
            {
                profSummary = new ProfileSummaryResponse
                {
                    UserId = profile.UserId,
                    Email = user?.Email ?? string.Empty,
                    FullName = profile.FullName,
                    AvatarUrl = profile.AvatarUrl,
                    Gender = profile.Gender,
                    DateOfBirth = profile.DateOfBirth,
                    PreferredCuisine = profile.PreferredCuisine,
                    HeightCm = healthProfile?.HeightCm,
                    WeightKg = healthProfile?.WeightKg,
                    BodyFatPercent = healthProfile?.BodyFatPercent,
                    ActivityLevel = healthProfile?.ActivityLevel ?? string.Empty,
                    Goal = healthProfile?.Goal,
                    Bmi = healthProfile?.Bmi,
                    BmrKcal = healthProfile?.BmrKcal,
                    TdeeKcal = healthProfile?.TdeeKcal,
                    TargetCalories = healthProfile?.TargetCalories,
                    TargetProteinG = healthProfile?.TargetProteinG,
                    TargetCarbsG = healthProfile?.TargetCarbsG,
                    TargetFatG = healthProfile?.TargetFatG,
                    AllergyCount = allergyCount,
                    HasProfile = !string.IsNullOrWhiteSpace(profile.FullName) && !string.IsNullOrWhiteSpace(profile.Gender),
                    HasHealthProfile = healthProfile?.HeightCm.HasValue == true && healthProfile?.WeightKg.HasValue == true && !string.IsNullOrWhiteSpace(healthProfile?.ActivityLevel),
                    HasAllergies = hasAllergies || allergiesAcknowledged,
                    HasAiProfile = UserAiProfilePreferencesHelper.HasMeaningfulAiProfile(
                        aiProfile?.Preferences,
                        aiProfile?.EatingPattern,
                        aiProfile?.DislikedFoods),
                    OnboardingStepsCompleted = completedSteps
                };
            }

            HealthProfileResponse? hpResponse = null;
            if (healthProfile != null)
            {
                hpResponse = new HealthProfileResponse
                {
                    UserId = healthProfile.UserId,
                    HeightCm = healthProfile.HeightCm,
                    WeightKg = healthProfile.WeightKg,
                    BodyFatPercent = healthProfile.BodyFatPercent,
                    ActivityLevel = healthProfile.ActivityLevel,
                    Goal = healthProfile.Goal,
                    Bmi = healthProfile.Bmi,
                    BmrKcal = healthProfile.BmrKcal,
                    TdeeKcal = healthProfile.TdeeKcal,
                    TargetCalories = healthProfile.TargetCalories,
                    TargetProteinG = healthProfile.TargetProteinG,
                    TargetCarbsG = healthProfile.TargetCarbsG,
                    TargetFatG = healthProfile.TargetFatG
                };
            }

            NutritionSummaryResponse? nutSummary = null;
            if (recentNutrition != null)
            {
                nutSummary = new NutritionSummaryResponse
                {
                    TotalCaloriesKcal = recentNutrition.TotalCalories ?? 0,
                    TotalProteinG = recentNutrition.TotalProteinG ?? 0,
                    TotalCarbsG = recentNutrition.TotalCarbsG ?? 0,
                    TotalFatG = recentNutrition.TotalFatG ?? 0
                };
            }

            return new AiAssistantContextResponse
            {
                Profile = profSummary,
                HealthProfile = hpResponse,
                Allergies = allergies,
                RecentNutrition = nutSummary
            };
        }

        public async Task<UserAiProfileResponse> GetProfileAsync(Guid userId)
        {
            var profile = await _db.UserAiProfiles.FirstOrDefaultAsync(x => x.UserId == userId);
            if (profile == null)
            {
                profile = new UserAiProfile
                {
                    UserId = userId,
                    Preferences = "[]",
                    DislikedFoods = "[]",
                    EatingPattern = "[]",
                    UpdatedAt = DateTime.UtcNow
                };
                _db.UserAiProfiles.Add(profile);
                await _db.SaveChangesAsync();
            }

            return new UserAiProfileResponse
            {
                UserId = profile.UserId,
                Preferences = UnwrapJsonString(profile.Preferences),
                DislikedFoods = UnwrapJsonString(profile.DislikedFoods),
                EatingPattern = UnwrapJsonString(profile.EatingPattern),
                AllergiesAcknowledged = true,
                UpdatedAt = profile.UpdatedAt
            };
        }

        public async Task<UserAiProfileResponse> UpdateProfileAsync(Guid userId, UpdateAiProfileRequest request)
        {
            var profile = await _db.UserAiProfiles.FirstOrDefaultAsync(x => x.UserId == userId);
            if (profile == null)
            {
                profile = new UserAiProfile
                {
                    UserId = userId,
                    UpdatedAt = DateTime.UtcNow
                };
                _db.UserAiProfiles.Add(profile);
            }

            if (request.Preferences != null) profile.Preferences = NormalizeJsonColumnValue(request.Preferences);
            if (request.DislikedFoods != null) profile.DislikedFoods = NormalizeJsonColumnValue(request.DislikedFoods);
            if (request.EatingPattern != null) profile.EatingPattern = NormalizeJsonColumnValue(request.EatingPattern);
            
            profile.UpdatedAt = DateTime.UtcNow;
            _db.UserAiProfiles.Update(profile);
            await _db.SaveChangesAsync();

            return new UserAiProfileResponse
            {
                UserId = profile.UserId,
                Preferences = UnwrapJsonString(profile.Preferences),
                DislikedFoods = UnwrapJsonString(profile.DislikedFoods),
                EatingPattern = UnwrapJsonString(profile.EatingPattern),
                AllergiesAcknowledged = true,
                UpdatedAt = profile.UpdatedAt
            };
        }

        private static string? NormalizeJsonColumnValue(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return null;
            }

            var trimmed = value.Trim();
            try
            {
                using var doc = JsonDocument.Parse(trimmed);
                return trimmed;
            }
            catch (JsonException)
            {
                return JsonSerializer.Serialize(trimmed);
            }
        }

        private static string? UnwrapJsonString(string? stored)
        {
            if (string.IsNullOrWhiteSpace(stored))
            {
                return null;
            }

            var trimmed = stored.Trim();
            if (!trimmed.StartsWith("\"", StringComparison.Ordinal) || !trimmed.EndsWith("\"", StringComparison.Ordinal))
            {
                return trimmed;
            }

            try
            {
                return JsonSerializer.Deserialize<string>(trimmed);
            }
            catch (JsonException)
            {
                return trimmed;
            }
        }

        // ==========================================
        // D. Action Suggestions
        // ==========================================

        public async Task<IEnumerable<string>> GetSuggestionsAsync(Guid userId)
        {
            try
            {
                var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
                client.Timeout = TimeSpan.FromSeconds(15);

                var url = $"{BuildWorkerRootUrl().TrimEnd('/')}/api/ai/suggestions?user_id={userId}";
                var response = await client.GetAsync(url);

                if (response.IsSuccessStatusCode)
                {
                    var suggestions = await response.Content.ReadFromJsonAsync<List<string>>();
                    if (suggestions != null && suggestions.Count > 0)
                    {
                        return suggestions;
                    }
                }
            }
            catch (Exception)
            {
                // Fallback silently to rule-based list
            }

            // Simple rule-based suggestions as a fallback/mock
            return new List<string>
            {
                "Cách tối ưu hóa calo cho bữa trưa của tôi là gì?",
                "Tôi bị dị ứng hải sản thì nên ăn món gì thay thế cơm gà?",
                "Tải thực đơn ăn kiêng giảm cân 1500 calo mỗi ngày?",
                "Làm sao để hạn chế cơn thèm ăn vào buổi tối?"
            };
        }

        public async Task<object> GenerateMealPlanFromAiAsync(Guid userId, string prompt)
        {
            var healthProfile = await _db.HealthProfiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var targetCalories = (int?)healthProfile?.TargetCalories ?? 2000;

            var payload = new
            {
                user_id = userId.ToString(),
                budget_vnd_per_day = 100000,
                max_cook_time_min = 60,
                target_calories_per_day = targetCalories,
                prompt = prompt,
            };

            var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
            client.Timeout = TimeSpan.FromSeconds(60);

            using var response = await client.PostAsJsonAsync(
                BuildWorkerRootUrl().TrimEnd('/') + "/api/ai/meal-plans/7d",
                payload,
                JsonOptions);

            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync();
                throw new InvalidOperationException(
                    $"AI worker meal plan failed with {(int)response.StatusCode} {response.ReasonPhrase}: {body}");
            }

            await using var stream = await response.Content.ReadAsStreamAsync();
            using var document = await JsonDocument.ParseAsync(stream);
            return document.RootElement.Clone();

#if false
            // Returns a structured weekly mockup meal plan suggested by AI
            return await Task.FromResult(new
            {
                Message = "Kế hoạch ăn uống được đề xuất từ AI:",
                StartDate = DateTime.UtcNow.ToString("yyyy-MM-dd"),
                Meals = new[]
                {
                    new { Day = "Thứ 2", Breakfast = "Cháo yến mạch chuối", Lunch = "Salad ức gà áp chảo", Dinner = "Đậu hũ sốt cà chua" },
                    new { Day = "Thứ 3", Breakfast = "Sinh tố chuối bơ hạt", Lunch = "Cơm gạo lứt thịt bò bông cải", Dinner = "Cá hồi áp chảo sốt chanh" }
                }
            });
#endif
        }

        public async Task<object> SuggestFoodReplacementAsync(Guid userId, Guid foodId, string reason)
        {
            // AI replacement advice mockup
            return await Task.FromResult(new
            {
                OriginalFoodId = foodId,
                Reason = reason,
                ReplacementSuggested = "Đậu phụ sốt cà chua",
                Explanation = "Vì bạn muốn thay thế thịt/hải sản do dị ứng, đậu hũ là nguồn đạm thực vật thanh đạm và an toàn lý tưởng."
            });
        }

        // ==========================================
        // E. History / Analytics
        // ==========================================

        public async Task<object> GetInsightsAsync(Guid userId)
        {
            // Analytical insight mockup from conversations
            return await Task.FromResult(new
            {
                MostDiscussedTopics = new[] { "Giảm cân", "Thực đơn ức gà", "Kiểm soát Calo" },
                InterestDistribution = new { Nutrition = 0.65, Recipes = 0.25, Allergies = 0.10 }
            });
        }

        public async Task<string> SummarizeConversationAsync(Guid userId, Guid conversationId)
        {
            var conversation = await _db.AiConversations
                .AnyAsync(x => x.UserId == userId && x.Id == conversationId);

            if (!conversation)
            {
                throw new Exception("Conversation not found.");
            }

            var messagesCount = await _db.AiMessages.CountAsync(x => x.ConversationId == conversationId);
            return $"Phiên hội thoại chứa {messagesCount} tin nhắn xoay quanh việc tư vấn thực đơn và tối ưu hóa calo.";
        }

        public async Task<object> GetUsageMetricsAsync(Guid userId)
        {
            var conversationsCount = await _db.AiConversations.CountAsync(x => x.UserId == userId);
            var messagesCount = await _db.AiMessages.CountAsync(x => x.Conversation != null && x.Conversation.UserId == userId);

            return await Task.FromResult(new
            {
                TotalConversations = conversationsCount,
                TotalMessages = messagesCount,
                LastUsed = DateTimeOffset.UtcNow
            });
        }

        // ==========================================
        // Helper Methods
        // ==========================================

        private async Task<object> BuildUserContextAsync(Guid userId)
        {
            var healthProfile = await _db.HealthProfiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var profile = await _db.Profiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var allergies = await _db.Allergies.AsNoTracking()
                .Where(x => x.UserId == userId && x.IsActive)
                .Select(x => x.Name)
                .ToListAsync();
            var recentNutrition = await _db.NutritionSnapshots.AsNoTracking()
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.SnapshotDate)
                .FirstOrDefaultAsync();

            return new
            {
                profile = profile == null ? null : new
                {
                    profile.FullName,
                    profile.Gender,
                    profile.DateOfBirth,
                    profile.PreferredCuisine,
                },
                healthProfile = healthProfile == null ? null : new
                {
                    healthProfile.Goal,
                    healthProfile.ActivityLevel,
                    healthProfile.WeightKg,
                    healthProfile.HeightCm,
                    healthProfile.Bmi,
                    healthProfile.BmrKcal,
                    healthProfile.TdeeKcal,
                    healthProfile.TargetCalories,
                    healthProfile.TargetProteinG,
                    healthProfile.TargetCarbsG,
                    healthProfile.TargetFatG,
                },
                allergies,
                recentNutrition = recentNutrition == null ? null : new
                {
                    recentNutrition.SnapshotDate,
                    recentNutrition.TotalCalories,
                    recentNutrition.TotalProteinG,
                    recentNutrition.TotalCarbsG,
                    recentNutrition.TotalFatG,
                    recentNutrition.GoalCompletionPercent,
                },
            };
        }

        private async Task<WorkerChatResponse> CallWorkerAsync(
            Guid userId,
            string message,
            Guid conversationId,
            IReadOnlyList<WorkerConversationMessage> conversationHistory,
            string language = "vi",
            bool stream = false)
        {
            try
            {
                var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
                client.Timeout = TimeSpan.FromSeconds(15);

                var payload = new
                {
                    message = message.Trim(),
                    user_id = userId.ToString(),
                    thread_id = conversationId.ToString(),
                    request_id = Guid.NewGuid().ToString(),
                    conversation_history = conversationHistory,
                    skip_save = true
                };

                using var response = await client.PostAsJsonAsync(BuildWorkerChatUrl(), payload, JsonOptions);
                if (!response.IsSuccessStatusCode)
                {
                    return GetMockResponse(message);
                }

                var body = await response.Content.ReadFromJsonAsync<WorkerChatResponse>(JsonOptions);
                return body ?? GetMockResponse(message);
            }
            catch
            {
                return GetMockResponse(message);
            }
        }

        private async Task<IReadOnlyList<WorkerConversationMessage>> BuildConversationHistoryAsync(
            Guid conversationId,
            object context,
            DateTimeOffset? before = null)
        {
            var query = _db.AiMessages
                .AsNoTracking()
                .Where(x => x.ConversationId == conversationId);

            if (before.HasValue)
            {
                query = query.Where(x => x.CreatedAt < before.Value);
            }

            var history = await query
                .OrderByDescending(x => x.CreatedAt)
                .Take(12)
                .OrderBy(x => x.CreatedAt)
                .Select(x => new WorkerConversationMessage
                {
                    Role = NormalizeRole(x.Role),
                    Content = x.Content ?? string.Empty,
                })
                .ToListAsync();

            history.Insert(0, new WorkerConversationMessage
            {
                Role = "system",
                Content = "MenuGreen user context. Use it only when relevant. "
                    + JsonSerializer.Serialize(context, JsonOptions),
            });

            return history;
        }

        private async Task CreateWorkerFeedbackAsync(
            Guid userId,
            Guid conversationId,
            AiMessage message,
            MessageFeedbackRequest request)
        {
            var payload = new
            {
                user_id = userId.ToString(),
                conversation_id = conversationId.ToString(),
                message_id = message.Id.ToString(),
                thread_id = conversationId.ToString(),
                feedback_type = request.IsPositive ? "thumbs_up" : "thumbs_down",
                user_note = request.Comment,
                assistant_response = message.Content,
                feature_area = "nutrition_chat",
            };

            var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
            client.Timeout = TimeSpan.FromSeconds(15);

            using var response = await client.PostAsJsonAsync(
                BuildWorkerRootUrl().TrimEnd('/') + "/api/ai/feedback",
                payload,
                JsonOptions);

            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync();
                throw new InvalidOperationException(
                    $"AI worker feedback failed with {(int)response.StatusCode} {response.ReasonPhrase}: {body}");
            }
        }

        private string BuildWorkerChatUrl()
        {
            return BuildWorkerChatUrl(_configuration["NutritionAssistant:WorkerUrl"]);
        }

        private string BuildWorkerRootUrl()
        {
            var workerChatUrl = BuildWorkerChatUrl();
            if (workerChatUrl.EndsWith("/worker/chat", StringComparison.OrdinalIgnoreCase))
            {
                return workerChatUrl[..^"/worker/chat".Length];
            }

            return workerChatUrl.TrimEnd('/');
        }

        private static string BuildWorkerChatUrl(string? configuredUrl)
        {
            if (string.IsNullOrWhiteSpace(configuredUrl))
            {
                return DefaultWorkerChatUrl;
            }

            var trimmed = configuredUrl.Trim().TrimEnd('/');
            if (trimmed.EndsWith("/worker/chat", StringComparison.OrdinalIgnoreCase))
            {
                return trimmed;
            }

            return trimmed + "/worker/chat";
        }

        private static string NormalizeRole(string? role)
        {
            return role switch
            {
                "system" => "system",
                "assistant" => "assistant",
                _ => "user",
            };
        }

        private WorkerChatResponse GetMockResponse(string userMessage)
        {
            var msgLower = userMessage.ToLowerInvariant();
            string reply = "Chào bạn! Tôi là Trợ lý Dinh dưỡng AI của MenuGreen. Cấu hình AI Worker hiện chưa sẵn sàng, dưới đây là tư vấn tự động:\n\n";

            if (msgLower.Contains("giảm cân") || msgLower.Contains("weight loss"))
            {
                reply += "Để giảm cân an toàn và bền vững, bạn nên:\n1. Kiểm soát thâm hụt calo (TDEE - 300 đến 500 kcal).\n2. Ăn nhiều rau xanh, ức gà, cá hồi và hạn chế thức ăn nhanh.\n3. Kết hợp luyện tập thể thao đều đặn và uống đủ nước.";
            }
            else if (msgLower.Contains("tăng cân") || msgLower.Contains("gain weight") || msgLower.Contains("cơ bắp"))
            {
                reply += "Để tăng cân/tăng cơ hiệu quả:\n1. Đảm bảo lượng calo nạp vào lớn hơn calo tiêu thụ (dư thừa khoảng 300-500 kcal).\n2. Tập trung vào thực phẩm giàu protein (thịt bò, trứng, sữa) và carb hấp thụ chậm (yến mạch, khoai lang).\n3. Tập các bài kháng lực (gym, calisthenics) ít nhất 3-4 buổi/tuần.";
            }
            else if (msgLower.Contains("dị ứng") || msgLower.Contains("allergy"))
            {
                reply += "Vui lòng cập nhật hồ sơ dị ứng của bạn trong mục Cá nhân. Hệ thống MenuGreen sẽ tự động lọc bỏ các nguyên liệu và món ăn chứa chất gây dị ứng để bảo vệ sức khỏe của bạn.";
            }
            else
            {
                reply += "Cảm ơn bạn đã trò chuyện với MenuGreen. Bạn có thể hỏi tôi về cách giảm cân, tăng cân, công thức nấu ăn lành mạnh, hoặc cách lên thực đơn ăn uống cá nhân hóa nhé!";
            }

            return new WorkerChatResponse
            {
                Response = reply,
                Intent = "general",
                Source = "mock",
                RequestId = Guid.NewGuid().ToString(),
                ThreadId = Guid.NewGuid().ToString(),
                IntentConfidence = 1.0m,
                SubscriptionTier = "free"
            };
        }

        private static string BuildConversationTitle(string message)
        {
            var normalized = message.Trim();
            if (normalized.Length <= 60) return normalized;
            return normalized[..60].Trim() + "...";
        }

        private sealed class WorkerChatResponse
        {
            [JsonPropertyName("response")]
            public string Response { get; set; } = string.Empty;

            [JsonPropertyName("intent")]
            public string? Intent { get; set; }

            [JsonPropertyName("source")]
            public string? Source { get; set; }

            [JsonPropertyName("request_id")]
            public string? RequestId { get; set; }

            [JsonPropertyName("thread_id")]
            public string? ThreadId { get; set; }

            [JsonPropertyName("intent_confidence")]
            public decimal? IntentConfidence { get; set; }

            [JsonPropertyName("subscription_tier")]
            public string? SubscriptionTier { get; set; }
        }

        private sealed class WorkerConversationMessage
        {
            [JsonPropertyName("role")]
            public string Role { get; set; } = "user";

            [JsonPropertyName("content")]
            public string Content { get; set; } = string.Empty;
        }
    }
}
