using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "AdminOnly")]
    public class DashboardController : ControllerBase
    {
        private readonly IDashboardService _dashboardService;
        private readonly IUserMetricsService _userMetricsService;
        private readonly IRevenueMetricsService _revenueMetricsService;
        private readonly IFoodRankingService _foodRankingService;

        public DashboardController(
            IDashboardService dashboardService,
            IUserMetricsService userMetricsService,
            IRevenueMetricsService revenueMetricsService,
            IFoodRankingService foodRankingService)
        {
            _dashboardService = dashboardService;
            _userMetricsService = userMetricsService;
            _revenueMetricsService = revenueMetricsService;
            _foodRankingService = foodRankingService;
        }

        // Lấy toàn bộ chỉ số tổng quan hệ thống để admin theo dõi tăng trưởng.
        [HttpGet("metrics")]
        public async Task<IActionResult> GetMetrics([FromQuery] int topCount = 10)
        {
            return Ok(await _dashboardService.GetMetricsAsync(topCount));
        }

        // Lấy nhóm chỉ số về user: tổng user, active users, premium users, pro users.
        [HttpGet("users")]
        public async Task<IActionResult> GetUserMetrics()
        {
            return Ok(await _userMetricsService.GetSummaryAsync());
        }

        // Lấy nhóm chỉ số doanh thu tài chính của hệ thống.
        [HttpGet("revenue")]
        public async Task<IActionResult> GetRevenueMetrics()
        {
            return Ok(await _revenueMetricsService.GetSummaryAsync());
        }

        // Lấy bảng xếp hạng món ăn được dùng phổ biến nhất.
        [HttpGet("foods/top")]
        public async Task<IActionResult> GetTopFoods([FromQuery] int topCount = 10)
        {
            return Ok(await _foodRankingService.GetTopFoodsAsync(topCount));
        }
    }
}
