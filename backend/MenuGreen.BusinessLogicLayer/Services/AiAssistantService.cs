using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text;
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
        private readonly INutritionAssistantService _nutritionAssistantService;
        private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
        {
            PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        };

        public AiAssistantService(
            ApplicationDbContext db,
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration,
            INutritionAssistantService nutritionAssistantService)
        {
            _db = db;
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
            _nutritionAssistantService = nutritionAssistantService;
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
                context,
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
            var workerResponse = await CallWorkerAsync(userId, promptText, conversationId, conversationHistory, context);

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

        public async Task<IEnumerable<string>> GetSuggestionsAsync(Guid userId, Guid? conversationId = null)
        {
            try
            {
                if (!conversationId.HasValue)
                {
                    var latestConv = await _db.AiConversations
                        .Where(x => x.UserId == userId)
                        .OrderByDescending(x => x.CreatedAt)
                        .FirstOrDefaultAsync();

                    if (latestConv != null)
                    {
                        conversationId = latestConv.Id;
                    }
                }

                List<AiMessage> messages = new List<AiMessage>();
                if (conversationId.HasValue)
                {
                    messages = await _db.AiMessages
                        .Where(x => x.ConversationId == conversationId.Value)
                        .OrderBy(x => x.CreatedAt)
                        .ToListAsync();
                }

                var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
                client.Timeout = TimeSpan.FromSeconds(45);

                if (messages.Count == 0)
                {
                    var url = $"{BuildWorkerRootUrl().TrimEnd('/')}/api/ai/suggestions?user_id={userId}";
                    using var request = CreateWorkerRequest(HttpMethod.Get, url);
                    using var response = await client.SendAsync(request);

                    if (response.IsSuccessStatusCode)
                    {
                        var suggestions = await response.Content.ReadFromJsonAsync<List<string>>();
                        if (suggestions != null && suggestions.Count > 0)
                        {
                            return suggestions;
                        }
                    }
                }
                else
                {
                    var requestBody = new
                    {
                        user_id = userId.ToString(),
                        conversation_history = messages.Select(m => new
                        {
                            role = m.Role.ToLower(),
                            content = m.Content
                        }).ToList()
                    };

                    var url = $"{BuildWorkerRootUrl().TrimEnd('/')}/api/ai/conversation/suggestions";
                    using var request = CreateWorkerRequest(HttpMethod.Post, url, requestBody);
                    using var response = await client.SendAsync(request);

                    if (response.IsSuccessStatusCode)
                    {
                        var suggestions = await response.Content.ReadFromJsonAsync<List<string>>();
                        if (suggestions != null && suggestions.Count > 0)
                        {
                            return suggestions;
                        }
                    }
                }
            }
            catch (Exception)
            {
                // Fallback silently to default list
            }

            return new List<string>
            {
                "Lên kế hoạch ăn uống 7 ngày cho tôi",
                "Thay thế món ăn có trong thực đơn",
                "Tối ưu hóa ngân sách chi tiêu hôm nay",
                "Tôi muốn xem chi tiết công thức nấu ăn"
            };
        }

        public async Task<AiMealPlanActionResponse> GenerateMealPlanFromAiAsync(Guid userId, string prompt)
        {
            var healthProfile = await _db.HealthProfiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var targetCalories = (int?)healthProfile?.TargetCalories ?? 2000;
            var latestBudget = await _db.BudgetRequests.AsNoTracking()
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.CreatedAt)
                .FirstOrDefaultAsync();
            var dailyBudget = latestBudget?.BudgetVnd is > 0
                ? Math.Max(latestBudget.BudgetVnd.Value / 7, 1000)
                : 100000;
            var plan = await _nutritionAssistantService.GenerateMealPlan7dAsync(
                userId.ToString(),
                new NutritionAssistantMealPlan7dRequest
                {
                    BudgetVndPerDay = dailyBudget,
                    MaxCookTimeMin = latestBudget?.TimeLimitMin is > 0 ? latestBudget.TimeLimitMin.Value : 60,
                    TargetCaloriesPerDay = targetCalories,
                });

            await AddAiActionAuditAsync(userId, "GenerateMealPlan", new
            {
                prompt,
                targetCalories,
                dailyBudget,
                plan.TotalItems,
            });

            return new AiMealPlanActionResponse
            {
                Prompt = prompt?.Trim() ?? string.Empty,
                GeneratedAt = DateTimeOffset.UtcNow,
                MealPlan = plan,
            };
        }

        public async Task<AiFoodReplacementActionResponse> SuggestFoodReplacementAsync(Guid userId, Guid foodId, string reason)
        {
            var original = await _db.Foods.AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == foodId && x.IsActive != false)
                ?? throw new InvalidOperationException("Food not found.");
            var recommendations = await _nutritionAssistantService.GenerateWorkerRecommendationAsync(
                userId.ToString(),
                "safe",
                new AiWorkerRecommendationRequest
                {
                    TargetCalories = original.CaloriesKcal.HasValue ? (int?)Math.Round(original.CaloriesKcal.Value) : null,
                    ExcludeFoodIds = new[] { foodId.ToString() },
                    Limit = 5,
                });

            await AddAiActionAuditAsync(userId, "ReplaceFood", new { foodId, reason });
            return new AiFoodReplacementActionResponse
            {
                OriginalFoodId = foodId,
                OriginalFoodName = original.NameVi,
                Reason = reason?.Trim() ?? string.Empty,
                Recommendations = recommendations,
                GeneratedAt = DateTimeOffset.UtcNow,
            };
        }

        public async Task<AiBudgetOptimizationResponse> OptimizeBudgetAsync(Guid userId)
        {
            var healthProfile = await _db.HealthProfiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var latestBudget = await _db.BudgetRequests.AsNoTracking()
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.CreatedAt)
                .FirstOrDefaultAsync();
            var aiProfile = await _db.UserAiProfiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var budgetPerMeal = UserAiProfilePreferencesHelper.TryGetBudgetPerMealVnd(aiProfile?.Preferences)
                ?? (latestBudget?.BudgetVnd is > 0 ? Math.Max(latestBudget.BudgetVnd.Value / 21, 1000) : 50000);
            var targetPerMeal = Math.Max((healthProfile?.TargetCalories ?? 1800) / 3m, 250m);
            var recommendations = await _nutritionAssistantService.GenerateWorkerRecommendationAsync(
                userId.ToString(),
                "budget-aware",
                new AiWorkerRecommendationRequest
                {
                    BudgetVnd = budgetPerMeal,
                    TargetCalories = (int)Math.Round(targetPerMeal),
                    Limit = 5,
                });

            await AddAiActionAuditAsync(userId, "BudgetOptimize", new { budgetPerMeal, targetPerMeal });
            return new AiBudgetOptimizationResponse
            {
                BudgetPerMealVnd = budgetPerMeal,
                TargetCaloriesPerMeal = targetPerMeal,
                Recommendations = recommendations,
                GeneratedAt = DateTimeOffset.UtcNow,
            };
        }

        // ==========================================
        // E. History / Analytics
        // ==========================================

        public async Task<AiAssistantInsightsResponse> GetInsightsAsync(Guid userId)
        {
            var messages = await _db.AiMessages.AsNoTracking()
                .Where(x => x.Conversation != null && x.Conversation.UserId == userId && x.Role == "user")
                .OrderBy(x => x.CreatedAt)
                .Select(x => new { x.Content, x.CreatedAt })
                .ToListAsync();
            var counts = messages
                .GroupBy(x => ClassifyConversationTopic(x.Content))
                .ToDictionary(x => x.Key, x => x.Count(), StringComparer.OrdinalIgnoreCase);
            var total = messages.Count;
            var topics = counts
                .OrderByDescending(x => x.Value)
                .ThenBy(x => x.Key)
                .Select(x => new AiTopicInsightResponse
                {
                    Topic = x.Key,
                    Count = x.Value,
                    Percentage = total == 0 ? 0 : Math.Round(x.Value * 100d / total, 2),
                })
                .ToList();

            return new AiAssistantInsightsResponse
            {
                TotalUserMessages = total,
                FirstMessageAt = messages.FirstOrDefault()?.CreatedAt,
                LastMessageAt = messages.LastOrDefault()?.CreatedAt,
                Topics = topics,
                InterestDistribution = topics.ToDictionary(x => x.Topic, x => x.Percentage / 100d),
            };
        }

        public async Task<string> SummarizeConversationAsync(Guid userId, Guid conversationId)
        {
            var conversation = await _db.AiConversations
                .AnyAsync(x => x.UserId == userId && x.Id == conversationId);

            if (!conversation)
            {
                throw new Exception("Conversation not found.");
            }

            var messages = await _db.AiMessages.AsNoTracking()
                .Where(x => x.ConversationId == conversationId)
                .OrderBy(x => x.CreatedAt)
                .Select(x => new { x.Role, x.Content, x.CreatedAt })
                .ToListAsync();
            if (messages.Count == 0)
            {
                return "This conversation has no messages yet.";
            }

            var userMessages = messages.Where(x => x.Role == "user").ToList();
            var topics = userMessages
                .GroupBy(x => ClassifyConversationTopic(x.Content))
                .OrderByDescending(x => x.Count())
                .Take(3)
                .Select(x => x.Key)
                .ToList();
            var questions = userMessages
                .Select(x => TruncateText(x.Content, 90))
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Take(3)
                .ToList();
            var topicText = topics.Count == 0 ? "general nutrition" : string.Join(", ", topics);
            var questionText = questions.Count == 0
                ? "No user questions recorded."
                : $"Key questions: {string.Join(" | ", questions)}.";
            return $"Conversation contains {messages.Count} messages ({userMessages.Count} from the user). Main topics: {topicText}. {questionText}";
        }

        public async Task<AiAssistantUsageResponse> GetUsageMetricsAsync(Guid userId)
        {
            var conversationsCount = await _db.AiConversations.CountAsync(x => x.UserId == userId);
            var messages = await _db.AiMessages.AsNoTracking()
                .Where(x => x.Conversation != null && x.Conversation.UserId == userId)
                .Select(x => new { x.Role, x.CreatedAt })
                .ToListAsync();
            var today = DateTimeOffset.UtcNow.Date;
            var weekStart = today.AddDays(-(((int)today.DayOfWeek + 6) % 7));
            var monthStart = new DateTime(today.Year, today.Month, 1, 0, 0, 0, DateTimeKind.Utc);
            var sevenDayStart = today.AddDays(-6);
            var daily = Enumerable.Range(0, 7)
                .Select(offset => sevenDayStart.AddDays(offset))
                .ToDictionary(
                    day => day.ToString("yyyy-MM-dd"),
                    day => messages.Count(x => x.CreatedAt.HasValue && x.CreatedAt.Value.UtcDateTime.Date == day));

            return new AiAssistantUsageResponse
            {
                TotalConversations = conversationsCount,
                TotalMessages = messages.Count,
                UserMessages = messages.Count(x => x.Role == "user"),
                AssistantMessages = messages.Count(x => x.Role == "assistant"),
                ActiveDays = messages.Where(x => x.CreatedAt.HasValue).Select(x => x.CreatedAt!.Value.UtcDateTime.Date).Distinct().Count(),
                MessagesThisWeek = messages.Count(x => x.CreatedAt.HasValue && x.CreatedAt.Value.UtcDateTime >= weekStart),
                MessagesThisMonth = messages.Count(x => x.CreatedAt.HasValue && x.CreatedAt.Value.UtcDateTime >= monthStart),
                LastUsed = messages.Where(x => x.CreatedAt.HasValue).Select(x => x.CreatedAt).Max(),
                DailyMessagesLast7Days = daily,
            };
        }

        private async Task AddAiActionAuditAsync(Guid userId, string action, object metadata)
        {
            _db.ActivityLogs.Add(new ActivityLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Action = action,
                EntityType = "AiAssistantAction",
                Metadata = JsonSerializer.Serialize(metadata, JsonOptions),
                CreatedAt = DateTimeOffset.UtcNow,
            });
            await _db.SaveChangesAsync();
        }

        private static string ClassifyConversationTopic(string? content)
        {
            var text = NormalizeForMatching(content);
            if (ContainsAny(text, "di ung", "allergy", "hai san", "dau phong")) return "allergy_safety";
            if (ContainsAny(text, "ngan sach", "budget", "gia", "tiet kiem", "re hon")) return "budget";
            if (ContainsAny(text, "thuc don", "meal plan", "ke hoach an", "7 ngay", "hang tuan")) return "meal_plan";
            if (ContainsAny(text, "cong thuc", "cach nau", "cach lam", "nguyen lieu", "recipe")) return "recipe";
            if (ContainsAny(text, "calo", "kcal", "protein", "carb", "macro", "tdee", "bmr", "dinh duong")) return "nutrition";
            return "general";
        }

        private static string NormalizeForMatching(string? value)
        {
            var normalized = (value ?? string.Empty).Trim().ToLowerInvariant().Normalize(NormalizationForm.FormD);
            var builder = new StringBuilder(normalized.Length);
            foreach (var character in normalized)
            {
                if (CharUnicodeInfo.GetUnicodeCategory(character) != UnicodeCategory.NonSpacingMark)
                {
                    builder.Append(character == 'đ' ? 'd' : character);
                }
            }
            return builder.ToString().Normalize(NormalizationForm.FormC);
        }

        private static bool ContainsAny(string text, params string[] tokens) => tokens.Any(text.Contains);

        private static string TruncateText(string? value, int maxLength)
        {
            var text = (value ?? string.Empty).Trim();
            return text.Length <= maxLength ? text : text[..maxLength].TrimEnd() + "...";
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
                .Where(x => x.UserId == userId && x.SnapshotDate == DateOnly.FromDateTime(DateTime.UtcNow))
                .OrderByDescending(x => x.SnapshotDate)
                .FirstOrDefaultAsync();

            var availableFoods = await _db.Foods.AsNoTracking()
                .Where(x => x.IsActive != false)
                .Select(x => new
                {
                    x.Id,
                    x.NameVi,
                    x.CaloriesKcal,
                    x.ProteinG,
                    x.CarbsG,
                    x.FatG,
                    x.Category
                })
                .ToListAsync();

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
                availableFoods = availableFoods
            };
        }

        private async Task<WorkerChatResponse> CallWorkerAsync(
            Guid userId,
            string message,
            Guid conversationId,
            IReadOnlyList<WorkerConversationMessage> conversationHistory,
            object context,
            string language = "vi",
            bool stream = false)
        {
            try
            {
                var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
                client.Timeout = TimeSpan.FromSeconds(45);

                var payload = new
                {
                    message = message.Trim(),
                    user_id = userId.ToString(),
                    thread_id = conversationId.ToString(),
                    request_id = Guid.NewGuid().ToString(),
                    conversation_history = conversationHistory,
                    context,
                    skip_save = true
                };

                using var request = CreateWorkerRequest(HttpMethod.Post, BuildWorkerChatUrl(), payload);
                using var response = await client.SendAsync(request);
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
                Content = "You are MenuGreen AI Nutrition Coach. When recommending dishes, food items, or creating daily/weekly meal plans for the user, you MUST select and recommend from the 'availableFoods' list provided in the user context. Do not make up food names that are not in 'availableFoods'. Available foods list represents actual dishes the user can log or cook. MenuGreen user context: "
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
            client.Timeout = TimeSpan.FromSeconds(45);

            using var workerRequest = CreateWorkerRequest(
                HttpMethod.Post,
                BuildWorkerRootUrl().TrimEnd('/') + "/api/ai/feedback",
                payload);
            using var response = await client.SendAsync(workerRequest);

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

        private HttpRequestMessage CreateWorkerRequest(HttpMethod method, string url, object? payload = null)
        {
            var request = new HttpRequestMessage(method, url);
            var internalKey = _configuration["NutritionAssistant:WorkerInternalKey"]
                ?? _configuration["AI_RUNTIME_INTERNAL_KEY"];

            if (!string.IsNullOrWhiteSpace(internalKey))
            {
                request.Headers.TryAddWithoutValidation("X-AI-Runtime-Key", internalKey.Trim());
            }

            if (payload != null)
            {
                request.Content = JsonContent.Create(payload, options: JsonOptions);
            }

            return request;
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

            if (msgLower.Contains("calo") || msgLower.Contains("kcal") || msgLower.Contains("ăn gì") || msgLower.Contains("món ăn") || msgLower.Contains("thực đơn"))
            {
                reply += "Dưới đây là gợi ý thực đơn cụ thể dựa trên các món ăn thực tế có sẵn trên hệ thống MenuGreen:\n\n"
                    + "- **Bữa sáng**: Cháo yến mạch trứng gà (250 kcal) và Sinh tố chuối bơ đậu phộng (450 kcal)\n"
                    + "- **Bữa trưa**: Cơm gạo lứt (111 kcal), Ức gà áp chảo (165 kcal) và Salad bơ ức gà (320 kcal)\n"
                    + "- **Bữa tối**: Cá hồi áp chảo sốt chanh (350 kcal), Khoai lang hấp (86 kcal) và Bò áp chảo bông cải xanh (290 kcal)\n"
                    + "- **Bữa phụ**: Salad cá hồi bơ (380 kcal)\n\n"
                    + "Tổng năng lượng nạp vào khoảng 2402 kcal (phù hợp với mục tiêu ~2500 kcal của bạn). Bạn có thể thêm trực tiếp từng món ăn trên vào thực đơn hôm nay của mình bằng các nút bấm xuất hiện ngay dưới đây.";
            }
            else if (msgLower.Contains("giảm cân") || msgLower.Contains("weight loss"))
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
