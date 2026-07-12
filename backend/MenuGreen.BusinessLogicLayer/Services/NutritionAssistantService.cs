using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading;
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
    public class NutritionAssistantService : INutritionAssistantService
    {
        private const string DefaultWorkerChatUrl = "http://127.0.0.1:8000/worker/chat";
        private readonly ApplicationDbContext _db;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private readonly IMealPlanService _mealPlanService;
        private readonly INutritionTrackingService _nutritionTrackingService;
        private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
        {
            PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        };

        public NutritionAssistantService(
            ApplicationDbContext db,
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration,
            IMealPlanService mealPlanService,
            INutritionTrackingService nutritionTrackingService)
        {
            _db = db;
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
            _mealPlanService = mealPlanService;
            _nutritionTrackingService = nutritionTrackingService;
        }

        public async Task<NutritionAssistantChatResponse> SendMessageAsync(string userId, NutritionAssistantChatRequest request)
        {
            if (!Guid.TryParse(userId, out var userGuid))
            {
                throw new InvalidOperationException("User id is invalid.");
            }

            var conversation = await ResolveConversationAsync(userGuid, request.ConversationId, request.Message);
            var context = await BuildUserContextAsync(userGuid);
            var conversationHistory = await BuildConversationHistoryAsync(conversation.Id, context);

            var userMessage = new AiMessage
            {
                Id = Guid.NewGuid(),
                ConversationId = conversation.Id,
                Role = "user",
                Content = request.Message.Trim(),
                CreatedAt = DateTimeOffset.UtcNow,
            };

            _db.AiMessages.Add(userMessage);
            await _db.SaveChangesAsync();

            var workerResponse = await CallWorkerAsync(request, conversation, conversationHistory);

            var assistantContent = workerResponse.Response ?? string.Empty;
            var assistantMessage = new AiMessage
            {
                Id = Guid.NewGuid(),
                ConversationId = conversation.Id,
                Role = "assistant",
                Content = assistantContent,
                CreatedAt = DateTimeOffset.UtcNow,
            };

            _db.AiMessages.Add(assistantMessage);
            if (string.IsNullOrWhiteSpace(conversation.Title))
            {
                conversation.Title = BuildConversationTitle(request.Message);
            }

            await _db.SaveChangesAsync();

            return new NutritionAssistantChatResponse
            {
                ConversationId = conversation.Id,
                UserMessageId = userMessage.Id,
                AssistantMessageId = assistantMessage.Id,
                AssistantMessage = assistantContent,
                CreatedAt = assistantMessage.CreatedAt ?? DateTimeOffset.UtcNow,
                SuggestedQuestions = Array.Empty<string>(),
                SafetyNotice = workerResponse.Intent == "medical"
                    ? "This is reference-only nutrition guidance. Please contact a medical professional for health risks."
                    : null,
                Intent = workerResponse.Intent,
                Source = workerResponse.Source,
                RequestId = workerResponse.RequestId,
                ThreadId = workerResponse.ThreadId,
                IntentConfidence = workerResponse.IntentConfidence,
                SubscriptionTier = workerResponse.SubscriptionTier,
            };
        }

        public async Task StreamMessageAsync(
            string userId,
            NutritionAssistantChatRequest request,
            Stream output,
            CancellationToken cancellationToken = default)
        {
            if (!Guid.TryParse(userId, out var userGuid))
            {
                throw new InvalidOperationException("User id is invalid.");
            }

            var threadId = request.ConversationId?.ToString() ?? Guid.NewGuid().ToString();
            var context = await BuildUserContextAsync(userGuid);
            var conversationHistory = new List<WorkerConversationMessage>();
            if (!string.IsNullOrWhiteSpace(context))
            {
                conversationHistory.Add(new WorkerConversationMessage
                {
                    Role = "system",
                    Content = context,
                });
            }

            var payload = new
            {
                message = request.Message.Trim(),
                user_id = userId,
                thread_id = threadId,
                request_id = Guid.NewGuid().ToString(),
                conversation_history = conversationHistory,
            };

            var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
            client.Timeout = TimeSpan.FromMinutes(2);

            using var workerRequest = CreateWorkerRequest(HttpMethod.Post, "/worker/chat/stream");
            workerRequest.Content = JsonContent.Create(payload, options: JsonOptions);

            using var response = await client.SendAsync(
                workerRequest,
                HttpCompletionOption.ResponseHeadersRead,
                cancellationToken);
            await EnsureWorkerSuccessAsync(response);
            await response.Content.CopyToAsync(output, cancellationToken);
        }

        public async Task<IReadOnlyList<NutritionAssistantConversationSummaryResponse>> GetConversationsAsync(string userId, int take = 20)
        {
            if (!Guid.TryParse(userId, out var userGuid))
            {
                throw new InvalidOperationException("User id is invalid.");
            }

            var safeTake = Math.Clamp(take, 1, 100);

            var rows = await _db.AiConversations
                .AsNoTracking()
                .Where(x => x.UserId == userGuid)
                .Select(x => new
                {
                    x.Id,
                    x.Title,
                    x.CreatedAt,
                    MessageCount = x.Messages.Count(),
                    LastMessage = x.Messages
                        .OrderByDescending(m => m.CreatedAt)
                        .Select(m => new { m.Content, m.CreatedAt })
                        .FirstOrDefault(),
                })
                .ToListAsync();

            return rows
                .OrderByDescending(x => x.LastMessage?.CreatedAt ?? x.CreatedAt ?? DateTimeOffset.MinValue)
                .Take(safeTake)
                .Select(x => new NutritionAssistantConversationSummaryResponse
                {
                    ConversationId = x.Id,
                    Title = !string.IsNullOrWhiteSpace(x.Title)
                        ? x.Title!
                        : "Conversation " + x.Id.ToString("N")[..8],
                    LastMessagePreview = BuildPreview(x.LastMessage?.Content),
                    LastMessageAt = x.LastMessage?.CreatedAt ?? x.CreatedAt,
                    MessageCount = x.MessageCount,
                })
                .ToList();
        }

        public async Task<NutritionAssistantConversationDetailResponse> GetConversationAsync(string userId, Guid conversationId)
        {
            if (!Guid.TryParse(userId, out var userGuid))
            {
                throw new InvalidOperationException("User id is invalid.");
            }

            var conversation = await _db.AiConversations
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == conversationId && x.UserId == userGuid);

            if (conversation == null)
            {
                throw new KeyNotFoundException("Conversation not found.");
            }

            var messages = await _db.AiMessages
                .AsNoTracking()
                .Where(x => x.ConversationId == conversationId)
                .OrderBy(x => x.CreatedAt)
                .Select(x => new NutritionAssistantMessageResponse
                {
                    MessageId = x.Id,
                    Role = x.Role ?? string.Empty,
                    Content = x.Content ?? string.Empty,
                    TokensUsed = x.TokensUsed,
                    CreatedAt = x.CreatedAt,
                })
                .ToListAsync();

            return new NutritionAssistantConversationDetailResponse
            {
                ConversationId = conversation.Id,
                Title = !string.IsNullOrWhiteSpace(conversation.Title)
                    ? conversation.Title!
                    : "Conversation " + conversation.Id.ToString("N")[..8],
                CreatedAt = conversation.CreatedAt,
                Messages = messages,
            };
        }

        public async Task<NutritionAssistantAdminOverviewResponse> GetAdminOverviewAsync(int recentTake = 10)
        {
            var safeTake = Math.Clamp(recentTake, 1, 50);
            var recentThreshold = DateTimeOffset.UtcNow.AddDays(-7);

            var bridgeHealth = await GetBridgeHealthAsync();
            var totalAiProfiles = await _db.UserAiProfiles.AsNoTracking().CountAsync();
            var totalConversations = await _db.AiConversations.AsNoTracking().CountAsync();
            var totalMessages = await _db.AiMessages.AsNoTracking().CountAsync();
            var messagesLast7Days = await _db.AiMessages
                .AsNoTracking()
                .CountAsync(x => x.CreatedAt != null && x.CreatedAt >= recentThreshold);
            var latestConversationAt = await _db.AiConversations
                .AsNoTracking()
                .MaxAsync(x => (DateTimeOffset?)x.CreatedAt);

            var recentRows = await _db.AiConversations
                .AsNoTracking()
                .Select(x => new
                {
                    x.Id,
                    x.Title,
                    x.CreatedAt,
                    MessageCount = x.Messages.Count(),
                    LastMessage = x.Messages
                        .OrderByDescending(m => m.CreatedAt)
                        .Select(m => new { m.Content, m.CreatedAt })
                        .FirstOrDefault(),
                })
                .ToListAsync();

            var recentConversations = recentRows
                .OrderByDescending(x => x.LastMessage?.CreatedAt ?? x.CreatedAt ?? DateTimeOffset.MinValue)
                .Take(safeTake)
                .Select(x => new NutritionAssistantConversationSummaryResponse
                {
                    ConversationId = x.Id,
                    Title = !string.IsNullOrWhiteSpace(x.Title)
                        ? x.Title!
                        : "Conversation " + x.Id.ToString("N")[..8],
                    LastMessagePreview = BuildPreview(x.LastMessage?.Content),
                    LastMessageAt = x.LastMessage?.CreatedAt ?? x.CreatedAt,
                    MessageCount = x.MessageCount,
                })
                .ToList();

            return new NutritionAssistantAdminOverviewResponse
            {
                BridgeHealth = bridgeHealth,
                TotalAiProfiles = totalAiProfiles,
                TotalConversations = totalConversations,
                TotalMessages = totalMessages,
                MessagesLast7Days = messagesLast7Days,
                LatestConversationAt = latestConversationAt,
                RecentConversations = recentConversations,
            };
        }

        public async Task<NutritionAssistantBridgeHealthResponse> GetBridgeHealthAsync()
        {
            var configuredUrl = _configuration["NutritionAssistant:WorkerUrl"];
            var workerUrl = BuildWorkerChatUrl(configuredUrl);
            var healthUrl = BuildWorkerEndpointUrl("/health");

            var result = new NutritionAssistantBridgeHealthResponse
            {
                WorkerConfigured = !string.IsNullOrWhiteSpace(configuredUrl),
                WorkerUrl = workerUrl,
                CheckedAt = DateTimeOffset.UtcNow,
            };

            try
            {
                var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
                client.Timeout = TimeSpan.FromSeconds(10);

                using var response = await client.GetAsync(healthUrl);
                result.StatusCode = (int)response.StatusCode;
                result.WorkerReachable = response.IsSuccessStatusCode;

                var body = await response.Content.ReadFromJsonAsync<WorkerHealthResponse>(JsonOptions);
                result.WorkerService = body?.Service;
                if (!response.IsSuccessStatusCode)
                {
                    result.Error = "Worker health check returned a non-success status.";
                }
            }
            catch (Exception ex)
            {
                result.WorkerReachable = false;
                result.Error = ex.Message;
            }

            return result;
        }

        public Task<JsonElement> GetWorkerDebugDbAsync(string? userId = null)
        {
            var path = "/debug/db";
            if (!string.IsNullOrWhiteSpace(userId))
            {
                path += "?user_id=" + Uri.EscapeDataString(userId.Trim());
            }

            return GetWorkerJsonElementAsync(path, TimeSpan.FromSeconds(15));
        }

        public Task<JsonElement> GetWorkerDebugPostgresAsync(string? userId = null)
        {
            var path = "/debug/postgres";
            if (!string.IsNullOrWhiteSpace(userId))
            {
                path += "?user_id=" + Uri.EscapeDataString(userId.Trim());
            }

            return GetWorkerJsonElementAsync(path, TimeSpan.FromSeconds(15));
        }

        public Task<JsonElement> GetWorkerContextAsync(string userId, string? date = null)
        {
            var path = "/worker/context?user_id=" + Uri.EscapeDataString(userId.Trim());
            if (!string.IsNullOrWhiteSpace(date))
            {
                path += "&date=" + Uri.EscapeDataString(date.Trim());
            }

            return GetWorkerJsonElementAsync(path, TimeSpan.FromSeconds(30));
        }

        public Task<NutritionAssistantFeedbackResponse> CreateFeedbackAsync(
            string userId,
            NutritionAssistantFeedbackRequest request)
        {
            var payload = new
            {
                user_id = userId,
                conversation_id = request.ConversationId,
                message_id = request.MessageId,
                thread_id = request.ThreadId,
                feedback_type = request.FeedbackType,
                rating = request.Rating,
                user_note = request.UserNote,
                assistant_response = request.AssistantResponse,
                corrected_response = request.CorrectedResponse,
                feature_area = request.FeatureArea,
            };

            return PostWorkerJsonAsync<NutritionAssistantFeedbackResponse>(
                "/api/ai/feedback",
                payload,
                TimeSpan.FromSeconds(30));
        }

        public Task<NutritionAssistantMealPlan7dResponse> GenerateMealPlan7dAsync(
            string userId,
            NutritionAssistantMealPlan7dRequest request)
        {
            var payload = new
            {
                user_id = userId,
                budget_vnd_per_day = request.BudgetVndPerDay,
                max_cook_time_min = request.MaxCookTimeMin,
                target_calories_per_day = request.TargetCaloriesPerDay,
            };

            return PostWorkerJsonAsync<NutritionAssistantMealPlan7dResponse>(
                "/api/ai/meal-plans/7d",
                payload,
                TimeSpan.FromSeconds(60));
        }

        public async Task<JsonElement> GenerateWorkerRecommendationAsync(
            string userId,
            string mode,
            AiWorkerRecommendationRequest request)
        {
            if (!Guid.TryParse(userId, out var userGuid))
            {
                throw new InvalidOperationException("User id is invalid.");
            }

            var path = BuildRecommendationPath(mode);
            var payload = new
            {
                user_id = userId,
                date = request.Date,
                budget_vnd = request.BudgetVnd,
                meal_slot = request.MealSlot,
                max_cook_time_min = request.MaxCookTimeMin,
                target_calories = request.TargetCalories,
                exclude_food_ids = request.ExcludeFoodIds,
                limit = request.Limit,
            };

            var result = await PostWorkerJsonElementAsync(path, payload, TimeSpan.FromSeconds(60));
            await SaveWorkerRecommendationHistoryAsync(userGuid, mode, payload, result);
            return result;
        }

        public async Task<JsonElement> ExecuteWorkerActionAsync(string userId, AiWorkerActionExecuteRequest request)
        {
            if (!Guid.TryParse(userId, out var userGuid))
            {
                throw new InvalidOperationException("User id is invalid.");
            }

            var action = request.Type.Trim().ToLowerInvariant();
            var requiresConfirmation = action is "generate_meal_plan" or "replace_food" or "budget_optimize" or "schedule_meal" or "log_meal";
            if (requiresConfirmation && !request.Confirmed)
            {
                return BuildActionResult(
                    "needs_confirmation",
                    action,
                    new { message = "User confirmation is required before executing this action." });
            }

            try
            {
                JsonElement? payloadElement = null;
                if (request.Payload != null)
                {
                    payloadElement = JsonSerializer.SerializeToElement(request.Payload, JsonOptions);
                }

                object result = action switch
                {
                    "generate_meal_plan" => await ExecuteGenerateMealPlanActionAsync(userId, payloadElement),
                    "replace_food" => await ExecuteReplaceFoodActionAsync(userId, payloadElement),
                    "budget_optimize" => await ExecuteBudgetOptimizeActionAsync(userId, payloadElement),
                    "schedule_meal" => await ExecuteScheduleMealActionAsync(userGuid, payloadElement),
                    "log_meal" => await ExecuteLogMealActionAsync(userGuid, payloadElement),
                    "show_recipe" => await ExecuteShowRecipeActionAsync(payloadElement),
                    "ask_followup" => new
                    {
                        message = GetPayloadString(payloadElement, "question", "message")
                            ?? "Please provide your meal, budget, cooking time, or nutrition goal.",
                    },
                    _ => throw new InvalidOperationException("Unsupported AI action type."),
                };

                if (action is not "show_recipe" and not "ask_followup")
                {
                    _db.ActivityLogs.Add(new ActivityLog
                    {
                        Id = Guid.NewGuid(),
                        UserId = userGuid,
                        Action = "AiActionExecuted",
                        EntityType = action,
                        Metadata = JsonSerializer.Serialize(new { request.Payload, request.Confirmed }, JsonOptions),
                        CreatedAt = DateTimeOffset.UtcNow,
                    });
                    await _db.SaveChangesAsync();
                }

                return BuildActionResult("completed", action, result);
            }
            catch (Exception exception) when (exception is InvalidOperationException or ArgumentException or FormatException)
            {
                return BuildActionResult("validation_error", action, new { message = exception.Message });
            }
        }

        private async Task<object> ExecuteGenerateMealPlanActionAsync(string userId, JsonElement? payload)
        {
            var healthTarget = await _db.HealthProfiles.AsNoTracking()
                .Where(x => x.UserId == Guid.Parse(userId))
                .Select(x => x.TargetCalories)
                .FirstOrDefaultAsync();
            return await GenerateMealPlan7dAsync(
                userId,
                new NutritionAssistantMealPlan7dRequest
                {
                    BudgetVndPerDay = GetPayloadInt(payload, "budget_vnd_per_day", "budget_vnd") ?? 100000,
                    MaxCookTimeMin = GetPayloadInt(payload, "max_cook_time_min") ?? 60,
                    TargetCaloriesPerDay = GetPayloadInt(payload, "target_calories_per_day", "target_calories") ?? healthTarget ?? 2000,
                });
        }

        private async Task<object> ExecuteReplaceFoodActionAsync(string userId, JsonElement? payload)
        {
            var originalId = GetPayloadGuid(payload, "food_id", "original_food_id");
            var excluded = originalId.HasValue ? new[] { originalId.Value.ToString() } : Array.Empty<string>();
            return await GenerateWorkerRecommendationAsync(
                userId,
                "safe",
                new AiWorkerRecommendationRequest
                {
                    TargetCalories = GetPayloadInt(payload, "target_calories"),
                    MealSlot = GetPayloadString(payload, "meal_slot"),
                    BudgetVnd = GetPayloadInt(payload, "budget_vnd"),
                    ExcludeFoodIds = excluded,
                    Limit = Math.Clamp(GetPayloadInt(payload, "limit") ?? 5, 1, 50),
                });
        }

        private async Task<object> ExecuteBudgetOptimizeActionAsync(string userId, JsonElement? payload)
        {
            var budget = GetPayloadInt(payload, "budget_vnd", "budget_per_meal_vnd")
                ?? throw new InvalidOperationException("budget_vnd is required for budget optimization.");
            return await GenerateWorkerRecommendationAsync(
                userId,
                "budget-aware",
                new AiWorkerRecommendationRequest
                {
                    BudgetVnd = budget,
                    TargetCalories = GetPayloadInt(payload, "target_calories"),
                    MealSlot = GetPayloadString(payload, "meal_slot"),
                    MaxCookTimeMin = GetPayloadInt(payload, "max_cook_time_min"),
                    Limit = Math.Clamp(GetPayloadInt(payload, "limit") ?? 5, 1, 50),
                });
        }

        private async Task<object> ExecuteScheduleMealActionAsync(Guid userId, JsonElement? payload)
        {
            var foodId = GetPayloadGuid(payload, "food_id");
            var recipeId = GetPayloadGuid(payload, "recipe_id");
            if (!foodId.HasValue && !recipeId.HasValue)
            {
                throw new InvalidOperationException("food_id or recipe_id is required to schedule a meal.");
            }

            var plannedDateText = GetPayloadString(payload, "planned_date", "date");
            var plannedDate = string.IsNullOrWhiteSpace(plannedDateText)
                ? DateOnly.FromDateTime(DateTime.UtcNow)
                : DateOnly.Parse(plannedDateText);
            var timeText = GetPayloadString(payload, "scheduled_time", "time");
            var scheduledTime = string.IsNullOrWhiteSpace(timeText) ? (TimeOnly?)null : TimeOnly.Parse(timeText);
            var item = new MealPlanItemUpsertRequest
            {
                MealType = GetPayloadString(payload, "meal_type", "meal_slot") ?? "meal",
                FoodId = foodId,
                RecipeId = recipeId,
                PlannedDate = plannedDate,
                ScheduledTime = scheduledTime,
                TargetCalories = GetPayloadInt(payload, "target_calories"),
            };
            var existingPlan = await _mealPlanService.GetByDateAsync(userId, plannedDate);
            if (existingPlan != null)
            {
                return await _mealPlanService.AddItemAsync(existingPlan.Id, item, userId);
            }

            return await _mealPlanService.CreateOrUpdateDailyAsync(userId, new UserMealPlanUpsertRequest
            {
                PlannedDate = plannedDate,
                Title = "AI scheduled meal",
                TargetCalories = GetPayloadInt(payload, "daily_target_calories"),
                Items = new List<MealPlanItemUpsertRequest> { item },
            });
        }

        private async Task<object> ExecuteLogMealActionAsync(Guid userId, JsonElement? payload)
        {
            var quantityG = GetPayloadDecimal(payload, "quantity_g");
            var quantity = GetPayloadDecimal(payload, "quantity");
            if (!quantityG.HasValue && !quantity.HasValue)
            {
                throw new InvalidOperationException("quantity_g or quantity is required to log a meal.");
            }

            var loggedAtText = GetPayloadString(payload, "logged_at");
            return await _nutritionTrackingService.CreateMealLogAsync(
                userId,
                new MealLogUpsertRequest
                {
                    FoodId = GetPayloadGuid(payload, "food_id"),
                    RecipeId = GetPayloadGuid(payload, "recipe_id"),
                    MealType = GetPayloadString(payload, "meal_type", "meal_slot") ?? "meal",
                    QuantityG = quantityG,
                    Quantity = quantity,
                    Unit = GetPayloadString(payload, "unit"),
                    Notes = GetPayloadString(payload, "notes"),
                    LoggedAt = string.IsNullOrWhiteSpace(loggedAtText) ? DateTime.UtcNow : DateTime.Parse(loggedAtText),
                    CaloriesKcal = GetPayloadDecimal(payload, "calories_kcal"),
                    ProteinG = GetPayloadDecimal(payload, "protein_g"),
                    CarbsG = GetPayloadDecimal(payload, "carbs_g"),
                    FatG = GetPayloadDecimal(payload, "fat_g"),
                });
        }

        private async Task<object> ExecuteShowRecipeActionAsync(JsonElement? payload)
        {
            var recipeId = GetPayloadGuid(payload, "recipe_id");
            var query = GetPayloadString(payload, "query", "name")?.Trim();
            var recipes = _db.Recipes.AsNoTracking().Include(x => x.Food).Where(x => x.IsActive != false);
            var recipe = recipeId.HasValue
                ? await recipes.FirstOrDefaultAsync(x => x.Id == recipeId.Value)
                : string.IsNullOrWhiteSpace(query)
                    ? null
                    : await recipes.FirstOrDefaultAsync(x => x.Title.ToLower().Contains(query.ToLower()));
            if (recipe == null)
            {
                throw new InvalidOperationException("Recipe not found.");
            }

            return new
            {
                recipe.Id,
                recipe.Title,
                recipe.Description,
                recipe.MealType,
                recipe.PrepTimeMin,
                recipe.CookTimeMin,
                recipe.TotalTimeMin,
                recipe.Servings,
                recipe.Instructions,
                caloriesKcal = recipe.Food?.CaloriesKcal,
                proteinG = recipe.Food?.ProteinG,
                carbsG = recipe.Food?.CarbsG,
                fatG = recipe.Food?.FatG,
            };
        }

        private static JsonElement BuildActionResult(string status, string action, object result)
        {
            return JsonSerializer.SerializeToElement(new { status, action, result }, JsonOptions);
        }

        private static JsonElement? GetPayloadProperty(JsonElement? payload, params string[] names)
        {
            if (!payload.HasValue || payload.Value.ValueKind != JsonValueKind.Object)
            {
                return null;
            }

            foreach (var property in payload.Value.EnumerateObject())
            {
                if (names.Any(name => property.Name.Equals(name, StringComparison.OrdinalIgnoreCase)))
                {
                    if (property.Value.ValueKind == JsonValueKind.Null)
                    {
                        return null;
                    }
                    return property.Value;
                }
            }
            return null;
        }

        private static string? GetPayloadString(JsonElement? payload, params string[] names)
        {
            var value = GetPayloadProperty(payload, names);
            return value.HasValue && value.Value.ValueKind == JsonValueKind.String ? value.Value.GetString() : null;
        }

        private static int? GetPayloadInt(JsonElement? payload, params string[] names)
        {
            var value = GetPayloadProperty(payload, names);
            if (!value.HasValue) return null;
            if (value.Value.TryGetInt32(out var number)) return number;
            return value.Value.ValueKind == JsonValueKind.String && int.TryParse(value.Value.GetString(), out number) ? number : null;
        }

        private static decimal? GetPayloadDecimal(JsonElement? payload, params string[] names)
        {
            var value = GetPayloadProperty(payload, names);
            if (!value.HasValue) return null;
            if (value.Value.TryGetDecimal(out var number)) return number;
            return value.Value.ValueKind == JsonValueKind.String && decimal.TryParse(value.Value.GetString(), out number) ? number : null;
        }

        private static Guid? GetPayloadGuid(JsonElement? payload, params string[] names)
        {
            var text = GetPayloadString(payload, names);
            return Guid.TryParse(text, out var value) ? value : null;
        }

        public Task<AiWorkerCrawlerNormalizeResponse> NormalizeCrawlerDataAsync(AiWorkerCrawlerNormalizeRequest request)
        {
            return PostWorkerJsonAsync<AiWorkerCrawlerNormalizeResponse>(
                "/admin/crawler/normalize",
                request,
                TimeSpan.FromSeconds(60));
        }

        public Task<AiWorkerCrawlerIngestResponse> IngestCrawlerDataAsync(AiWorkerCrawlerIngestRequest request)
        {
            return PostWorkerJsonAsync<AiWorkerCrawlerIngestResponse>(
                "/admin/crawler/ingest",
                request,
                TimeSpan.FromMinutes(5));
        }

        public Task<AiWorkerCreateTrainingSampleResponse> CreateTrainingSampleAsync(AiWorkerCreateTrainingSampleRequest request)
        {
            return PostWorkerJsonAsync<AiWorkerCreateTrainingSampleResponse>(
                "/api/ai/training-samples",
                request,
                TimeSpan.FromSeconds(30));
        }

        public Task<AiWorkerCreateTrainingSampleResponse> CreateTrainingSampleFromFeedbackAsync(
            string feedbackId,
            AiWorkerCreateSampleFromFeedbackRequest request)
        {
            var path = "/api/ai/feedback/" + Uri.EscapeDataString(feedbackId.Trim()) + "/to-training-sample";
            return PostWorkerJsonAsync<AiWorkerCreateTrainingSampleResponse>(
                path,
                request,
                TimeSpan.FromSeconds(30));
        }

        public Task<AiWorkerTrainingSampleListResponse> ListTrainingSamplesAsync(string? status = null, int limit = 50)
        {
            var safeLimit = Math.Clamp(limit, 1, 500);
            var query = "?limit=" + safeLimit;
            if (!string.IsNullOrWhiteSpace(status))
            {
                query += "&status=" + Uri.EscapeDataString(status.Trim());
            }

            return GetWorkerJsonAsync<AiWorkerTrainingSampleListResponse>(
                "/api/ai/training-samples" + query,
                TimeSpan.FromSeconds(30));
        }

        public Task<AiWorkerTrainingSampleResponse> ReviewTrainingSampleAsync(
            string sampleId,
            AiWorkerReviewTrainingSampleRequest request)
        {
            var path = "/api/ai/training-samples/" + Uri.EscapeDataString(sampleId.Trim()) + "/review";
            return PatchWorkerJsonAsync<AiWorkerTrainingSampleResponse>(
                path,
                request,
                TimeSpan.FromSeconds(30));
        }

        public Task<JsonElement> RunNightlyCurationAsync(int limit = 200)
        {
            var safeLimit = Math.Clamp(limit, 1, 2000);
            return PostWorkerJsonElementAsync(
                "/api/ai/curation/nightly?limit=" + safeLimit,
                new { },
                TimeSpan.FromMinutes(5));
        }

        private async Task<AiConversation> ResolveConversationAsync(Guid userId, Guid? conversationId, string message)
        {
            if (conversationId.HasValue)
            {
                var existing = await _db.AiConversations.FirstOrDefaultAsync(x => x.Id == conversationId.Value && x.UserId == userId);
                if (existing != null)
                {
                    return existing;
                }
            }

            var conversation = new AiConversation
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = BuildConversationTitle(message),
                CreatedAt = DateTimeOffset.UtcNow,
            };

            _db.AiConversations.Add(conversation);
            await _db.SaveChangesAsync();
            return conversation;
        }

        private async Task<string?> BuildUserContextAsync(Guid userId)
        {
            var healthProfile = await _db.HealthProfiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var profile = await _db.Profiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var aiProfile = await _db.UserAiProfiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var allergies = await _db.Allergies.AsNoTracking()
                .Where(x => x.UserId == userId && x.IsActive)
                .Select(x => x.Name)
                .ToListAsync();
            var recentNutrition = await _db.NutritionSnapshots.AsNoTracking()
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.SnapshotDate)
                .FirstOrDefaultAsync();

            var parts = new List<string>();

            if (profile != null)
            {
                parts.Add("profile: "
                    + $"full_name={profile.FullName ?? "unknown"}, "
                    + $"gender={profile.Gender ?? "unknown"}, "
                    + $"preferred_cuisine={profile.PreferredCuisine ?? "unknown"}");
            }

            if (healthProfile != null)
            {
                parts.Add("health: "
                    + $"goal={healthProfile.Goal ?? "unknown"}, "
                    + $"activity={healthProfile.ActivityLevel ?? "unknown"}, "
                    + $"target_calories={healthProfile.TargetCalories?.ToString() ?? "unknown"}, "
                    + $"target_protein={healthProfile.TargetProteinG?.ToString() ?? "unknown"}, "
                    + $"target_carbs={healthProfile.TargetCarbsG?.ToString() ?? "unknown"}, "
                    + $"target_fat={healthProfile.TargetFatG?.ToString() ?? "unknown"}");
            }

            if (allergies.Count > 0)
            {
                parts.Add("allergies: " + string.Join(", ", allergies.Where(x => !string.IsNullOrWhiteSpace(x))));
            }

            if (aiProfile != null)
            {
                parts.Add("ai_profile: "
                    + $"preferences={aiProfile.Preferences ?? "none"}, "
                    + $"disliked={aiProfile.DislikedFoods ?? "none"}, "
                    + $"pattern={aiProfile.EatingPattern ?? "none"}");
            }

            if (recentNutrition != null)
            {
                parts.Add("recent_nutrition: "
                    + $"date={recentNutrition.SnapshotDate:yyyy-MM-dd}, "
                    + $"calories={recentNutrition.TotalCalories}, "
                    + $"protein={recentNutrition.TotalProteinG}, "
                    + $"carbs={recentNutrition.TotalCarbsG}, "
                    + $"fat={recentNutrition.TotalFatG}, "
                    + $"goal_completion={recentNutrition.GoalCompletionPercent}");
            }

            if (parts.Count == 0)
            {
                return null;
            }

            return "MenuGreen user context. Use it only when relevant. " + string.Join(" | ", parts);
        }

        private async Task<IReadOnlyList<WorkerConversationMessage>> BuildConversationHistoryAsync(Guid conversationId, string? userContext)
        {
            var history = await _db.AiMessages
                .AsNoTracking()
                .Where(x => x.ConversationId == conversationId)
                .OrderByDescending(x => x.CreatedAt)
                .Take(12)
                .OrderBy(x => x.CreatedAt)
                .Select(x => new WorkerConversationMessage
                {
                    Role = NormalizeRole(x.Role),
                    Content = x.Content ?? string.Empty,
                })
                .ToListAsync();

            if (!string.IsNullOrWhiteSpace(userContext))
            {
                history.Insert(0, new WorkerConversationMessage
                {
                    Role = "system",
                    Content = userContext,
                });
            }

            return history;
        }

        private async Task<WorkerChatResponse> CallWorkerAsync(
            NutritionAssistantChatRequest request,
            AiConversation conversation,
            IReadOnlyList<WorkerConversationMessage> conversationHistory)
        {
            var baseUrl = BuildWorkerChatUrl(_configuration["NutritionAssistant:WorkerUrl"]);
            var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
            client.Timeout = TimeSpan.FromSeconds(60);

            var payload = new
            {
                message = request.Message.Trim(),
                user_id = conversation.UserId.ToString(),
                thread_id = conversation.Id.ToString(),
                request_id = Guid.NewGuid().ToString(),
                conversation_history = conversationHistory,
                skip_save = true,
            };

            try
            {
                using var workerRequest = CreateWorkerRequest(HttpMethod.Post, baseUrl, isAbsoluteUrl: true);
                workerRequest.Content = JsonContent.Create(payload, options: JsonOptions);
                using var response = await client.SendAsync(workerRequest);
                response.EnsureSuccessStatusCode();

                var body = await response.Content.ReadFromJsonAsync<WorkerChatResponse>(JsonOptions);
                if (body == null || string.IsNullOrWhiteSpace(body.Response))
                {
                    throw new InvalidOperationException("Worker response is empty.");
                }

                return body;
            }
            catch (Exception)
            {
                return new WorkerChatResponse
                {
                    Response = $"[AI Assistant Fallback] Sorry, the AI Worker system is currently unavailable. You asked: \"{request.Message}\". Auto recommendation: Maintain a balanced diet, exercise regularly, and drink enough water every day.",
                    Intent = "general",
                    Source = "fallback",
                    RequestId = Guid.NewGuid().ToString()
                };
            }
        }

        private async Task<TResponse> GetWorkerJsonAsync<TResponse>(string path, TimeSpan timeout)
        {
            var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
            client.Timeout = timeout;

            using var request = CreateWorkerRequest(HttpMethod.Get, path);
            using var response = await client.SendAsync(request);
            await EnsureWorkerSuccessAsync(response);

            var body = await response.Content.ReadFromJsonAsync<TResponse>(JsonOptions);
            return body ?? throw new InvalidOperationException("Worker response is empty.");
        }

        private async Task<JsonElement> GetWorkerJsonElementAsync(string path, TimeSpan timeout)
        {
            var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
            client.Timeout = timeout;

            using var request = CreateWorkerRequest(HttpMethod.Get, path);
            using var response = await client.SendAsync(request);
            await EnsureWorkerSuccessAsync(response);
            return await ReadJsonElementAsync(response.Content);
        }

        private async Task<TResponse> PostWorkerJsonAsync<TResponse>(string path, object payload, TimeSpan timeout)
        {
            var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
            client.Timeout = timeout;

            using var request = CreateWorkerRequest(HttpMethod.Post, path);
            request.Content = JsonContent.Create(payload, options: JsonOptions);
            using var response = await client.SendAsync(request);
            await EnsureWorkerSuccessAsync(response);

            var body = await response.Content.ReadFromJsonAsync<TResponse>(JsonOptions);
            return body ?? throw new InvalidOperationException("Worker response is empty.");
        }

        private async Task<JsonElement> PostWorkerJsonElementAsync(string path, object payload, TimeSpan timeout)
        {
            var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
            client.Timeout = timeout;

            using var request = CreateWorkerRequest(HttpMethod.Post, path);
            request.Content = JsonContent.Create(payload, options: JsonOptions);
            using var response = await client.SendAsync(request);
            await EnsureWorkerSuccessAsync(response);
            return await ReadJsonElementAsync(response.Content);
        }

        private async Task<TResponse> PatchWorkerJsonAsync<TResponse>(string path, object payload, TimeSpan timeout)
        {
            var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
            client.Timeout = timeout;

            using var request = CreateWorkerRequest(HttpMethod.Patch, path);
            request.Content = JsonContent.Create(payload, options: JsonOptions);

            using var response = await client.SendAsync(request);
            await EnsureWorkerSuccessAsync(response);

            var body = await response.Content.ReadFromJsonAsync<TResponse>(JsonOptions);
            return body ?? throw new InvalidOperationException("Worker response is empty.");
        }

        private static async Task EnsureWorkerSuccessAsync(HttpResponseMessage response)
        {
            if (response.IsSuccessStatusCode)
            {
                return;
            }

            var body = await response.Content.ReadAsStringAsync();
            throw new InvalidOperationException(
                $"AI worker returned {(int)response.StatusCode} {response.ReasonPhrase}: {body}");
        }

        private static async Task<JsonElement> ReadJsonElementAsync(HttpContent content)
        {
            await using var stream = await content.ReadAsStreamAsync();
            using var document = await JsonDocument.ParseAsync(stream);
            return document.RootElement.Clone();
        }

        private async Task SaveWorkerRecommendationHistoryAsync(
            Guid userId,
            string mode,
            object input,
            JsonElement output)
        {
            var history = new RecommendationHistory
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Type = "AIWorker:" + mode,
                Input = JsonSerializer.Serialize(input, JsonOptions),
                Output = output.GetRawText(),
                Confidence = TryReadConfidence(output),
                CreatedAt = DateTimeOffset.UtcNow,
            };

            _db.RecommendationHistories.Add(history);
            await _db.SaveChangesAsync();
        }

        private static decimal? TryReadConfidence(JsonElement output)
        {
            if (output.ValueKind != JsonValueKind.Object)
            {
                return 0.85m;
            }

            if (output.TryGetProperty("scores", out var scores) && scores.ValueKind == JsonValueKind.Object)
            {
                var totals = new List<decimal>();
                foreach (var score in scores.EnumerateObject())
                {
                    if (score.Value.ValueKind == JsonValueKind.Object
                        && score.Value.TryGetProperty("total", out var total)
                        && total.TryGetDecimal(out var value))
                    {
                        totals.Add(value);
                    }
                }

                if (totals.Count > 0)
                {
                    return Math.Round(totals.Average(), 4);
                }
            }

            return 0.85m;
        }

        private HttpRequestMessage CreateWorkerRequest(HttpMethod method, string pathOrUrl, bool isAbsoluteUrl = false)
        {
            var url = isAbsoluteUrl ? pathOrUrl : BuildWorkerEndpointUrl(pathOrUrl);
            var request = new HttpRequestMessage(method, url);
            var internalKey = _configuration["NutritionAssistant:WorkerInternalKey"]
                ?? _configuration["AI_RUNTIME_INTERNAL_KEY"];
            if (!string.IsNullOrWhiteSpace(internalKey))
            {
                request.Headers.TryAddWithoutValidation("X-AI-Runtime-Key", internalKey.Trim());
            }

            return request;
        }

        private static string BuildRecommendationPath(string mode)
        {
            var normalized = (mode ?? string.Empty).Trim().ToLowerInvariant();
            var allowedModes = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "generate",
                "safe",
                "daily-menu",
                "weekly-plan",
                "budget-aware",
                "smart-schedule",
            };

            if (!allowedModes.Contains(normalized))
            {
                throw new InvalidOperationException("Unsupported AI recommendation mode.");
            }

            return "/api/ai/recommendations/" + normalized;
        }

        private string BuildWorkerEndpointUrl(string path)
        {
            var rootUrl = BuildWorkerRootUrl(_configuration["NutritionAssistant:WorkerUrl"]);
            return rootUrl.TrimEnd('/') + "/" + path.TrimStart('/');
        }

        private static string BuildConversationTitle(string message)
        {
            var normalized = message.Trim();
            if (normalized.Length <= 60)
            {
                return normalized;
            }

            return normalized[..60].Trim() + "...";
        }

        private static string BuildPreview(string? content)
        {
            if (string.IsNullOrWhiteSpace(content))
            {
                return string.Empty;
            }

            var normalized = content.Trim();
            if (normalized.Length <= 120)
            {
                return normalized;
            }

            return normalized[..120].Trim() + "...";
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

        private static string BuildWorkerHealthUrl(string workerChatUrl)
        {
            if (workerChatUrl.EndsWith("/worker/chat", StringComparison.OrdinalIgnoreCase))
            {
                return workerChatUrl[..^"/worker/chat".Length] + "/health";
            }

            return workerChatUrl.TrimEnd('/') + "/health";
        }

        private static string BuildWorkerRootUrl(string? configuredUrl)
        {
            var workerChatUrl = BuildWorkerChatUrl(configuredUrl);
            if (workerChatUrl.EndsWith("/worker/chat", StringComparison.OrdinalIgnoreCase))
            {
                return workerChatUrl[..^"/worker/chat".Length];
            }

            return workerChatUrl.TrimEnd('/');
        }

        private sealed class WorkerConversationMessage
        {
            [JsonPropertyName("role")]
            public string Role { get; set; } = "user";

            [JsonPropertyName("content")]
            public string Content { get; set; } = string.Empty;
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

        private sealed class WorkerHealthResponse
        {
            [JsonPropertyName("status")]
            public string? Status { get; set; }

            [JsonPropertyName("service")]
            public string? Service { get; set; }
        }
    }
}
