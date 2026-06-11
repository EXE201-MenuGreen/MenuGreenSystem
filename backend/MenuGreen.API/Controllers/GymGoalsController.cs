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
    /// Gym/PT goal workflow controller.
    /// Reuses existing recommendation and tracking APIs instead of duplicating them.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class GymGoalsController : ControllerBase
    {
        private readonly IUserAiProfileService _userAiProfileService;
        private readonly IRecommendationService _recommendationService;
        private readonly INutritionTrackingService _nutritionTrackingService;
        private readonly IMealPlanService _mealPlanService;
        private readonly IUserMealPlanService _userMealPlanService;

        public GymGoalsController(
            IUserAiProfileService userAiProfileService,
            IRecommendationService recommendationService,
            INutritionTrackingService nutritionTrackingService,
            IMealPlanService mealPlanService,
            IUserMealPlanService userMealPlanService)
        {
            _userAiProfileService = userAiProfileService;
            _recommendationService = recommendationService;
            _nutritionTrackingService = nutritionTrackingService;
            _mealPlanService = mealPlanService;
            _userMealPlanService = userMealPlanService;
        }

        /// <summary>
        /// Lấy cấu hình Gym/PT goal hiện tại của user.
        /// </summary>
        [HttpGet("me")]
        public async Task<IActionResult> GetMe()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _userAiProfileService.GetAsync(userId));
        }

        /// <summary>
        /// Tạo hoặc cập nhật cấu hình goal mode, lịch tập và target ban đầu cho user.
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateOrUpdate([FromBody] GymGoalUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var profile = await _userAiProfileService.GetAsync(userId);
            profile.EatingPattern = request.GoalMode;
            profile.Preferences = $"{{\"goalMode\":\"{request.GoalMode}\",\"weeklyTrainingSchedule\":\"{request.WeeklyTrainingSchedule}\",\"trainingDaysPerWeek\":{request.TrainingDaysPerWeek?.ToString() ?? "null"},\"restDaysPerWeek\":{request.RestDaysPerWeek?.ToString() ?? "null"}}}";
            return Ok(await _userAiProfileService.UpsertAsync(userId, new UpdateUserAiProfileRequest
            {
                Preferences = profile.Preferences,
                EatingPattern = request.GoalMode,
                DislikedFoods = profile.DislikedFoods,
                AllergiesAcknowledged = profile.AllergiesAcknowledged
            }));
        }

        /// <summary>
        /// Cập nhật lại goal mode và lịch tập hiện tại của user.
        /// </summary>
        [HttpPut]
        public async Task<IActionResult> Update([FromBody] GymGoalUpsertRequest request)
        {
            return await CreateOrUpdate(request);
        }

        /// <summary>
        /// Lấy kế hoạch dinh dưỡng gợi ý theo goal mode và target calories.
        /// </summary>
        [HttpGet("plan")]
        public async Task<IActionResult> GetPlan([FromQuery] int targetCalories = 0, [FromQuery] int top = 10)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _recommendationService.RecommendByCaloriesAsync(userId, new RecommendationRequest
            {
                TargetCalories = targetCalories > 0 ? targetCalories : null,
                Top = top
            }));
        }

        /// <summary>
        /// Thu thập dữ liệu tracking để tái cân chỉnh target calories/macro theo tuần.
        /// </summary>
        [HttpPost("recalibrate")]
        public async Task<IActionResult> Recalibrate([FromBody] GymGoalRecalibrateRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var summary = await _nutritionTrackingService.GetNutritionSummaryAsync(userId, request.Period ?? "week", request.Date);
            var dashboard = await _nutritionTrackingService.GetDashboardAsync(userId, request.Range ?? "week", request.StartDate, request.EndDate);
            var weightTrend = await _nutritionTrackingService.GetWeightTrendAsync(userId, request.StartDate ?? DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-7)), request.EndDate ?? DateOnly.FromDateTime(DateTime.UtcNow));

            return Ok(new
            {
                Message = "Recalibration data collected successfully.",
                Summary = summary,
                Dashboard = dashboard,
                WeightTrend = weightTrend
            });
        }

        /// <summary>
        /// Tạo cảnh báo lệch mục tiêu dựa trên dữ liệu meal plan compare và tracking.
        /// </summary>
        [HttpGet("alerts")]
        public async Task<IActionResult> GetAlerts([FromQuery] DateOnly? startDate = null, [FromQuery] DateOnly? endDate = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var compare = await _mealPlanService.GetCompareAsync(startDate ?? DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-7)), endDate ?? DateOnly.FromDateTime(DateTime.UtcNow), userId);
            return Ok(new
            {
                Message = "Alerts are derived from meal plan compare and tracking data.",
                Compare = compare
            });
        }

        /// <summary>
        /// Tạo báo cáo nâng cao để PT/coach review, tổng hợp từ meal plan và tracking hiện có.
        /// </summary>
        [HttpGet("coach-report")]
        public async Task<IActionResult> CoachReport([FromQuery] DateOnly date)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var dashboard = await _mealPlanService.GetDashboardAsync(date, userId);
            var adherence = await _userMealPlanService.GetAdherenceAsync(userId, date);
            var tracking = await _nutritionTrackingService.GetDailySummaryAsync(userId, date);

            return Ok(new
            {
                Dashboard = dashboard,
                Adherence = adherence,
                Tracking = tracking,
                Note = "This report reuses existing meal plan and tracking APIs; no duplicate coach-report storage is created."
            });
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }

    public class GymGoalRecalibrateRequest
    {
        public string? Period { get; set; }
        public string? Range { get; set; }
        public DateOnly? Date { get; set; }
        public DateOnly? StartDate { get; set; }
        public DateOnly? EndDate { get; set; }
    }
}
