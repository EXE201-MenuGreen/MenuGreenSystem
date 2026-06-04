using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>Controller User Dashboard - Dashboard cá nhân của user.</summary>
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

        /// <summary>Lấy tổng hợp thông tin cá nhân của user cho dashboard.</summary>
        [HttpGet("user-summary")]
        public async Task<IActionResult> GetUserSummary()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _userDashboardService.GetUserSummaryAsync(userId));
        }

        /// <summary>Lấy xu hướng dinh dưỡng trong khoảng thời gian (cho biểu đồ).</summary>
        [HttpGet("nutrition-trend")]
        public async Task<IActionResult> GetNutritionTrend([FromQuery] DateOnly startDate, [FromQuery] DateOnly endDate)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _userDashboardService.GetNutritionTrendAsync(userId, startDate, endDate));
        }

        /// <summary>Lấy xu hướng cân nặng trong khoảng thời gian (cho biểu đồ).</summary>
        [HttpGet("weight-trend")]
        public async Task<IActionResult> GetWeightTrend([FromQuery] DateOnly startDate, [FromQuery] DateOnly endDate)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _userDashboardService.GetWeightTrendAsync(userId, startDate, endDate));
        }

        /// <summary>Lấy tóm tắt các recommendation gần đây.</summary>
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
