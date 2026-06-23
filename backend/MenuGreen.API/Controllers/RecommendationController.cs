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

        public RecommendationController(IRecommendationService service)
        {
            _service = service;
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
        /// Preview recommendation results before saving or applying.
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
        /// Explain why this recommendation was suggested.
        /// </summary>
        [HttpGet("explain/{id:guid}")]
        public async Task<IActionResult> Explain(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.ExplainAsync(userId, id));
        }

        /// <summary>
        /// Calculate suitability scores based on calories, macros, allergies, and budget.
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
            return Ok(await _service.GenerateAsync(userId, request));
        }

        /// <summary>
        /// Generate weekly meal plan suggestions.
        /// </summary>
        [HttpPost("generate/weekly-plan")]
        public async Task<IActionResult> GenerateWeeklyPlan([FromBody] WeeklyPlanGenerateRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GenerateWeeklyPlanAsync(userId, request));
        }

        /// <summary>
        /// Generate eating suggestions based on budget constraints.
        /// </summary>
        [HttpPost("generate/budget-aware")]
        public async Task<IActionResult> GenerateBudgetAware([FromBody] BudgetAwareGenerateRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GenerateBudgetAwareAsync(userId, request));
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
    }
}
