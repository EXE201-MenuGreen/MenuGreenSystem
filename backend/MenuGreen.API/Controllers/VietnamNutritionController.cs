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

        [HttpGet("meal-log/vn/suggestions")]
        public async Task<IActionResult> MealLogSuggestions([FromQuery] string? keyword, [FromQuery] int? maxPriceVnd)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _foodService.SearchAsync(keyword, null, null, null, maxPriceVnd, null, null, userId, null));
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


}
