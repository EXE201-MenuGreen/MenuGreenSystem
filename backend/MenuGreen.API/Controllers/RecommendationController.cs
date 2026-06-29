using System;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "UserOnly")]
    public class RecommendationController : ControllerBase
    {
        private readonly IRecommendationService _service;
        private readonly INutritionAssistantService _nutritionAssistantService;

        public RecommendationController(
            IRecommendationService service,
            INutritionAssistantService nutritionAssistantService)
        {
            _service = service;
            _nutritionAssistantService = nutritionAssistantService;
        }

        private bool TryGetUserId(out Guid userId)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }

        /// <summary>
        /// Recommend meals/recipes based on user calorie targets.
        /// </summary>
        [HttpGet("calories")]
        public async Task<IActionResult> Calories([FromQuery] RecommendationRequest request)
        {
            TryGetUserId(out var userId);
            return Ok(await _service.RecommendByCaloriesAsync(userId, request));
        }

        /// <summary>
        /// Recommend optimal meals/recipes based on budget and cooking time.
        /// </summary>
        [HttpGet("eco")]
        public async Task<IActionResult> Eco([FromQuery] RecommendationRequest request)
        {
            TryGetUserId(out var userId);
            return Ok(await _service.RecommendByEcoAsync(userId, request));
        }

        /// <summary>
        /// Recommend quick lunch that fits calorie target and budget.
        /// </summary>
        [HttpGet("lunch")]
        public async Task<IActionResult> Lunch([FromQuery] RecommendationRequest request)
        {
            TryGetUserId(out var userId);
            return Ok(await _service.RecommendLunchAsync(userId, request));
        }

        /// <summary>
        /// Generate full-day menu from user target calories.
        /// </summary>
        [HttpGet("daily-menu")]
        public async Task<IActionResult> DailyMenu([FromQuery] RecommendationRequest request)
        {
            TryGetUserId(out var userId);
            return Ok(await _service.BuildDailyMenuAsync(userId, request));
        }

        /// <summary>
        /// Generate cooking schedule based on planned meal times and prep time.
        /// </summary>
        [HttpPost("smart-schedule")]
        public async Task<IActionResult> SmartSchedule([FromBody] SmartScheduleRequest request)
        {
            return Ok(await _service.BuildSmartScheduleAsync(request));
        }

        /// <summary>
        /// Get history of recommendations created by the current user.
        /// </summary>
        [HttpGet("history")]
        public async Task<IActionResult> History()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetHistoryAsync(userId));
        }

        /// <summary>
        /// Get details of a specific recommendation by Id.
        /// </summary>
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetByIdAsync(userId, id));
        }

        /// <summary>
        /// Xoá lịch sử recommendation không cần thiết.
        /// </summary>
        [HttpDelete("history/{id:guid}")]
        public async Task<IActionResult> DeleteHistory(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.DeleteHistoryAsync(userId, id);
                return Ok(new { Message = "Recommendation history deleted successfully." });
            }
            catch (Exception ex)
            {
                return NotFound(new { ex.Message });
            }
        }

        /// <summary>
        /// Xem trước kết quả recommendation trước khi lưu hoặc áp dụng.
        /// </summary>
        [HttpPost("preview")]
        public async Task<IActionResult> Preview([FromBody] RecommendationPreviewRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.PreviewAsync(userId, request));
        }

        /// <summary>
        /// Save user feedback for a recommendation.
        /// </summary>
        [HttpPost("feedback")]
        public async Task<IActionResult> Feedback([FromBody] RecommendationFeedbackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.SubmitFeedbackAsync(userId, request);
            return Ok(new { Message = "Feedback saved successfully." });
        }

        /// <summary>
        /// Alias theo README: user chấm chất lượng một recommendation history.
        /// </summary>
        [HttpPost("history/{id:guid}/feedback")]
        public async Task<IActionResult> FeedbackHistory(Guid id, [FromBody] RecommendationFeedbackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            request.RecommendationId = id;
            await _service.SubmitFeedbackAsync(userId, request);
            return Ok(new { Message = "Feedback saved successfully." });
        }

        /// <summary>
        /// Giải thích vì sao recommendation này được đề xuất.
        /// </summary>
        [HttpGet("explain/{id:guid}")]
        public async Task<IActionResult> Explain(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.ExplainAsync(userId, id));
        }

        /// <summary>
        /// Alias theo README: giải thích một recommendation history.
        /// </summary>
        [HttpGet("history/{id:guid}/explain")]
        public async Task<IActionResult> ExplainHistory(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.ExplainAsync(userId, id));
        }

        /// <summary>
        /// Alias theo README: giải thích vì sao item xuất hiện trong recommendation.
        /// </summary>
        [HttpGet("{id:guid}/why-this-item")]
        public async Task<IActionResult> WhyThisItem(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.ExplainAsync(userId, id));
        }

        /// <summary>
        /// Tính điểm phù hợp theo calories, macro, dị ứng và ngân sách.
        /// </summary>
        [HttpGet("scores")]
        public async Task<IActionResult> Scores([FromQuery] RecommendationScoreRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetScoresAsync(userId, request));
        }

        /// <summary>
        /// Retrain rule/model from feedback and recommendation history.
        /// </summary>
        [HttpPost("retrain")]
        public async Task<IActionResult> Retrain([FromBody] RecommendationRetrainRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.RetrainAsync(userId, request));
        }

        /// <summary>
        /// Generate general eating suggestions and save to history.
        /// </summary>
        [HttpPost("generate")]
        public async Task<IActionResult> Generate([FromBody] RecommendationGenerateRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _nutritionAssistantService.GenerateWorkerRecommendationAsync(
                userId.ToString(),
                "generate",
                new AiWorkerRecommendationRequest
                {
                    MealSlot = NormalizeMealSlot(request.MealType),
                    TargetCalories = request.TargetCalories,
                    Limit = Math.Clamp(request.MaxResults, 1, 50),
                }));
        }

        /// <summary>
        /// Sinh gợi ý an toàn qua AI worker, ưu tiên loại trừ dị ứng/preference.
        /// </summary>
        [HttpPost("generate/safe")]
        public async Task<IActionResult> GenerateSafe([FromBody] SafeRecommendationGenerateRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _nutritionAssistantService.GenerateWorkerRecommendationAsync(
                userId.ToString(),
                "safe",
                new AiWorkerRecommendationRequest
                {
                    MealSlot = NormalizeMealSlot(request.MealType),
                    TargetCalories = request.TargetCalories,
                    Limit = Math.Clamp(request.MaxResults, 1, 50),
                }));
        }

        /// <summary>
        /// Sinh thực đơn trong ngày qua AI worker.
        /// </summary>
        [HttpPost("generate/daily-menu")]
        public async Task<IActionResult> GenerateDailyMenu([FromBody] RecommendationGenerateRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _nutritionAssistantService.GenerateWorkerRecommendationAsync(
                userId.ToString(),
                "daily-menu",
                new AiWorkerRecommendationRequest
                {
                    MealSlot = NormalizeMealSlot(request.MealType),
                    TargetCalories = request.TargetCalories,
                    Limit = Math.Clamp(request.MaxResults, 1, 50),
                }));
        }

        /// <summary>
        /// Generate weekly meal plan suggestions.
        /// </summary>
        [HttpPost("generate/weekly-plan")]
        public async Task<IActionResult> GenerateWeeklyPlan([FromBody] WeeklyPlanGenerateRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _nutritionAssistantService.GenerateWorkerRecommendationAsync(
                userId.ToString(),
                "weekly-plan",
                new AiWorkerRecommendationRequest
                {
                    Date = request.StartDate == default ? null : request.StartDate.ToString("yyyy-MM-dd"),
                    TargetCalories = request.TargetCaloriesPerDay,
                    Limit = 21,
                }));
        }

        /// <summary>
        /// Generate eating suggestions based on budget constraints.
        /// </summary>
        [HttpPost("generate/budget-aware")]
        public async Task<IActionResult> GenerateBudgetAware([FromBody] BudgetAwareGenerateRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _nutritionAssistantService.GenerateWorkerRecommendationAsync(
                userId.ToString(),
                "budget-aware",
                new AiWorkerRecommendationRequest
                {
                    BudgetVnd = request.MaxBudgetPerMeal,
                    MealSlot = NormalizeMealSlot(request.MealType),
                    Limit = 5,
                }));
        }

        /// <summary>
        /// Sinh lịch gợi ý giờ ăn qua AI worker.
        /// </summary>
        [HttpPost("generate/smart-schedule")]
        public async Task<IActionResult> GenerateSmartSchedule([FromBody] SmartScheduleRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _nutritionAssistantService.GenerateWorkerRecommendationAsync(
                userId.ToString(),
                "smart-schedule",
                new AiWorkerRecommendationRequest
                {
                    Date = request.ExpectedMealTime == default
                        ? null
                        : DateOnly.FromDateTime(request.ExpectedMealTime).ToString("yyyy-MM-dd"),
                    MealSlot = InferMealSlot(request.ExpectedMealTime),
                    MaxCookTimeMin = request.CookingTimeMinutes,
                    Limit = 5,
                }));
        }

        /// <summary>
        /// Update existing user feedback for a recommendation.
        /// </summary>
        [HttpPut("feedback/{id:guid}")]
        public async Task<IActionResult> UpdateFeedback(Guid id, [FromBody] UpdateFeedbackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.UpdateFeedbackAsync(userId, id, request);
            return Ok(new { Message = "Feedback updated successfully." });
        }

        /// <summary>
        /// Aggregate feedback ratio statistics (like/dislike) by meal type.
        /// </summary>
        [HttpGet("feedback/summary")]
        public async Task<IActionResult> GetFeedbackSummary()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetFeedbackSummaryAsync(userId));
        }

        private static string? NormalizeMealSlot(string? mealType)
        {
            if (string.IsNullOrWhiteSpace(mealType))
            {
                return null;
            }

            var normalized = mealType.Trim().ToLowerInvariant();
            if (normalized is "breakfast" or "lunch" or "dinner" or "snack" or "any")
            {
                return normalized;
            }

            if (normalized.Contains("sáng") || normalized.Contains("sang") || normalized.Contains("break"))
            {
                return "breakfast";
            }

            if (normalized.Contains("trưa") || normalized.Contains("trua") || normalized.Contains("lunch"))
            {
                return "lunch";
            }

            if (normalized.Contains("tối") || normalized.Contains("toi") || normalized.Contains("dinner"))
            {
                return "dinner";
            }

            if (normalized.Contains("snack") || normalized.Contains("phụ") || normalized.Contains("phu"))
            {
                return "snack";
            }

            return "any";
        }

        private static string InferMealSlot(DateTime expectedMealTime)
        {
            var hour = expectedMealTime.Hour;
            if (hour < 10)
            {
                return "breakfast";
            }

            if (hour < 15)
            {
                return "lunch";
            }

            if (hour < 17)
            {
                return "snack";
            }

            return "dinner";
        }
    }
}
