using System;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Entities;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class CvService : ICvService
    {
        private readonly ApplicationDbContext _db;
        private readonly IAllergenMatchingService _allergenMatching;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private readonly ILogger<CvService> _logger;
        private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

        // Limits for input validation
        private const long MaxImageBytes = 10 * 1024 * 1024; // 10MB
        private const int MaxDimension = 4096;

        public CvService(
            ApplicationDbContext db,
            IAllergenMatchingService allergenMatching,
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration,
            ILogger<CvService> logger)
        {
            _db = db;
            _allergenMatching = allergenMatching;
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<CvInferenceResponse> AnalyzeImageAsync(Guid userId, Stream imageStream, string fileName, string contentType)
        {
            return await AnalyzeImageWithPollingAsync(userId, imageStream, fileName, contentType);
        }

        public async Task<PreparedMealScanResponse> AnalyzePreparedMealAsync(
            Guid userId, Stream imageStream, string fileName, string contentType)
        {
            ValidateImage(imageStream, contentType);

            var baseUrl = _configuration["CvService:BaseUrl"] ?? "https://vision.menugreen.food";
            var apiKey = _configuration["CvService:ApiSecretKey"] ?? string.Empty;
            var client = _httpClientFactory.CreateClient(nameof(CvService));
            client.Timeout = TimeSpan.FromSeconds(110);

            try
            {
                using var request = new HttpRequestMessage(
                    HttpMethod.Post,
                    $"{baseUrl.TrimEnd('/')}/api/v1/cv/analyze-meal-sync");
                if (!string.IsNullOrWhiteSpace(apiKey))
                {
                    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
                }

                if (imageStream.CanSeek) imageStream.Position = 0;
                using var content = new MultipartFormDataContent();
                using var imageContent = new StreamContent(imageStream);
                imageContent.Headers.ContentType = new MediaTypeHeaderValue(contentType);
                content.Add(imageContent, "image", fileName ?? "meal.jpg");
                content.Add(new StringContent("90"), "timeout_seconds");
                request.Content = content;

                using var response = await client.SendAsync(request);
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("Prepared meal scan failed with status {Status}", response.StatusCode);
                    throw new InvalidOperationException("Không thể phân tích món ăn lúc này. Vui lòng thử lại sau.");
                }

                var result = await response.Content.ReadFromJsonAsync<PreparedMealScanResponse>(JsonOptions);
                if (result == null)
                {
                    throw new InvalidOperationException("Không thể phân tích món ăn lúc này. Vui lòng thử lại sau.");
                }
                return result;
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "Failed to reach CV service for prepared meal scan");
                throw new InvalidOperationException("Không thể phân tích món ăn lúc này. Vui lòng thử lại sau.", ex);
            }
            catch (TaskCanceledException ex)
            {
                _logger.LogWarning(ex, "Prepared meal scan timed out");
                throw new TimeoutException("Phân tích món ăn mất nhiều thời gian. Vui lòng thử lại sau.", ex);
            }
        }

        private async Task<CvInferenceResponse> AnalyzeImageWithPollingAsync(
            Guid userId, Stream imageStream, string fileName, string contentType)
        {
            // 0. Validate input before any network call
            if (imageStream == null || imageStream.Length == 0)
            {
                throw new ArgumentException("Image stream is missing or empty.");
            }

            if (imageStream.Length > MaxImageBytes)
            {
                throw new ArgumentException($"Image exceeds maximum size of {MaxImageBytes / 1024 / 1024}MB.");
            }

            var allowedTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/webp" };
            var mtype = string.IsNullOrWhiteSpace(contentType) ? "image/jpeg" : contentType.ToLowerInvariant();
            if (!allowedTypes.Contains(mtype))
            {
                throw new ArgumentException($"Unsupported image type: {contentType}. Allowed: jpeg, png, webp.");
            }

            var baseUrl = _configuration["CvService:BaseUrl"] ?? "https://vision.menugreen.food";
            var apiKey = _configuration["CvService:ApiSecretKey"] ?? string.Empty;

            if (string.IsNullOrWhiteSpace(baseUrl))
            {
                _logger.LogError("CvService:BaseUrl is not configured");
                throw new InvalidOperationException("CV service is not properly configured.");
            }

            var client = _httpClientFactory.CreateClient(nameof(CvService));
            client.Timeout = TimeSpan.FromSeconds(120);

            string jobId;

            // 1. Submit image
            try
            {
                jobId = await SubmitImageAsync(client, baseUrl, apiKey, imageStream, fileName, mtype);
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "Failed to reach CV service at {BaseUrl}", baseUrl);
                throw new InvalidOperationException("AI service is unreachable. Please try again later.", ex);
            }
            catch (TaskCanceledException ex)
            {
                _logger.LogError(ex, "Timeout while submitting image to CV service");
                throw new InvalidOperationException("AI service took too long to accept the image.", ex);
            }
            catch (JsonException ex)
            {
                _logger.LogError(ex, "CV service returned invalid JSON on submit");
                throw new InvalidOperationException("AI service returned an invalid response.", ex);
            }

            // 2. Poll job status
            CvInferenceResponse? result;
            try
            {
                result = await PollJobUntilDoneAsync(client, baseUrl, apiKey, jobId);
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "Failed to poll job {JobId}", jobId);
                throw new InvalidOperationException("Lost connection to AI service while waiting for result.", ex);
            }
            catch (TaskCanceledException ex)
            {
                _logger.LogError(ex, "Polling timed out for job {JobId}", jobId);
                throw new TimeoutException("AI service took too long to analyze the image.", ex);
            }
            catch (JsonException ex)
            {
                _logger.LogError(ex, "CV service returned invalid JSON while polling job {JobId}", jobId);
                throw new InvalidOperationException("AI service returned an invalid status response.", ex);
            }

            if (result == null)
            {
                throw new TimeoutException("The image analysis task timed out on the AI service.");
            }

            // 3. Evaluate allergy risks (best-effort: never let this block the response)
            await TryEvaluateAllergensAsync(result, userId);

            // 4. Persist activity log (best-effort: never let this break the response)
            await TrySaveActivityLogAsync(result, userId);

            return result;
        }

        private static void ValidateImage(Stream imageStream, string contentType)
        {
            if (imageStream == null || imageStream.Length == 0)
            {
                throw new ArgumentException("Image stream is missing or empty.");
            }
            if (imageStream.Length > MaxImageBytes)
            {
                throw new ArgumentException($"Image exceeds maximum size of {MaxImageBytes / 1024 / 1024}MB.");
            }
            var allowedTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/webp" };
            var mtype = string.IsNullOrWhiteSpace(contentType) ? "image/jpeg" : contentType.ToLowerInvariant();
            if (!allowedTypes.Contains(mtype))
            {
                throw new ArgumentException($"Unsupported image type: {contentType}. Allowed: jpeg, png, webp.");
            }
        }

        private async Task<string> SubmitImageAsync(
            HttpClient client, string baseUrl, string apiKey,
            Stream imageStream, string fileName, string contentType)
        {
            var analyzeUrl = $"{baseUrl.TrimEnd('/')}/api/v1/cv/analyze";
            var analyzeRequest = new HttpRequestMessage(HttpMethod.Post, analyzeUrl);

            if (!string.IsNullOrWhiteSpace(apiKey))
            {
                analyzeRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
            }

            // Reset stream position in case it was already read
            if (imageStream.CanSeek)
            {
                imageStream.Position = 0;
            }

            var multipartContent = new MultipartFormDataContent();
            var streamContent = new StreamContent(imageStream);
            streamContent.Headers.ContentType = new MediaTypeHeaderValue(contentType);
            multipartContent.Add(streamContent, "image", fileName ?? "image.jpg");
            analyzeRequest.Content = multipartContent;

            using var response = await client.SendAsync(analyzeRequest);

            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                _logger.LogWarning("CV service submit failed: {Status} {Body}", response.StatusCode, errorBody);

                if (response.StatusCode == HttpStatusCode.Unauthorized)
                {
                    throw new InvalidOperationException("AI service rejected the API key. Please contact support.");
                }
                if (response.StatusCode == HttpStatusCode.TooManyRequests)
                {
                    throw new InvalidOperationException("AI service is rate-limited. Please try again in a few minutes.");
                }
                if (response.StatusCode == HttpStatusCode.BadRequest)
                {
                    throw new ArgumentException($"AI service rejected the image: {Truncate(errorBody, 200)}");
                }

                response.EnsureSuccessStatusCode(); // throws for 5xx
            }

            var jobResponse = await response.Content.ReadFromJsonAsync<CvJobResponse>(JsonOptions);
            if (jobResponse == null || string.IsNullOrWhiteSpace(jobResponse.JobId))
            {
                throw new InvalidOperationException("AI service did not return a job ID.");
            }

            return jobResponse.JobId;
        }

        private async Task<CvInferenceResponse?> PollJobUntilDoneAsync(
            HttpClient client, string baseUrl, string apiKey, string jobId)
        {
            const int maxAttempts = 30;
            const int delayMs = 2000;

            CvJobStatusResponse? jobStatus = null;
            var isCompleted = false;

            for (var attempt = 1; attempt <= maxAttempts; attempt++)
            {
                await Task.Delay(delayMs);

                var pollUrl = $"{baseUrl.TrimEnd('/')}/api/v1/cv/jobs/{jobId}";
                var pollRequest = new HttpRequestMessage(HttpMethod.Get, pollUrl);

                if (!string.IsNullOrWhiteSpace(apiKey))
                {
                    pollRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
                }

                using var pollResponse = await client.SendAsync(pollRequest);

                if (!pollResponse.IsSuccessStatusCode)
                {
                    // 5xx from CV service while polling: keep trying (transient)
                    if ((int)pollResponse.StatusCode >= 500)
                    {
                        _logger.LogWarning("Transient poll error {Status} on attempt {Attempt}/{Max}", pollResponse.StatusCode, attempt, maxAttempts);
                        continue;
                    }

                    // 4xx: don't retry
                    var errorBody = await pollResponse.Content.ReadAsStringAsync();
                    _logger.LogError("Poll failed permanently: {Status} {Body}", pollResponse.StatusCode, errorBody);
                    pollResponse.EnsureSuccessStatusCode();
                }

                jobStatus = await pollResponse.Content.ReadFromJsonAsync<CvJobStatusResponse>(JsonOptions);
                if (jobStatus == null)
                {
                    throw new InvalidOperationException("AI service returned an empty status response.");
                }

                if (string.Equals(jobStatus.Status, "done", StringComparison.OrdinalIgnoreCase))
                {
                    isCompleted = true;
                    break;
                }

                if (string.Equals(jobStatus.Status, "failed", StringComparison.OrdinalIgnoreCase))
                {
                    var reason = jobStatus.Error ?? "Unknown error";
                    _logger.LogWarning("CV job {JobId} failed: {Reason}", jobId, reason);
                    throw new InvalidOperationException($"AI analysis failed: {reason}");
                }
            }

            if (!isCompleted)
            {
                _logger.LogWarning("CV job {JobId} did not complete within {Max} attempts", jobId, maxAttempts);
                return null;
            }

            return jobStatus?.Result;
        }

        private async Task TryEvaluateAllergensAsync(CvInferenceResponse result, Guid userId)
        {
            if (result.DanhSachMonAnGoiY == null || result.DanhSachMonAnGoiY.Count == 0)
            {
                return;
            }

            foreach (var dish in result.DanhSachMonAnGoiY)
            {
                try
                {
                    if (dish.NguyenLieuSuDung == null || dish.NguyenLieuSuDung.Count == 0)
                    {
                        continue;
                    }

                    var ingredientNames = dish.NguyenLieuSuDung.Select(x => x.Ten).ToList();
                    var risk = await _allergenMatching.EvaluateRecipeRiskAsync(null, ingredientNames, userId);
                    dish.IsSafeForUser = risk.IsSafeForUser;
                    dish.MatchedAllergens = risk.MatchedAllergens?.ToList() ?? new List<string>();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Allergen evaluation failed for dish in job {JobId}", result.JobId);
                    // Continue with the next dish
                }
            }
        }

        private async Task TrySaveActivityLogAsync(CvInferenceResponse result, Guid userId)
        {
            try
            {
                var jobGuid = Guid.TryParse(result.JobId, out var parsedGuid) ? parsedGuid : Guid.NewGuid();
                var log = new ActivityLog
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Action = "CV_ANALYZE_IMAGE",
                    EntityType = "CvInference",
                    EntityId = jobGuid,
                    Metadata = JsonSerializer.Serialize(result, JsonOptions),
                    CreatedAt = DateTimeOffset.UtcNow
                };

                _db.ActivityLogs.Add(log);
                await _db.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to persist activity log for job {JobId} user {UserId}", result.JobId, userId);
                // Swallow: do not fail the user request because of logging
            }
        }

        private static string Truncate(string value, int maxLength)
        {
            if (string.IsNullOrEmpty(value) || value.Length <= maxLength)
            {
                return value ?? string.Empty;
            }
            return value.Substring(0, maxLength) + "...";
        }
    }
}
