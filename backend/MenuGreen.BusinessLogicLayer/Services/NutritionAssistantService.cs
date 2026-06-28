using System;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
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

            var context = await BuildUserContextAsync(userGuid);
            var workerResponse = await CallWorkerAsync(request, conversation, context);

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
                SafetyNotice = workerResponse.Intent == "medical" ? "Đây chỉ là tư vấn tham khảo, nếu có triệu chứng bất thường hãy liên hệ chuyên gia y tế." : null,
                Intent = workerResponse.Intent,
                Source = workerResponse.Source,
                RequestId = workerResponse.RequestId,
                ThreadId = workerResponse.ThreadId,
                IntentConfidence = workerResponse.IntentConfidence,
                SubscriptionTier = workerResponse.SubscriptionTier,
            };
        }

        private async Task<AiConversation> ResolveConversationAsync(Guid userId, Guid? conversationId, string message)
        {
            if (conversationId.HasValue)
            {
                var existing = await _db.AiConversations.FirstOrDefaultAsync(x => x.Id == conversationId.Value && x.UserId == userId);
                if (existing != null) return existing;
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
            NutritionAssistantChatRequest request,
            AiConversation conversation,
            object context)
        {
            var baseUrl = _configuration["NutritionAssistant:WorkerUrl"] ?? "http://127.0.0.1:8010/worker/chat";
            var client = _httpClientFactory.CreateClient(nameof(NutritionAssistantService));
            client.Timeout = TimeSpan.FromSeconds(60);

            var payload = new
            {
                conversationId = conversation.Id,
                thread_id = conversation.Id.ToString(),
                language = request.Language,
                stream = request.Stream,
                domain = "nutrition",
                systemPrompt = BuildSystemPrompt(),
                userMessage = request.Message,
                context,
            };

            try
            {
                using var response = await client.PostAsJsonAsync(baseUrl, payload, JsonOptions);
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

        private static string BuildSystemPrompt()
        {
            return "Bạn là AI Nutrition Assistant của MenuGreen. Hãy tư vấn dinh dưỡng bằng tiếng Việt, ngắn gọn, dễ hiểu, thực tế, an toàn. Không chẩn đoán bệnh, không thay thế bác sĩ. Nếu câu hỏi có nguy cơ sức khỏe, hãy khuyên người dùng gặp chuyên gia y tế.";
        }

        private static string BuildConversationTitle(string message)
        {
            var normalized = message.Trim();
            if (normalized.Length <= 60) return normalized;
            return normalized[..60].Trim() + "...";
        }

        private sealed class WorkerChatResponse
        {
            public string Response { get; set; } = string.Empty;
            public string? Intent { get; set; }
            public string? Source { get; set; }
            public string? RequestId { get; set; }
            public string? ThreadId { get; set; }
            public decimal? IntentConfidence { get; set; }
            public string? SubscriptionTier { get; set; }
        }
    }
}
