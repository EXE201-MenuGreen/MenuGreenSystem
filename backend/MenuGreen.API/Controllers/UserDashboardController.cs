using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>User Dashboard - Personal user dashboard.</summary>
    [ApiController]
    [Route("api/Dashboard")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class UserDashboardController : ControllerBase
    {
        private readonly IUserDashboardService _userDashboardService;

        public UserDashboardController(IUserDashboardService userDashboardService)
        {
            _userDashboardService = userDashboardService;
        }

        /// <summary>Get aggregated user personal information for dashboard.</summary>
        [HttpGet("user-summary")]
        public async Task<IActionResult> GetUserSummary()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _userDashboardService.GetUserSummaryAsync(userId));
        }

        /// <summary>Get nutrition trend over time period (for charts).</summary>
        [HttpGet("nutrition-trend")]
        public async Task<IActionResult> GetNutritionTrend([FromQuery] DateOnly startDate, [FromQuery] DateOnly endDate)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _userDashboardService.GetNutritionTrendAsync(userId, startDate, endDate));
        }

        /// <summary>Get weight trend over time period (for charts).</summary>
        [HttpGet("weight-trend")]
        public async Task<IActionResult> GetWeightTrend([FromQuery] DateOnly startDate, [FromQuery] DateOnly endDate)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _userDashboardService.GetWeightTrendAsync(userId, startDate, endDate));
        }

        /// <summary>Get summary of recent recommendations.</summary>
        [HttpGet("recommendation-summary")]
        public async Task<IActionResult> GetRecommendationSummary([FromQuery] int topCount = 5)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _userDashboardService.GetRecommendationSummaryAsync(userId, topCount));
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
