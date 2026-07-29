using System;
using System.Security.Claims;
using System.Text.Json;
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
    [Authorize(Policy = "GymerOnly")]
    public class GymGoalsController : ControllerBase
    {
        private readonly IUserAiProfileService _userAiProfileService;
        private readonly IRecommendationService _recommendationService;
        private readonly INutritionTrackingService _nutritionTrackingService;
        private readonly IMealPlanService _mealPlanService;
        private readonly IHealthProfileService _healthProfileService;
        private readonly IDailyStarterService _dailyStarterService;

        public GymGoalsController(
            IUserAiProfileService userAiProfileService,
            IRecommendationService recommendationService,
            INutritionTrackingService nutritionTrackingService,
            IMealPlanService mealPlanService,
            IHealthProfileService healthProfileService,
            IDailyStarterService dailyStarterService)
        {
            _userAiProfileService = userAiProfileService;
            _recommendationService = recommendationService;
            _nutritionTrackingService = nutritionTrackingService;
            _mealPlanService = mealPlanService;
            _healthProfileService = healthProfileService;
            _dailyStarterService = dailyStarterService;
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
        [HttpPost("setup")]
        public async Task<IActionResult> CreateOrUpdate([FromBody] GymGoalUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var profile = await _userAiProfileService.GetAsync(userId);
            
            string preferencesJson = request.Preferences;
            if (string.IsNullOrEmpty(preferencesJson))
            {
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
                    targetWeightKg = request.TargetWeightKg,
                    targetBodyFatPercent = request.TargetBodyFatPercent,
                    notes = request.Notes
                };
                preferencesJson = System.Text.Json.JsonSerializer.Serialize(preferencesData);
            }

            // Sync HealthProfile TargetCalories if trainingDayTargetCalories is provided
            if (request.TrainingDayTargetCalories.HasValue || request.TargetWeightKg.HasValue)
            {
                var health = await _healthProfileService.GetAsync(userId);
                var updateHealthRequest = new UpdateHealthProfileRequest
                {
                    HeightCm = health.HeightCm ?? 170m,
                    WeightKg = health.WeightKg ?? 60m,
                    BodyFatPercent = health.BodyFatPercent,
                    TargetWeightKg = request.TargetWeightKg,
                    ActivityLevel = health.ActivityLevel ?? "Light",
                    Goal = request.GoalMode,
                    TargetCalories = request.TrainingDayTargetCalories ?? health.TargetCalories
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
        public async Task<IActionResult> GetPlan(
            [FromQuery] DateOnly? date = null,
            [FromQuery] int targetCalories = 0,
            [FromQuery] int top = 10)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var planDate = date ?? DateOnly.FromDateTime(DateTime.UtcNow.AddHours(7));
            var hasApplicableConfiguration = targetCalories > 0;
            int? minCaloriesOverride = null;
            int? maxCaloriesOverride = null;

            if (targetCalories == 0)
            {
                // Default from HealthProfile
                var health = await _healthProfileService.GetAsync(userId);
                targetCalories = health?.TargetCalories ?? 2000;
                
                // Adjust based on Gym Goal preferences (Day -> Week -> Month override hierarchy)
                var profile = await _userAiProfileService.GetAsync(userId);
                if (profile != null && !string.IsNullOrEmpty(profile.Preferences))
                {
                    try
                    {
                        using var doc = JsonDocument.Parse(profile.Preferences);
                        var root = doc.RootElement;

                        string schedule = root.TryGetProperty("weeklyTrainingSchedule", out var scheduleProp) ? (scheduleProp.GetString() ?? "") : "";
                        var todayDay = planDate.DayOfWeek.ToString();
                        bool isTrainingDay = schedule.Contains(todayDay, StringComparison.OrdinalIgnoreCase);

                        var todayDateStr = planDate.ToString("yyyy-MM-dd");

                        int diff = (7 + (planDate.DayOfWeek - DayOfWeek.Monday)) % 7;
                        var monday = planDate.AddDays(-1 * diff);
                        string weekStartStr = monday.ToString("yyyy-MM-dd");

                        string monthStr = planDate.ToString("yyyy-MM");

                        int? resolvedCalories = null;
                        bool foundConfig = false;

                        // 1. Check dailyDetails
                        if (root.TryGetProperty("dailyDetails", out var dailyDetailsProp) && dailyDetailsProp.ValueKind == System.Text.Json.JsonValueKind.Array)
                        {
                            foreach (var element in dailyDetailsProp.EnumerateArray())
                            {
                                if (element.TryGetProperty("dateString", out var dateStrProp) && dateStrProp.GetString() == todayDateStr)
                                {
                                    if (
                                        element.TryGetProperty("isTraining", out var isTrainProp)
                                        && (
                                            isTrainProp.ValueKind == JsonValueKind.True
                                            || isTrainProp.ValueKind == JsonValueKind.False
                                        )
                                    )
                                    {
                                        isTrainingDay = isTrainProp.GetBoolean();
                                    }
                                    
                                    if (TryReadInt32(element, "customCalories", out var customCalVal))
                                    {
                                        resolvedCalories = customCalVal;
                                    }
                                    
                                    if (TryReadInt32(element, "minCalories", out var minCalVal))
                                    {
                                        minCaloriesOverride = minCalVal;
                                    }
                                    
                                    if (TryReadInt32(element, "maxCalories", out var maxCalVal))
                                    {
                                        maxCaloriesOverride = maxCalVal;
                                    }

                                    foundConfig = true;
                                    break;
                                }
                            }
                        }

                        // 2. Check weeklyDetails
                        if (root.TryGetProperty("weeklyDetails", out var weeklyDetailsProp) && weeklyDetailsProp.ValueKind == System.Text.Json.JsonValueKind.Array)
                        {
                            foreach (var element in weeklyDetailsProp.EnumerateArray())
                            {
                                if (element.TryGetProperty("weekStartDateString", out var weekStartProp) && weekStartProp.GetString() == weekStartStr)
                                {
                                    if (resolvedCalories == null && TryReadInt32(element, "customCalories", out var customCalVal))
                                    {
                                        resolvedCalories = customCalVal;
                                    }
                                    
                                    if (minCaloriesOverride == null && TryReadInt32(element, "minCalories", out var minCalVal))
                                    {
                                        minCaloriesOverride = minCalVal;
                                    }
                                    
                                    if (maxCaloriesOverride == null && TryReadInt32(element, "maxCalories", out var maxCalVal))
                                    {
                                        maxCaloriesOverride = maxCalVal;
                                    }

                                    foundConfig = true;
                                    break;
                                }
                            }
                        }

                        // 3. Check monthlyDetails
                        if (root.TryGetProperty("monthlyDetails", out var monthlyDetailsProp) && monthlyDetailsProp.ValueKind == System.Text.Json.JsonValueKind.Array)
                        {
                            foreach (var element in monthlyDetailsProp.EnumerateArray())
                            {
                                if (element.TryGetProperty("monthString", out var monthProp) && monthProp.GetString() == monthStr)
                                {
                                    if (resolvedCalories == null && TryReadInt32(element, "customCalories", out var customCalVal))
                                    {
                                        resolvedCalories = customCalVal;
                                    }
                                    
                                    if (minCaloriesOverride == null && TryReadInt32(element, "minCalories", out var minCalVal))
                                    {
                                        minCaloriesOverride = minCalVal;
                                    }
                                    
                                    if (maxCaloriesOverride == null && TryReadInt32(element, "maxCalories", out var maxCalVal))
                                    {
                                        maxCaloriesOverride = maxCalVal;
                                    }

                                    foundConfig = true;
                                    break;
                                }
                            }
                        }

                        // 4. Default weekly/rest day fallback
                        if (resolvedCalories == null)
                        {
                            if (isTrainingDay && TryReadInt32(root, "trainingDayTargetCalories", out var trainCal))
                            {
                                resolvedCalories = trainCal;
                            }
                            else if (!isTrainingDay && TryReadInt32(root, "restDayTargetCalories", out var restCal))
                            {
                                resolvedCalories = restCal;
                            }
                        }

                        if (resolvedCalories.HasValue)
                        {
                            targetCalories = resolvedCalories.Value;
                        }

                        // A scoped calorie target is authoritative. Only use legacy/global
                        // guardrails when the scoped configuration did not set a target.
                        if (resolvedCalories == null && minCaloriesOverride == null && TryReadInt32(root, "minCalories", out var minCalG))
                        {
                            minCaloriesOverride = minCalG;
                        }
                        if (resolvedCalories == null && maxCaloriesOverride == null && TryReadInt32(root, "maxCalories", out var maxCalG))
                        {
                            maxCaloriesOverride = maxCalG;
                        }

                        if (minCaloriesOverride.HasValue && targetCalories < minCaloriesOverride.Value)
                        {
                            targetCalories = minCaloriesOverride.Value;
                        }
                        if (maxCaloriesOverride.HasValue && targetCalories > maxCaloriesOverride.Value)
                        {
                            targetCalories = maxCaloriesOverride.Value;
                        }

                        hasApplicableConfiguration = foundConfig;
                    }
                    catch (Exception ex) when (
                        ex is JsonException || ex is InvalidOperationException
                    )
                    {
                        hasApplicableConfiguration = false;
                    }
                }
            }

            if (!hasApplicableConfiguration)
            {
                return Ok(new
                {
                    Date = planDate.ToString("yyyy-MM-dd"),
                    HasConfiguration = false,
                    TargetCalories = (int?)null,
                    Items = Array.Empty<object>()
                });
            }

            var items = await _dailyStarterService.GetRecommendationsAsync(userId, new RecommendationRequest
            {
                Date = planDate,
                TargetCalories = targetCalories,
                MinCalories = minCaloriesOverride,
                MaxCalories = maxCaloriesOverride,
                Top = top
            });

            return Ok(new
            {
                Date = planDate.ToString("yyyy-MM-dd"),
                HasConfiguration = true,
                TargetCalories = targetCalories,
                Items = items
            });
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
            decimal? targetWeightKg = null;
            decimal? targetBodyFatPercent = null;
            try
            {
                if (!string.IsNullOrWhiteSpace(profile?.Preferences))
                {
                    using var preferences = System.Text.Json.JsonDocument.Parse(profile.Preferences);
                    var root = preferences.RootElement;
                    if (TryReadDecimal(root, "targetWeightKg", out var parsedWeight))
                    {
                        targetWeightKg = parsedWeight;
                    }
                    if (TryReadDecimal(root, "targetBodyFatPercent", out var parsedFat))
                    {
                        targetBodyFatPercent = parsedFat;
                    }
                }
            }
            catch (System.Text.Json.JsonException)
            {
                // Keep recalibration available for legacy/non-JSON preference values.
            }

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

            if (weightTrend?.LatestWeightKg is decimal latestWeight && targetWeightKg.HasValue)
            {
                var distance = latestWeight - targetWeightKg.Value;
                reason += $" Current weight is {latestWeight:0.0} kg, {Math.Abs(distance):0.0} kg " +
                    (distance > 0 ? "above" : distance < 0 ? "below" : "at") + " the target.";
            }
            var latestBodyFat = weightTrend?.WeightData.LastOrDefault(x => x.BodyFatPercent.HasValue)?.BodyFatPercent;
            if (latestBodyFat.HasValue && targetBodyFatPercent.HasValue)
            {
                var distance = latestBodyFat.Value - targetBodyFatPercent.Value;
                reason += $" Body fat is {latestBodyFat:0.0}%, {Math.Abs(distance):0.0} percentage points " +
                    (distance > 0 ? "above" : distance < 0 ? "below" : "at") + " the target.";
            }

            // Auto-apply suggested target calories to HealthProfile
            if (suggestedCalories != currentTargetCalories)
            {
                var updateHealthRequest = new UpdateHealthProfileRequest
                {
                    HeightCm = health?.HeightCm ?? 170m,
                    WeightKg = weightTrend?.LatestWeightKg ?? health?.WeightKg ?? 60m,
                    BodyFatPercent = health?.BodyFatPercent,
                    TargetWeightKg = health?.TargetWeightKg,
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

        private static bool TryReadInt32(
            JsonElement parent,
            string propertyName,
            out int value)
        {
            value = default;
            return parent.ValueKind == JsonValueKind.Object
                && parent.TryGetProperty(propertyName, out var property)
                && property.ValueKind == JsonValueKind.Number
                && property.TryGetInt32(out value);
        }

        private static bool TryReadDecimal(
            JsonElement parent,
            string propertyName,
            out decimal value)
        {
            value = default;
            return parent.ValueKind == JsonValueKind.Object
                && parent.TryGetProperty(propertyName, out var property)
                && property.ValueKind == JsonValueKind.Number
                && property.TryGetDecimal(out value);
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
