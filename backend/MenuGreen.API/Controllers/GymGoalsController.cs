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
        /// Get current user Gym/PT goal configuration.
        /// </summary>
        [HttpGet("me")]
        public async Task<IActionResult> GetMe()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _userAiProfileService.GetAsync(userId));
        }

        /// <summary>
        /// Create or update goal mode, training schedule, and initial targets for user.
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateOrUpdate([FromBody] GymGoalUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var profile = await _userAiProfileService.GetAsync(userId);
            
            // Serialize entire request to preferences to store fully and safely
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

            // Sync HealthProfile TargetCalories if trainingDayTargetCalories is provided
            if (request.TrainingDayTargetCalories.HasValue)
            {
                var health = await _healthProfileService.GetAsync(userId);
                var updateHealthRequest = new UpdateHealthProfileRequest
                {
                    HeightCm = health.HeightCm ?? 170m,
                    WeightKg = health.WeightKg ?? 60m,
                    BodyFatPercent = health.BodyFatPercent,
                    ActivityLevel = health.ActivityLevel ?? "Light",
                    Goal = request.GoalMode,
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
        /// Update current goal mode and training schedule.
        /// </summary>
        [HttpPut]
        public async Task<IActionResult> Update([FromBody] GymGoalUpsertRequest request)
        {
            return await CreateOrUpdate(request);
        }

        /// <summary>
        /// Get suggested nutrition plan based on goal mode and target calories.
        /// </summary>
        [HttpGet("plan")]
        public async Task<IActionResult> GetPlan([FromQuery] int targetCalories = 0, [FromQuery] int top = 10)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            if (targetCalories == 0)
            {
                // Default from HealthProfile
                var health = await _healthProfileService.GetAsync(userId);
                targetCalories = health?.TargetCalories ?? 2000;
                
                // Adjust based on Gym Goal preferences (training day/rest day)
                var profile = await _userAiProfileService.GetAsync(userId);
                if (profile != null && !string.IsNullOrEmpty(profile.Preferences))
                {
                    try
                    {
                        using var doc = System.Text.Json.JsonDocument.Parse(profile.Preferences);
                        var root = doc.RootElement;

                        string schedule = root.TryGetProperty("weeklyTrainingSchedule", out var scheduleProp) ? (scheduleProp.GetString() ?? "") : "";
                        var todayDay = DateTime.UtcNow.AddHours(7).DayOfWeek.ToString();
                        bool isTrainingDay = schedule.Contains(todayDay, StringComparison.OrdinalIgnoreCase);

                        if (isTrainingDay && root.TryGetProperty("trainingDayTargetCalories", out var trainCalProp) && trainCalProp.TryGetInt32(out var trainCal))
                        {
                            targetCalories = trainCal;
                        }
                        else if (!isTrainingDay && root.TryGetProperty("restDayTargetCalories", out var restCalProp) && restCalProp.TryGetInt32(out var restCal))
                        {
                            targetCalories = restCal;
                        }

                        // Apply safe guardrail
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
        /// Collect tracking data to recalibrate target calories/macros weekly.
        /// </summary>
        [HttpPost("recalibrate")]
        public async Task<IActionResult> Recalibrate([FromBody] GymGoalRecalibrateRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var summary = await _nutritionTrackingService.GetNutritionSummaryAsync(userId, request.Period ?? "week", request.Date);
            var dashboard = await _nutritionTrackingService.GetDashboardAsync(userId, request.Range ?? "week", request.StartDate, request.EndDate);
            var weightTrend = await _nutritionTrackingService.GetWeightTrendAsync(userId, request.StartDate ?? DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-7)), request.EndDate ?? DateOnly.FromDateTime(DateTime.UtcNow));

            // RECALIBRATION CALCULATION:
            // Suggest new TargetCalories based on AI Profile GoalMode
            var profile = await _userAiProfileService.GetAsync(userId);
            var goalMode = profile?.EatingPattern ?? "maintain";

            var health = await _healthProfileService.GetAsync(userId);
            int currentTargetCalories = health?.TargetCalories ?? 2000;
            int suggestedCalories = currentTargetCalories;
            string reason = "Your target calorie intake is at an optimal level.";

            if (weightTrend != null && weightTrend.WeightChangeKg.HasValue)
            {
                decimal weightChange = weightTrend.WeightChangeKg.Value;
                
                if (goalMode.Equals("cut", StringComparison.OrdinalIgnoreCase))
                {
                    if (weightChange >= 0)
                    {
                        suggestedCalories = (int)(currentTargetCalories * 0.9);
                        reason = $"Goal is Cut but your weight increased or stayed the same ({weightChange:0.0} kg) over the past week. Suggesting 10% reduction in calorie intake.";
                    }
                    else
                    {
                        reason = $"Good weight loss progress ({weightChange:0.0} kg). Continue maintaining current calorie level.";
                    }
                }
                else if (goalMode.Equals("bulk", StringComparison.OrdinalIgnoreCase))
                {
                    if (weightChange <= 0)
                    {
                        suggestedCalories = (int)(currentTargetCalories * 1.1);
                        reason = $"Goal is Bulk but your weight decreased or stayed the same ({weightChange:0.0} kg) over the past week. Suggesting 10% increase in calorie intake.";
                    }
                    else
                    {
                        reason = $"Good weight gain progress (+{weightChange:0.0} kg). Continue maintaining current calorie level.";
                    }
                }
                else if (goalMode.Equals("maintain", StringComparison.OrdinalIgnoreCase) || goalMode.Equals("recomp", StringComparison.OrdinalIgnoreCase))
                {
                    if (Math.Abs(weightChange) > 1.0m)
                    {
                        if (weightChange > 0)
                        {
                            suggestedCalories = (int)(currentTargetCalories * 0.95);
                            reason = $"Weight increased ({weightChange:0.0} kg) versus maintain goal. Suggesting 5% calorie reduction.";
                        }
                        else
                        {
                            suggestedCalories = (int)(currentTargetCalories * 1.05);
                            reason = $"Weight decreased ({weightChange:0.0} kg) versus maintain goal. Suggesting 5% calorie increase.";
                        }
                    }
                }
            }

            // Auto-apply suggested target calories to HealthProfile
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
        /// Generate alerts based on goal deviation from meal plan compare and tracking data.
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
        /// Generate advanced report for PT/coach review, aggregated from existing meal plan and tracking.
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
