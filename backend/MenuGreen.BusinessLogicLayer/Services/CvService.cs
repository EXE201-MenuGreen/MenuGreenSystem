using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
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
        private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

        public CvService(
            ApplicationDbContext db,
            IAllergenMatchingService allergenMatching,
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration)
        {
            _db = db;
            _allergenMatching = allergenMatching;
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
        }

        public async Task<CvInferenceResponse> AnalyzeImageAsync(Guid userId, Stream imageStream, string fileName, string contentType)
        {
            if (imageStream == null || imageStream.Length == 0)
            {
                throw new ArgumentException("Image stream is missing or empty.");
            }

            var baseUrl = _configuration["CvService:BaseUrl"] ?? "http://127.0.0.1:8000";
            var apiKey = _configuration["CvService:ApiSecretKey"] ?? string.Empty;

            var client = _httpClientFactory.CreateClient(nameof(CvService));
            client.Timeout = TimeSpan.FromSeconds(60);

            // 1. Send image to POST /api/v1/cv/analyze
            var analyzeUrl = $"{baseUrl.TrimEnd('/')}/api/v1/cv/analyze";
            var analyzeRequest = new HttpRequestMessage(HttpMethod.Post, analyzeUrl);

            if (!string.IsNullOrWhiteSpace(apiKey))
            {
                analyzeRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
            }

            var multipartContent = new MultipartFormDataContent();
            var streamContent = new StreamContent(imageStream);
            
            var mtype = string.IsNullOrWhiteSpace(contentType) ? "image/jpeg" : contentType;
            streamContent.Headers.ContentType = new MediaTypeHeaderValue(mtype);
            multipartContent.Add(streamContent, "image", fileName ?? "image.jpg");
            analyzeRequest.Content = multipartContent;

            using var analyzeResponse = await client.SendAsync(analyzeRequest);
            analyzeResponse.EnsureSuccessStatusCode();

            var jobResponse = await analyzeResponse.Content.ReadFromJsonAsync<CvJobResponse>(JsonOptions);
            if (jobResponse == null || string.IsNullOrWhiteSpace(jobResponse.JobId))
            {
                throw new InvalidOperationException("Failed to initiate image analysis: No Job ID returned.");
            }

            var jobId = jobResponse.JobId;

            // 2. Poll GET /api/v1/cv/jobs/{job_id} synchronously (blocking loop)
            CvJobStatusResponse? jobStatus = null;
            int maxAttempts = 20;
            int attempt = 0;
            bool isCompleted = false;

            while (attempt < maxAttempts)
            {
                attempt++;
                await Task.Delay(2000); // Wait 2 seconds before checking

                var pollUrl = $"{baseUrl.TrimEnd('/')}/api/v1/cv/jobs/{jobId}";
                var pollRequest = new HttpRequestMessage(HttpMethod.Get, pollUrl);

                if (!string.IsNullOrWhiteSpace(apiKey))
                {
                    pollRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
                }

                using var pollResponse = await client.SendAsync(pollRequest);
                pollResponse.EnsureSuccessStatusCode();

                jobStatus = await pollResponse.Content.ReadFromJsonAsync<CvJobStatusResponse>(JsonOptions);
                if (jobStatus == null)
                {
                    throw new InvalidOperationException("Failed to read status response from AI service.");
                }

                if (string.Equals(jobStatus.Status, "done", StringComparison.OrdinalIgnoreCase))
                {
                    isCompleted = true;
                    break;
                }

                if (string.Equals(jobStatus.Status, "failed", StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException($"AI CV Service analysis failed: {jobStatus.Error ?? "Unknown error"}");
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
                        var risk = await _allergenMatching.EvaluateRecipeRiskAsync(null, ingredientNames, userId);
                        dish.IsSafeForUser = risk.IsSafeForUser;
                        dish.MatchedAllergens = risk.MatchedAllergens?.ToList() ?? new List<string>();
                    }
                }
            }

            // 4. Save analysis results to database (activity_logs)
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

            return result;
        }
    }
}
