using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Configuration;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class CvService : ICvService
    {
        private readonly ApplicationDbContext _db;
        private readonly IAllergenMatchingService _allergenMatching;
        private readonly INutritionTrackingService _nutritionTrackingService;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly CvServiceOptions _options;
        private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

        public CvService(
            ApplicationDbContext db,
            IAllergenMatchingService allergenMatching,
            INutritionTrackingService nutritionTrackingService,
            IHttpClientFactory httpClientFactory,
            IOptions<CvServiceOptions> options
        )
        {
            _db = db;
            _allergenMatching = allergenMatching;
            _nutritionTrackingService = nutritionTrackingService;
            _httpClientFactory = httpClientFactory;
            _options = options.Value;
        }

        public async Task<CvInferenceResponse> AnalyzeImageAsync(
            Guid userId,
            Stream imageStream,
            string fileName,
            string contentType
        )
        {
            if (imageStream == null || imageStream.Length == 0)
            {
                throw new ArgumentException("Image stream is missing or empty.");
            }

            if (string.IsNullOrWhiteSpace(_options.BaseUrl))
            {
                throw new InvalidOperationException("CvService:BaseUrl is not configured.");
            }

            var baseUrl = _options.BaseUrl.TrimEnd('/');
            var apiVersion = NormalizeApiVersion(_options.ApiVersion);
            var apiKey = _options.ApiSecretKey ?? string.Empty;

            var client = _httpClientFactory.CreateClient(nameof(CvService));
            client.Timeout = TimeSpan.FromSeconds(Math.Max(_options.PollTimeoutSeconds + 15, 30));

            // 1. Send image to POST /api/{version}/cv/analyze
            var analyzeUrl = $"{baseUrl}/api/{apiVersion}/cv/analyze";
            var analyzeRequest = new HttpRequestMessage(HttpMethod.Post, analyzeUrl);

            if (!string.IsNullOrWhiteSpace(apiKey))
            {
                analyzeRequest.Headers.Authorization = new AuthenticationHeaderValue(
                    "Bearer",
                    apiKey
                );
            }
            analyzeRequest.Headers.Add("X-User-Id", userId.ToString());

            var multipartContent = new MultipartFormDataContent();
            var streamContent = new StreamContent(imageStream);

            var mtype = string.IsNullOrWhiteSpace(contentType) ? "image/jpeg" : contentType;
            streamContent.Headers.ContentType = new MediaTypeHeaderValue(mtype);
            multipartContent.Add(streamContent, "image", fileName ?? "image.jpg");
            multipartContent.Add(new StringContent(userId.ToString()), "user_id");
            multipartContent.Add(
                new StringContent(
                    JsonSerializer.Serialize(await BuildUserContextAsync(userId), JsonOptions),
                    Encoding.UTF8,
                    "application/json"
                ),
                "user_context"
            );
            analyzeRequest.Content = multipartContent;

            using var analyzeResponse = await client.SendAsync(analyzeRequest);
            if (!analyzeResponse.IsSuccessStatusCode)
            {
                var error = await analyzeResponse.Content.ReadAsStringAsync();
                throw new InvalidOperationException(
                    $"AI CV Service rejected the image analysis request: {(int)analyzeResponse.StatusCode} {analyzeResponse.ReasonPhrase}. {error}"
                );
            }

            var jobResponse = await analyzeResponse.Content.ReadFromJsonAsync<CvJobResponse>(
                JsonOptions
            );
            if (jobResponse == null || string.IsNullOrWhiteSpace(jobResponse.JobId))
            {
                throw new InvalidOperationException(
                    "Failed to initiate image analysis: No Job ID returned."
                );
            }

            var jobId = jobResponse.JobId;

            // 2. Poll GET /api/{version}/cv/jobs/{job_id} synchronously (blocking loop)
            CvJobStatusResponse? jobStatus = null;
            var pollTimeoutSeconds = Math.Max(_options.PollTimeoutSeconds, 1);
            var pollIntervalSeconds = Math.Max(_options.PollIntervalSeconds, 1);
            var deadline = DateTimeOffset.UtcNow.AddSeconds(pollTimeoutSeconds);
            int attempt = 0;
            bool isCompleted = false;

            while (DateTimeOffset.UtcNow < deadline)
            {
                attempt++;
                await Task.Delay(TimeSpan.FromSeconds(pollIntervalSeconds));

                var pollUrl = $"{baseUrl}/api/{apiVersion}/cv/jobs/{jobId}";
                var pollRequest = new HttpRequestMessage(HttpMethod.Get, pollUrl);

                if (!string.IsNullOrWhiteSpace(apiKey))
                {
                    pollRequest.Headers.Authorization = new AuthenticationHeaderValue(
                        "Bearer",
                        apiKey
                    );
                }

                using var pollResponse = await client.SendAsync(pollRequest);
                if (!pollResponse.IsSuccessStatusCode)
                {
                    var error = await pollResponse.Content.ReadAsStringAsync();
                    throw new InvalidOperationException(
                        $"AI CV Service job polling failed: {(int)pollResponse.StatusCode} {pollResponse.ReasonPhrase}. {error}"
                    );
                }

                jobStatus = await pollResponse.Content.ReadFromJsonAsync<CvJobStatusResponse>(
                    JsonOptions
                );
                if (jobStatus == null)
                {
                    throw new InvalidOperationException(
                        "Failed to read status response from AI service."
                    );
                }

                if (string.Equals(jobStatus.Status, "done", StringComparison.OrdinalIgnoreCase))
                {
                    isCompleted = true;
                    break;
                }

                if (string.Equals(jobStatus.Status, "failed", StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException(
                        $"AI CV Service analysis failed: {jobStatus.Error ?? "Unknown error"}"
                    );
                }
            }

            if (!isCompleted || jobStatus?.Result == null)
            {
                throw new TimeoutException("The image analysis task timed out on the AI service.");
            }

            var result = jobStatus.Result;

            // 3. Process Business Logic: Match ingredients against user allergies
            if (result.DanhSachMonAnGoiY != null && result.DanhSachMonAnGoiY.Count > 0)
            {
                foreach (var dish in result.DanhSachMonAnGoiY)
                {
                    if (dish.NguyenLieuSuDung != null && dish.NguyenLieuSuDung.Count > 0)
                    {
                        var ingredientNames = dish.NguyenLieuSuDung.Select(x => x.Ten).ToList();
                        var risk = await _allergenMatching.EvaluateRecipeRiskAsync(
                            null,
                            ingredientNames,
                            userId
                        );
                        dish.IsSafeForUser = risk.IsSafeForUser;
                        dish.MatchedAllergens =
                            risk.MatchedAllergens?.ToList() ?? new List<string>();
                    }
                }
            }

            // 4. Save analysis results to database (activity_logs)
            var jobGuid = Guid.TryParse(result.JobId, out var parsedGuid)
                ? parsedGuid
                : Guid.NewGuid();
            var log = new ActivityLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Action = "CV_ANALYZE_IMAGE",
                EntityType = "CvInference",
                EntityId = jobGuid,
                Metadata = JsonSerializer.Serialize(result, JsonOptions),
                CreatedAt = DateTimeOffset.UtcNow,
            };

            _db.ActivityLogs.Add(log);
            await _db.SaveChangesAsync();

            return result;
        }

        public async Task<MealLogResponse> CreateMealLogFromCvDishAsync(
            Guid userId,
            CvMealLogCreateRequest request
        )
        {
            if (request == null)
            {
                throw new ArgumentException("Request body is required.");
            }

            var dish = request.Dish ?? throw new ArgumentException("Dish is required.");
            if (string.IsNullOrWhiteSpace(dish.TenMonAn))
            {
                throw new ArgumentException("Dish name is required.");
            }

            if (string.IsNullOrWhiteSpace(request.MealType))
            {
                throw new ArgumentException("MealType is required.");
            }

            if (request.QuantityG <= 0)
            {
                throw new ArgumentException("QuantityG must be greater than 0.");
            }

            var nutrition = dish.ThongTinDinhDuongMonAn ?? new CvNutritionInfo();
            var cvNotes = new
            {
                Source = "CV",
                AnalysisJobId = request.AnalysisJobId,
                AnalysisRequestId = request.AnalysisRequestId,
                DishId = dish.IdMonAnGoiY,
                DishName = dish.TenMonAn,
                TechnicalName = dish.TenMonAnKyThuat,
                Confidence = dish.Confidence,
                Feasibility = dish.DoKhaThi,
                Description = dish.MoTaNgan,
                IsSafeForUser = dish.IsSafeForUser,
                MatchedAllergens = dish.MatchedAllergens,
                UserNotes = request.Notes,
            };

            var mealLog = await _nutritionTrackingService.CreateMealLogAsync(
                userId,
                new MealLogUpsertRequest
                {
                    MealType = request.MealType,
                    QuantityG = request.QuantityG,
                    LoggedAt = request.LoggedAt,
                    CaloriesKcal = ToDecimal(nutrition.TongCalories),
                    ProteinG = ToDecimal(nutrition.ProteinG),
                    CarbsG = ToDecimal(nutrition.CarbsG),
                    FatG = ToDecimal(nutrition.FatG),
                    Notes = JsonSerializer.Serialize(cvNotes, JsonOptions),
                }
            );

            await MarkMealLogAsCvSourceAsync(userId, mealLog.Id);
            mealLog.DisplayName = dish.TenMonAn;
            mealLog.SourceType = "CV";
            return mealLog;
        }

        private static decimal? ToDecimal(double value)
        {
            if (double.IsNaN(value) || double.IsInfinity(value) || value < 0)
            {
                return null;
            }

            return Math.Round((decimal)value, 2);
        }

        private static string NormalizeApiVersion(string? apiVersion)
        {
            var version = string.IsNullOrWhiteSpace(apiVersion) ? "v1" : apiVersion.Trim();
            return version
                .Trim('/')
                .Replace("api/", string.Empty, StringComparison.OrdinalIgnoreCase);
        }

        private async Task MarkMealLogAsCvSourceAsync(Guid userId, Guid mealLogId)
        {
            var entity = await _db.MealLogs.FirstOrDefaultAsync(x =>
                x.Id == mealLogId && x.UserId == userId
            );
            if (entity == null)
            {
                throw new InvalidOperationException("Created CV meal log could not be found.");
            }

            entity.SourceType = "CV";
            await _db.SaveChangesAsync();
        }

        private async Task<object> BuildUserContextAsync(Guid userId)
        {
            var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(x => x.Id == userId);
            var profile = await _db.Profiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var health = await _db.HealthProfiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var aiProfile = await _db.UserAiProfiles.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId);
            var allergies = await _db.Allergies
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.IsActive)
                .Select(x => new
                {
                    x.Id,
                    x.Name,
                    x.Notes
                })
                .ToListAsync();

            return new
            {
                UserId = userId,
                IsActive = user?.IsActive ?? true,
                Profile = profile == null
                    ? null
                    : new
                    {
                        profile.FullName,
                        DateOfBirth = profile.DateOfBirth?.ToString("yyyy-MM-dd"),
                        profile.Gender,
                        profile.PreferredCuisine
                    },
                HealthProfile = health == null
                    ? null
                    : new
                    {
                        health.HeightCm,
                        health.WeightKg,
                        health.BodyFatPercent,
                        health.ActivityLevel,
                        health.Goal,
                        health.Bmi,
                        health.BmrKcal,
                        health.TdeeKcal,
                        health.TargetCalories,
                        health.TargetProteinG,
                        health.TargetCarbsG,
                        health.TargetFatG
                    },
                AiProfile = aiProfile == null
                    ? null
                    : new
                    {
                        aiProfile.Preferences,
                        aiProfile.DislikedFoods,
                        aiProfile.EatingPattern
                    },
                Allergies = allergies
            };
        }
    }
}
