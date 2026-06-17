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
    public class NutritionAssistantService : INutritionAssistantService
    {
        private const string DefaultWorkerChatUrl = "http://127.0.0.1:8000/worker/chat";
        private readonly ApplicationDbContext _db;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

        public NutritionAssistantService(
            ApplicationDbContext db,
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration)
        {
            _db = db;
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
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
            var healthUrl = BuildWorkerHealthUrl(workerUrl);

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
            };

            using var response = await client.PostAsJsonAsync(baseUrl, payload, JsonOptions);
            response.EnsureSuccessStatusCode();

            var body = await response.Content.ReadFromJsonAsync<WorkerChatResponse>(JsonOptions);
            if (body == null || string.IsNullOrWhiteSpace(body.Response))
            {
                throw new InvalidOperationException("Worker response is empty.");
            }

            return body;
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
