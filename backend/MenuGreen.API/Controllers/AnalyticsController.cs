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
    /// Controller for Analytics - Audit and Product analytics.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AnalyticsController : ControllerBase
    {
        private readonly IAnalyticsService _service;

        public AnalyticsController(IAnalyticsService service)
        {
            _service = service;
        }

        /// <summary>
        /// Record an important event.
        /// </summary>
        [HttpPost("activity-log")]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> CreateActivityLog([FromBody] ActivityLogCreateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateActivityLogAsync(userId, request));
        }

        /// <summary>
        /// Record multiple events at once.
        /// </summary>
        [HttpPost("activity-log/bulk")]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> CreateActivityLogs([FromBody] ActivityLogBulkCreateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateActivityLogsAsync(userId, request.Items));
        }

        /// <summary>
        /// Get events by user or time.
        /// </summary>
        [HttpGet("activity-log")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetActivityLogs([FromQuery] Guid? userId = null, [FromQuery] DateTimeOffset? from = null, [FromQuery] DateTimeOffset? to = null, [FromQuery] string? action = null)
        {
            return Ok(await _service.GetActivityLogsAsync(userId, from, to, action));
        }

        /// <summary>
        /// Get events by user or time with pagination.
        /// </summary>
        [HttpGet("activity-log/paginated")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetActivityLogsPaginated(
            [FromQuery] Guid? userId = null,
            [FromQuery] DateTimeOffset? from = null,
            [FromQuery] DateTimeOffset? to = null,
            [FromQuery] string? action = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 50)
        {
            return Ok(await _service.GetActivityLogsPaginatedAsync(userId, from, to, action, page, pageSize));
        }

        /// <summary>
        /// View event details.
        /// </summary>
        [HttpGet("activity-log/{id:guid}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetActivityLogById(Guid id)
        {
            return Ok(await _service.GetActivityLogByIdAsync(id));
        }

        /// <summary>
        /// Aggregate main KPIs.
        /// </summary>
        [HttpGet("dashboard")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetDashboard()
        {
            return Ok(await _service.GetDashboardAsync());
        }

        /// <summary>
        /// Summary report for a time period.
        /// </summary>
        [HttpGet("summary")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetSummary([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetSummaryAsync(from, to));
        }

        /// <summary>
        /// Return detailed KPIs by day/week/month.
        /// </summary>
        [HttpGet("metrics")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetMetrics([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetMetricsAsync(from, to));
        }

        /// <summary>
        /// Most frequently recorded events.
        /// </summary>
        [HttpGet("top-events")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetTopEvents([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetTopEventsAsync(from, to));
        }

        /// <summary>
        /// Aggregate funnel by predefined flow.
        /// </summary>
        [HttpGet("funnel")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetFunnel()
        {
            return Ok(await _service.GetFunnelAsync());
        }

        /// <summary>
        /// Preview funnel by input steps.
        /// </summary>
        [HttpPost("funnel/preview")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> PreviewFunnel([FromBody] string[] steps)
        {
            return Ok(await _service.PreviewFunnelAsync(steps ?? Array.Empty<string>()));
        }

        /// <summary>
        /// Default funnel for onboarding to logging first meal.
        /// </summary>
        [HttpGet("funnel/meal-onboarding")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetMealOnboardingFunnel()
        {
            return Ok(await _service.GetMealOnboardingFunnelAsync());
        }

        /// <summary>
        /// Default funnel for registration to subscription purchase.
        /// </summary>
        [HttpGet("funnel/subscription")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetSubscriptionFunnel()
        {
            return Ok(await _service.GetSubscriptionFunnelAsync());
        }

        /// <summary>
        /// Get general cohort data.
        /// </summary>
        [HttpGet("cohort")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetCohort()
        {
            return Ok(await _service.GetCohortAsync());
        }

        /// <summary>
        /// Measure retention by D1/D7/D30.
        /// </summary>
        [HttpGet("cohort/retention")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetRetention()
        {
            return Ok(await _service.GetRetentionAsync());
        }

        /// <summary>
        /// Cohort by signup date.
        /// </summary>
        [HttpGet("cohort/by-signup-date")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetCohortBySignupDate()
        {
            return Ok(await _service.GetCohortBySignupDateAsync());
        }

        /// <summary>
        /// Cohort by first meal log date.
        /// </summary>
        [HttpGet("cohort/by-first-meal-log")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetCohortByFirstMealLog()
        {
            return Ok(await _service.GetCohortByFirstMealLogAsync());
        }

        /// <summary>
        /// Cohort by subscription status.
        /// </summary>
        [HttpGet("cohort/by-subscription")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetCohortBySubscription()
        {
            return Ok(await _service.GetCohortBySubscriptionAsync());
        }

        /// <summary>
        /// Analyze steps with highest user drop-off.
        /// </summary>
        [HttpGet("drop-off")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetDropOff()
        {
            return Ok(await _service.GetDropOffAsync());
        }

        /// <summary>
        /// Segment users at churn risk.
        /// </summary>
        [HttpGet("churn-risk")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetChurnRisk()
        {
            return Ok(await _service.GetChurnRiskAsync());
        }

        /// <summary>
        /// List inactive users in specified time period.
        /// </summary>
        [HttpGet("inactive-users")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetInactiveUsers()
        {
            return Ok(await _service.GetInactiveUsersAsync());
        }

        /// <summary>
        /// List users eligible for re-engagement reminders.
        /// </summary>
        [HttpGet("reactivation-opportunities")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetReactivationOpportunities()
        {
            return Ok(await _service.GetReactivationOpportunitiesAsync());
        }

        /// <summary>
        /// Export activity log to file or CSV.
        /// </summary>
        [HttpGet("export/activity-log")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> ExportActivityLog([FromQuery] DateTimeOffset? from = null, [FromQuery] DateTimeOffset? to = null)
        {
            return Ok(await _service.ExportActivityLogsAsync(from, to));
        }

        /// <summary>
        /// Export funnel data.
        /// </summary>
        [HttpGet("export/funnel")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> ExportFunnel()
        {
            return Ok(await _service.ExportFunnelAsync());
        }

        /// <summary>
        /// Export cohort data.
        /// </summary>
        [HttpGet("export/cohort")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> ExportCohort()
        {
            return Ok(await _service.ExportCohortAsync());
        }

        #region Nutrition Analytics

        /// <summary>
        /// Aggregate nutrition dashboard with all key metrics.
        /// </summary>
        [HttpGet("nutrition/dashboard")]
        public async Task<IActionResult> GetNutritionDashboard([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetNutritionDashboardAsync(from, to));
        }

        /// <summary>
        /// Analyze macro distribution (Protein/Carbs/Fat).
        /// </summary>
        [HttpGet("nutrition/macro-distribution")]
        public async Task<IActionResult> GetMacroDistribution([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetMacroDistributionAsync(from, to));
        }

        /// <summary>
        /// Ratio of users achieving daily goals.
        /// </summary>
        [HttpGet("nutrition/goal-achievement")]
        public async Task<IActionResult> GetGoalAchievement([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetGoalAchievementAsync(from, to));
        }

        /// <summary>
        /// Top foods most frequently logged.
        /// </summary>
        [HttpGet("nutrition/top-foods")]
        public async Task<IActionResult> GetTopFoods([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to, [FromQuery] int limit = 10, [FromQuery] string sortBy = "count")
        {
            return Ok(await _service.GetTopFoodsAsync(from, to, limit, sortBy));
        }

        /// <summary>
        /// Calorie distribution (Below/On/Above target).
        /// </summary>
        [HttpGet("nutrition/calorie-distribution")]
        public async Task<IActionResult> GetCalorieDistribution([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetCalorieDistributionAsync(from, to));
        }

        /// <summary>
        /// Distribution by meal type (Breakfast/Lunch/Dinner/Snack).
        /// </summary>
        [HttpGet("nutrition/meal-type-breakdown")]
        public async Task<IActionResult> GetMealTypeBreakdown([FromQuery] DateTimeOffset from, [FromQuery] DateTimeOffset to)
        {
            return Ok(await _service.GetMealTypeBreakdownAsync(from, to));
        }

        /// <summary>
        /// User engagement and diet quality insights.
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
