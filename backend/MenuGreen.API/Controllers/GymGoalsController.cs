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
        private readonly IHealthProfileService _healthProfileService;

        public GymGoalsController(
            IUserAiProfileService userAiProfileService,
            IRecommendationService recommendationService,
            INutritionTrackingService nutritionTrackingService,
            IMealPlanService mealPlanService,
            IHealthProfileService healthProfileService)
        {
            _userAiProfileService = userAiProfileService;
            _recommendationService = recommendationService;
            _nutritionTrackingService = nutritionTrackingService;
            _mealPlanService = mealPlanService;
            _healthProfileService = healthProfileService;
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
            
            // Serialize toàn bộ request thành preferences để lưu đầy đủ và an toàn
            var preferencesData = new
            {
                goalMode = request.GoalMode,
                weeklyTrainingSchedule = request.WeeklyTrainingSchedule,
                trainingDaysPerWeek = request.TrainingDaysPerWeek,
                restDaysPerWeek = request.RestDaysPerWeek,
                trainingDayTargetCalories = request.TrainingDayTargetCalories,
                restDayTargetCalories = request.RestDayTargetCalories,
                minCalories = request.MinCalories,
                maxCalories = request.MaxCalories,
                minProteinG = request.MinProteinG,
                maxProteinG = request.MaxProteinG,
                notes = request.Notes
            };

            var preferencesJson = System.Text.Json.JsonSerializer.Serialize(preferencesData);

            // Đồng thời đồng bộ cập nhật TargetCalories ở HealthProfile nếu có trainingDayTargetCalories
            if (request.TrainingDayTargetCalories.HasValue)
            {
                var health = await _healthProfileService.GetAsync(userId);
                var updateHealthRequest = new UpdateHealthProfileRequest
                {
                    HeightCm = health.HeightCm ?? 170m,
                    WeightKg = health.WeightKg ?? 60m,
                    BodyFatPercent = health.BodyFatPercent,
                    ActivityLevel = health.ActivityLevel ?? "Light",
                    Goal = request.GoalMode, // Đồng bộ Goal mode
                    TargetCalories = request.TrainingDayTargetCalories.Value
                };
                await _healthProfileService.UpdateAsync(userId, updateHealthRequest);
            }

            return Ok(await _userAiProfileService.UpsertAsync(userId, new UpdateUserAiProfileRequest
            {
                Preferences = preferencesJson,
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

            if (targetCalories == 0)
            {
                // Mặc định lấy từ HealthProfile
                var health = await _healthProfileService.GetAsync(userId);
                targetCalories = health?.TargetCalories ?? 2000;
                
                // Điều chỉnh theo Gym Goal preferences (ngày tập/ngày nghỉ)
                var profile = await _userAiProfileService.GetAsync(userId);
                if (profile != null && !string.IsNullOrEmpty(profile.Preferences))
                {
                    try
                    {
                        using var doc = System.Text.Json.JsonDocument.Parse(profile.Preferences);
                        var root = doc.RootElement;

                        string schedule = root.TryGetProperty("weeklyTrainingSchedule", out var scheduleProp) ? (scheduleProp.GetString() ?? "") : "";
                        var todayDay = DateTime.UtcNow.AddHours(7).DayOfWeek.ToString(); // Ngày VN hiện tại
                        bool isTrainingDay = schedule.Contains(todayDay, StringComparison.OrdinalIgnoreCase);

                        if (isTrainingDay && root.TryGetProperty("trainingDayTargetCalories", out var trainCalProp) && trainCalProp.TryGetInt32(out var trainCal))
                        {
                            targetCalories = trainCal;
                        }
                        else if (!isTrainingDay && root.TryGetProperty("restDayTargetCalories", out var restCalProp) && restCalProp.TryGetInt32(out var restCal))
                        {
                            targetCalories = restCal;
                        }

                        // Áp dụng guardrail an toàn
                        if (root.TryGetProperty("minCalories", out var minCalProp) && minCalProp.TryGetInt32(out var minCal) && targetCalories < minCal)
                        {
                            targetCalories = minCal;
                        }
                        if (root.TryGetProperty("maxCalories", out var maxCalProp) && maxCalProp.TryGetInt32(out var maxCal) && targetCalories > maxCal)
                        {
                            targetCalories = maxCal;
                        }
                    }
                    catch { }
                }
            }

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

            // TÍNH TOÁN RECALIBRATION:
            // Đề xuất TargetCalories mới dựa trên GoalMode của AI Profile
            var profile = await _userAiProfileService.GetAsync(userId);
            var goalMode = profile?.EatingPattern ?? "maintain";

            var health = await _healthProfileService.GetAsync(userId);
            int currentTargetCalories = health?.TargetCalories ?? 2000;
            int suggestedCalories = currentTargetCalories;
            string reason = "Lượng calo mục tiêu của bạn đang ở trạng thái tối ưu.";

            if (weightTrend != null && weightTrend.WeightChangeKg.HasValue)
            {
                decimal weightChange = weightTrend.WeightChangeKg.Value;
                
                if (goalMode.Equals("cut", StringComparison.OrdinalIgnoreCase))
                {
                    if (weightChange >= 0) // Mục tiêu giảm cân nhưng cân nặng tăng hoặc không đổi
                    {
                        suggestedCalories = (int)(currentTargetCalories * 0.9); // Giảm 10%
                        reason = $"Mục tiêu là Cut nhưng cân nặng của bạn tăng hoặc không đổi ({weightChange:0.0} kg) trong tuần qua. Đề xuất giảm 10% lượng calo tiêu thụ.";
                    }
                    else
                    {
                        reason = $"Tiến độ giảm cân tốt ({weightChange:0.0} kg). Hãy tiếp tục giữ mức calo hiện tại.";
                    }
                }
                else if (goalMode.Equals("bulk", StringComparison.OrdinalIgnoreCase))
                {
                    if (weightChange <= 0) // Mục tiêu tăng cân nhưng cân nặng giảm hoặc giữ nguyên
                    {
                        suggestedCalories = (int)(currentTargetCalories * 1.1); // Tăng 10%
                        reason = $"Mục tiêu là Bulk nhưng cân nặng của bạn giảm hoặc giữ nguyên ({weightChange:0.0} kg) trong tuần qua. Đề xuất tăng 10% lượng calo tiêu thụ.";
                    }
                    else
                    {
                        reason = $"Tiến độ tăng cân tốt (+{weightChange:0.0} kg). Hãy tiếp tục giữ mức calo hiện tại.";
                    }
                }
                else if (goalMode.Equals("maintain", StringComparison.OrdinalIgnoreCase) || goalMode.Equals("recomp", StringComparison.OrdinalIgnoreCase))
                {
                    if (Math.Abs(weightChange) > 1.0m)
                    {
                        if (weightChange > 0)
                        {
                            suggestedCalories = (int)(currentTargetCalories * 0.95);
                            reason = $"Cân nặng tăng ({weightChange:0.0} kg) so với mục tiêu duy trì. Đề xuất giảm 5% calo.";
                        }
                        else
                        {
                            suggestedCalories = (int)(currentTargetCalories * 1.05);
                            reason = $"Cân nặng giảm ({weightChange:0.0} kg) so với mục tiêu duy trì. Đề xuất tăng 5% calo.";
                        }
                    }
                }
            }

            // Tự động áp dụng target calories đề xuất mới vào HealthProfile
            if (suggestedCalories != currentTargetCalories)
            {
                var updateHealthRequest = new UpdateHealthProfileRequest
                {
                    HeightCm = health?.HeightCm ?? 170m,
                    WeightKg = weightTrend?.LatestWeightKg ?? health?.WeightKg ?? 60m,
                    BodyFatPercent = health?.BodyFatPercent,
                    ActivityLevel = health?.ActivityLevel ?? "Light",
                    Goal = health?.Goal ?? "Maintain",
                    TargetCalories = suggestedCalories
                };
                await _healthProfileService.UpdateAsync(userId, updateHealthRequest);
            }

            return Ok(new
            {
                Message = "Recalibration data collected and target calories updated successfully.",
                CurrentTargetCalories = currentTargetCalories,
                SuggestedTargetCalories = suggestedCalories,
                Reason = reason,
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
            var adherence = await _mealPlanService.GetAdherenceAsync(userId, date);
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
