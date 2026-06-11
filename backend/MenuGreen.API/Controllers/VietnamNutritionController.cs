using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Vietnam-first nutrition endpoints.
    /// Most features reuse existing profile, food search, meal log, and recommendation flows to avoid duplication.
    /// </summary>
    [ApiController]
    [Route("api/Nutrition")]
    [Authorize(Policy = "UserOnly")]
    public class VietnamNutritionController : ControllerBase
    {
        private readonly IUserAiProfileService _aiProfileService;
        private readonly IFoodService _foodService;
        private readonly INutritionTrackingService _nutritionTrackingService;
        private readonly IRecommendationService _recommendationService;

        public VietnamNutritionController(
            IUserAiProfileService aiProfileService,
            IFoodService foodService,
            INutritionTrackingService nutritionTrackingService,
            IRecommendationService recommendationService)
        {
            _aiProfileService = aiProfileService;
            _foodService = foodService;
            _nutritionTrackingService = nutritionTrackingService;
            _recommendationService = recommendationService;
        }

        [HttpGet("local-preferences")]
        public async Task<IActionResult> GetLocalPreferences()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _aiProfileService.GetAsync(userId));
        }

        [HttpPost("local-preferences")]
        [HttpPut("local-preferences")]
        public async Task<IActionResult> UpsertLocalPreferences([FromBody] UpdateUserAiProfileRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _aiProfileService.UpsertAsync(userId, request));
        }

        [HttpGet("discovery/local")]
        public async Task<IActionResult> DiscoveryLocal([FromQuery] string? keyword, [FromQuery] int? maxPriceVnd)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _foodService.SearchAsync(keyword, null, null, null, maxPriceVnd, null, null, userId, null));
        }

        [HttpGet("discovery/local/by-region/{region}")]
        public async Task<IActionResult> DiscoveryByRegion(string region)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _foodService.SearchAsync(region, null, null, null, null, null, null, userId, null));
        }

        [HttpGet("discovery/local/by-budget")]
        public async Task<IActionResult> DiscoveryByBudget([FromQuery] int maxPrice)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _foodService.SearchAsync(null, null, null, null, maxPrice, null, null, userId, null));
        }

        [HttpGet("portions/local-units")]
        public IActionResult LocalUnits()
        {
            return Ok(new[] { "chén", "bát", "muỗng", "đĩa", "ly", "cốc" });
        }

        [HttpPost("portions/convert")]
        public IActionResult ConvertPortion([FromBody] PortionConvertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var grams = request.Unit.ToLowerInvariant() switch
            {
                "chén" => request.Amount * 150m,
                "bát" => request.Amount * 200m,
                "muỗng" => request.Amount * 15m,
                "đĩa" => request.Amount * 250m,
                "ly" => request.Amount * 250m,
                "cốc" => request.Amount * 240m,
                _ => request.Amount
            };

            return Ok(new { request.Amount, request.Unit, Grams = grams });
        }

        [HttpGet("portions/estimate")]
        public async Task<IActionResult> EstimatePortion([FromQuery] Guid foodId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var food = await _foodService.GetByIdAsync(foodId, userId, null);
            return Ok(new { foodId, food.DefaultServingG, SuggestedUnit = "chén" });
        }

        [HttpPost("meal-log/vn")]
        [HttpPost("meal-log/vn/quick-add")]
        public async Task<IActionResult> QuickAddMealLog([FromBody] MealLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _nutritionTrackingService.CreateMealLogAsync(userId, request));
        }

        [HttpGet("meal-log/vn/suggestions")]
        public async Task<IActionResult> MealLogSuggestions([FromQuery] string? keyword, [FromQuery] int? maxPriceVnd)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _foodService.SearchAsync(keyword, null, null, null, maxPriceVnd, null, null, userId, null));
        }

        [HttpGet("meal-log/vn/history")]
        public async Task<IActionResult> MealLogHistory([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _nutritionTrackingService.GetMealLogsAsync(userId, page, pageSize));
        }

        [HttpGet("recommendations/budget-aware")]
        [HttpGet("recommendations/local-friendly")]
        public async Task<IActionResult> Recommendations([FromQuery] RecommendationRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _recommendationService.RecommendByEcoAsync(userId, request));
        }

        [HttpPost("recommendations/feedback")]
        public async Task<IActionResult> RecommendationFeedback([FromBody] RecommendationFeedbackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _recommendationService.SubmitFeedbackAsync(userId, request);
            return Ok(new { Message = "Feedback saved successfully." });
        }

        private bool TryGetUserId(out Guid userId)
        {
            var raw = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(raw, out userId);
        }
    }

    public class PortionConvertRequest
    {
        public decimal Amount { get; set; }
        public string Unit { get; set; } = string.Empty;
    }
}
