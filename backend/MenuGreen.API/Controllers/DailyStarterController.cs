using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Controller for new user daily starter (1-tap) quick start support.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "CasualOnly")]
    public class DailyStarterController : ControllerBase
    {
        private readonly IDailyStarterService _service;
        private readonly IRecommendationService _recommendationService;

        public DailyStarterController(IDailyStarterService service, IRecommendationService recommendationService)
        {
            _service = service;
            _recommendationService = recommendationService;
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }

        /// <summary>
        /// Get daily starter summary for user (dynamic quote, banner, target calories, onboarding status).
        /// </summary>
        [HttpGet("today")]
        public async Task<IActionResult> GetTodayStarter()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetTodayStarterAsync(userId));
        }
        /// <summary>
        /// Get list of featured foods (popular, healthy) for quick start.
        /// </summary>
        [HttpGet("featured-meals")]
        public async Task<IActionResult> GetFeaturedMeals()
        {
            return Ok(await _service.GetFeaturedMealsAsync());
        }

        /// <summary>
        /// Quickly select a menu template to apply directly to today's meal plan.
        /// </summary>
        [HttpPost("select-meal")]
        public async Task<IActionResult> SelectMeal([FromBody] DailyStarterSelectMealRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            
            await _service.SelectMealPlanAsync(userId, request);
            return Ok(new { Message = "Menu template applied to today's plan successfully." });
        }

        /// <summary>
        /// Start quick meal logging. Returns meal suggestions based on current system time.
        /// </summary>
        [HttpPost("start-log")]
        public async Task<IActionResult> StartLog()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.StartLogFlowAsync(userId));
        }

        /// <summary>
        /// Get combined user personalization info (health metrics, AI preferences, allergies).
        /// </summary>
        [HttpGet("personalization")]
        public async Task<IActionResult> GetPersonalization()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetPersonalizationAsync(userId));
        }

        /// <summary>
        /// Update user personalization metrics simultaneously (HealthProfile, AI Profile, Allergy).
        /// </summary>
        [HttpPut("personalization")]
        public async Task<IActionResult> UpdatePersonalization([FromBody] DailyStarterPersonalizationUpdateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdatePersonalizationAsync(userId, request));
        }

        /// <summary>
        /// Lấy thực đơn gợi ý cho user mới dựa vào calorie mục tiêu.
        /// </summary>
        [HttpGet("recommendations")]
        public async Task<IActionResult> GetRecommendations([FromQuery] RecommendationRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetRecommendationsAsync(userId, request));
        }

        /// <summary>
        /// Lưu sở thích ăn uống ban đầu của user.
        /// </summary>
        [HttpPost("save-preference")]
        public async Task<IActionResult> SavePreference([FromBody] UpdateUserAiProfileRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.SavePreferenceAsync(userId, request));
        }
    }
}
