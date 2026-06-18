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
    /// <summary>
    /// Controller quản lý Analytics - Audit và Product analytics.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "AdminOnly")]
    public class AnalyticsController : ControllerBase
    {
        private readonly IAnalyticsService _service;

        public AnalyticsController(IAnalyticsService service)
        {
            _service = service;
        }

        /// <summary>
        /// Ghi nhận một sự kiện quan trọng.
        /// </summary>
        [HttpPost("activity-log")]
        public async Task<IActionResult> CreateActivityLog([FromBody] ActivityLogCreateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateActivityLogAsync(userId, request));
        }

        /// <summary>
        /// Ghi nhận nhiều sự kiện cùng lúc.
        /// </summary>
        [HttpPost("activity-log/bulk")]
        public async Task<IActionResult> CreateActivityLogs([FromBody] ActivityLogBulkCreateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateActivityLogsAsync(userId, request.Items));
        }

        /// <summary>
        /// Lấy danh sách sự kiện theo user hoặc thời gian.
        /// </summary>
        [HttpGet("activity-log")]
        public async Task<IActionResult> GetActivityLogs([FromQuery] Guid? userId = null, [FromQuery] DateTimeOffset? from = null, [FromQuery] DateTimeOffset? to = null, [FromQuery] string? action = null)
        {
            return Ok(await _service.GetActivityLogsAsync(userId, from, to, action));
        }

        /// <summary>
        /// Xem chi tiết một sự kiện.
        /// </summary>
        [HttpGet("activity-log/{id:guid}")]
        public async Task<IActionResult> GetActivityLogById(Guid id)
        {
            return Ok(await _service.GetActivityLogByIdAsync(id));
        }

        /// <summary>
        /// Tổng hợp KPI chính.
        /// </summary>
        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboard()
        {
            return Ok(await _service.GetDashboardAsync());
        }

        /// <summary>
        /// Báo cáo tổng hợp theo khoảng thời gian.
        /// </summary>
        [HttpGet("summary")]
        public async Task<IActionResult> GetSummary([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetSummaryAsync(from, to));
        }

        /// <summary>
        /// Trả về KPI chi tiết theo ngày / tuần / tháng.
        /// </summary>
        [HttpGet("metrics")]
        public async Task<IActionResult> GetMetrics([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetMetricsAsync(from, to));
        }

        /// <summary>
        /// Danh sách event được ghi nhận nhiều nhất.
        /// </summary>
        [HttpGet("top-events")]
        public async Task<IActionResult> GetTopEvents([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetTopEventsAsync(from, to));
        }

        /// <summary>
        /// Tổng hợp funnel theo một flow định nghĩa sẵn.
        /// </summary>
        [HttpGet("funnel")]
        public async Task<IActionResult> GetFunnel()
        {
            return Ok(await _service.GetFunnelAsync());
        }

        /// <summary>
        /// Xem trước funnel theo các step truyền vào.
        /// </summary>
        [HttpPost("funnel/preview")]
        public async Task<IActionResult> PreviewFunnel([FromBody] string[] steps)
        {
            return Ok(await _service.PreviewFunnelAsync(steps ?? Array.Empty<string>()));
        }

        /// <summary>
        /// Funnel mặc định cho onboarding → log bữa đầu tiên.
        /// </summary>
        [HttpGet("funnel/meal-onboarding")]
        public async Task<IActionResult> GetMealOnboardingFunnel()
        {
            return Ok(await _service.GetMealOnboardingFunnelAsync());
        }

        /// <summary>
        /// Funnel mặc định cho đăng ký → mua subscription.
        /// </summary>
        [HttpGet("funnel/subscription")]
        public async Task<IActionResult> GetSubscriptionFunnel()
        {
            return Ok(await _service.GetSubscriptionFunnelAsync());
        }

        /// <summary>
        /// Lấy dữ liệu cohort tổng quát.
        /// </summary>
        [HttpGet("cohort")]
        public async Task<IActionResult> GetCohort()
        {
            return Ok(await _service.GetCohortAsync());
        }

        /// <summary>
        /// Đo retention theo D1 / D7 / D30.
        /// </summary>
        [HttpGet("cohort/retention")]
        public async Task<IActionResult> GetRetention()
        {
            return Ok(await _service.GetRetentionAsync());
        }

        /// <summary>
        /// Cohort theo ngày đăng ký.
        /// </summary>
        [HttpGet("cohort/by-signup-date")]
        public async Task<IActionResult> GetCohortBySignupDate()
        {
            return Ok(await _service.GetCohortBySignupDateAsync());
        }

        /// <summary>
        /// Cohort theo ngày log bữa đầu tiên.
        /// </summary>
        [HttpGet("cohort/by-first-meal-log")]
        public async Task<IActionResult> GetCohortByFirstMealLog()
        {
            return Ok(await _service.GetCohortByFirstMealLogAsync());
        }

        /// <summary>
        /// Cohort theo trạng thái subscription.
        /// </summary>
        [HttpGet("cohort/by-subscription")]
        public async Task<IActionResult> GetCohortBySubscription()
        {
            return Ok(await _service.GetCohortBySubscriptionAsync());
        }

        /// <summary>
        /// Phân tích các bước có rớt user nhiều nhất.
        /// </summary>
        [HttpGet("drop-off")]
        public async Task<IActionResult> GetDropOff()
        {
            return Ok(await _service.GetDropOffAsync());
        }

        /// <summary>
        /// Phân nhóm user có nguy cơ rời bỏ.
        /// </summary>
        [HttpGet("churn-risk")]
        public async Task<IActionResult> GetChurnRisk()
        {
            return Ok(await _service.GetChurnRiskAsync());
        }

        /// <summary>
        /// Danh sách user không hoạt động trong khoảng thời gian xác định.
        /// </summary>
        [HttpGet("inactive-users")]
        public async Task<IActionResult> GetInactiveUsers()
        {
            return Ok(await _service.GetInactiveUsersAsync());
        }

        /// <summary>
        /// Danh sách user có thể nhắc quay lại.
        /// </summary>
        [HttpGet("reactivation-opportunities")]
        public async Task<IActionResult> GetReactivationOpportunities()
        {
            return Ok(await _service.GetReactivationOpportunitiesAsync());
        }

        /// <summary>
        /// Xuất activity log ra file hoặc CSV.
        /// </summary>
        [HttpGet("export/activity-log")]
        public async Task<IActionResult> ExportActivityLog([FromQuery] DateTimeOffset? from = null, [FromQuery] DateTimeOffset? to = null)
        {
            return Ok(await _service.ExportActivityLogsAsync(from, to));
        }

        /// <summary>
        /// Xuất dữ liệu funnel.
        /// </summary>
        [HttpGet("export/funnel")]
        public async Task<IActionResult> ExportFunnel()
        {
            return Ok(await _service.ExportFunnelAsync());
        }

        /// <summary>
        /// Xuất dữ liệu cohort.
        /// </summary>
        [HttpGet("export/cohort")]
        public async Task<IActionResult> ExportCohort()
        {
            return Ok(await _service.ExportCohortAsync());
        }

        #region Nutrition Analytics

        /// <summary>
        /// Tổng hợp nutrition dashboard với all key metrics.
        /// </summary>
        [HttpGet("nutrition/dashboard")]
        public async Task<IActionResult> GetNutritionDashboard([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetNutritionDashboardAsync(from, to));
        }

        /// <summary>
        /// Phân tích phân bổ macro (Protein/Carbs/Fat).
        /// </summary>
        [HttpGet("nutrition/macro-distribution")]
        public async Task<IActionResult> GetMacroDistribution([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetMacroDistributionAsync(from, to));
        }

        /// <summary>
        /// Tỷ lệ users đạt được daily goals.
        /// </summary>
        [HttpGet("nutrition/goal-achievement")]
        public async Task<IActionResult> GetGoalAchievement([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetGoalAchievementAsync(from, to));
        }

        /// <summary>
        /// Top foods được log nhiều nhất.
        /// </summary>
        [HttpGet("nutrition/top-foods")]
        public async Task<IActionResult> GetTopFoods([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to, [FromQuery] int limit = 10, [FromQuery] string sortBy = "count")
        {
            return Ok(await _service.GetTopFoodsAsync(from, to, limit, sortBy));
        }

        /// <summary>
        /// Phân bổ calorie (Below/On/Above target).
        /// </summary>
        [HttpGet("nutrition/calorie-distribution")]
        public async Task<IActionResult> GetCalorieDistribution([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetCalorieDistributionAsync(from, to));
        }

        /// <summary>
        /// Phân bổ theo meal type (Breakfast/Lunch/Dinner/Snack).
        /// </summary>
        [HttpGet("nutrition/meal-type-breakdown")]
        public async Task<IActionResult> GetMealTypeBreakdown([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetMealTypeBreakdownAsync(from, to));
        }

        /// <summary>
        /// User engagement và diet quality insights.
        /// </summary>
        [HttpGet("nutrition/user-insights")]
        public async Task<IActionResult> GetUserInsights([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetUserInsightsAsync(from, to));
        }

        #endregion

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
