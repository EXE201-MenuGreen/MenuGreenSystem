using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Controller quản lý engagement workflow như Habit Score, streak và nhắc nhở.
    /// Tái sử dụng dữ liệu meal log, weight log, meal plan và notification hiện có.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class EngagementController : ControllerBase
    {
        private readonly INutritionTrackingService _nutritionTrackingService;
        private readonly IMealPlanService _mealPlanService;
        private readonly INotificationService _notificationService;

        public EngagementController(
            INutritionTrackingService nutritionTrackingService,
            IMealPlanService mealPlanService,
            INotificationService notificationService)
        {
            _nutritionTrackingService = nutritionTrackingService;
            _mealPlanService = mealPlanService;
            _notificationService = notificationService;
        }

        /// <summary>
        /// Lấy Habit Score tổng hợp của user từ tracking hiện có.
        /// </summary>
        [HttpGet("habit-score")]
        public async Task<IActionResult> GetHabitScore([FromQuery] string period = "week")
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var score = await BuildHabitScoreAsync(userId, period);
            return Ok(score);
        }

        /// <summary>
        /// Lấy lịch sử Habit Score theo ngày trong một khoảng thời gian.
        /// </summary>
        [HttpGet("habit-score/history")]
        public async Task<IActionResult> GetHabitScoreHistory([FromQuery] int days = 30)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            days = Math.Clamp(days, 7, 90);
            var endDate = DateOnly.FromDateTime(DateTime.UtcNow);
            var startDate = endDate.AddDays(-(days - 1));
            var history = new List<object>();

            for (var date = startDate; date <= endDate; date = date.AddDays(1))
            {
                var score = await BuildHabitScoreAsync(userId, "day", date);
                history.Add(new
                {
                    Date = date,
                    Score = score.Score,
                    Label = score.Label
                });
            }

            return Ok(new
            {
                StartDate = startDate,
                EndDate = endDate,
                Items = history
            });
        }

        /// <summary>
        /// Trả breakdown các thành phần tạo nên Habit Score.
        /// </summary>
        [HttpGet("habit-score/breakdown")]
        public async Task<IActionResult> GetHabitScoreBreakdown([FromQuery] string period = "week")
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var score = await BuildHabitScoreAsync(userId, period);
            return Ok(new
            {
                score.Score,
                score.Label,
                score.Period,
                score.Range,
                score.Components,
                score.Recommendations
            });
        }

        /// <summary>
        /// Lấy streak hiện tại từ meal plan để hỗ trợ Habit Score.
        /// </summary>
        [HttpGet("streak")]
        public async Task<IActionResult> GetStreak()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _mealPlanService.GetStreaksAsync(userId));
        }

        /// <summary>
        /// Lấy dashboard notification analytics để xem mức độ engagement.
        /// </summary>
        [HttpGet("notification-engagement")]
        public async Task<IActionResult> GetNotificationEngagement()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _notificationService.GetAnalyticsAsync(userId));
        }

        private async Task<HabitScoreResponse> BuildHabitScoreAsync(Guid userId, string period, DateOnly? dayOverride = null)
        {
            var (startDate, endDate) = ResolveRange(period, dayOverride);

            var summary = await _nutritionTrackingService.GetNutritionSummaryAsync(userId, period, dayOverride);
            var dashboard = await _nutritionTrackingService.GetDashboardAsync(userId, period, startDate, endDate);
            var streak = await _mealPlanService.GetStreaksAsync(userId);
            var notificationAnalytics = await _notificationService.GetAnalyticsAsync(userId);

            var totalDays = Math.Max(1, endDate.DayNumber - startDate.DayNumber + 1);
            var mealDays = dashboard.Days.Count(d => d.TotalCalories > 0);
            var mealConsistency = Math.Min(100, (int)Math.Round((mealDays / (double)totalDays) * 100));

            var avgCalories = summary.AvgCaloriesPerDay;
            var calorieConsistency = avgCalories <= 0 ? 0 : Math.Max(0, 100 - (int)Math.Min(60, Math.Abs(avgCalories - 2000) / 20));

            var streakScore = Math.Min(100, (int)(streak.CurrentStreakDays * 10));
            var engagementScore = GetOpenRateScore(notificationAnalytics);

            var score = (int)Math.Round(
                mealConsistency * 0.35 +
                calorieConsistency * 0.35 +
                streakScore * 0.20 +
                engagementScore * 0.10);

            score = Math.Clamp(score, 0, 100);

            return new HabitScoreResponse
            {
                Period = period,
                Range = new HabitScoreRange
                {
                    StartDate = startDate,
                    EndDate = endDate
                },
                Score = score,
                Label = GetLabel(score),
                Components = new List<HabitScoreComponent>
                {
                    new HabitScoreComponent
                    {
                        Name = "Meal consistency",
                        Score = mealConsistency,
                        Weight = 0.35,
                        Detail = $"{mealDays}/{totalDays} ngày có meal log"
                    },
                    new HabitScoreComponent
                    {
                        Name = "Calorie consistency",
                        Score = calorieConsistency,
                        Weight = 0.35,
                        Detail = $"Avg {Math.Round(avgCalories, 2)} kcal/ngày"
                    },
                    new HabitScoreComponent
                    {
                        Name = "Meal plan streak",
                        Score = streakScore,
                        Weight = 0.20,
                        Detail = $"Current streak: {streak.CurrentStreakDays}"
                    },
                    new HabitScoreComponent
                    {
                        Name = "Notification engagement",
                        Score = engagementScore,
                        Weight = 0.10,
                        Detail = "Derived from notification analytics"
                    }
                },
                Recommendations = BuildRecommendations(mealConsistency, calorieConsistency, streakScore, engagementScore)
            };
        }

        private static List<string> BuildRecommendations(int mealConsistency, int calorieConsistency, int streakScore, int engagementScore)
        {
            var items = new List<string>();

            if (mealConsistency < 70) items.Add("Log bữa đều hơn mỗi ngày để tăng tính ổn định.");
            if (calorieConsistency < 70) items.Add("Giữ calories gần mục tiêu hơn để score tăng nhanh.");
            if (streakScore < 50) items.Add("Duy trì chuỗi ngày liên tiếp để cải thiện streak.");
            if (engagementScore < 50) items.Add("Mở và tương tác với notification thường xuyên hơn.");

            if (items.Count == 0)
            {
                items.Add("Bạn đang duy trì thói quen khá tốt, hãy giữ nhịp này.");
            }

            return items;
        }

        private static int GetOpenRateScore(object analytics)
        {
            var type = analytics.GetType();
            var openRateProp = type.GetProperty("OpenRate");
            if (openRateProp?.GetValue(analytics) is double rate)
            {
                return Math.Clamp((int)Math.Round(rate * 100), 0, 100);
            }

            return 0;
        }

        private static string GetLabel(int score)
        {
            if (score >= 85) return "Excellent";
            if (score >= 70) return "Good";
            if (score >= 50) return "Fair";
            return "Needs Improvement";
        }

        private static (DateOnly StartDate, DateOnly EndDate) ResolveRange(string period, DateOnly? dayOverride)
        {
            var endDate = dayOverride ?? DateOnly.FromDateTime(DateTime.UtcNow);
            return period.ToLowerInvariant() switch
            {
                "day" => (endDate, endDate),
                "month" => (endDate.AddDays(-29), endDate),
                _ => (endDate.AddDays(-6), endDate)
            };
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }

    public class HabitScoreResponse
    {
        public string Period { get; set; } = "week";
        public HabitScoreRange Range { get; set; } = new();
        public int Score { get; set; }
        public string Label { get; set; } = string.Empty;
        public List<HabitScoreComponent> Components { get; set; } = new();
        public List<string> Recommendations { get; set; } = new();
    }

    public class HabitScoreRange
    {
        public DateOnly StartDate { get; set; }
        public DateOnly EndDate { get; set; }
    }

    public class HabitScoreComponent
    {
        public string Name { get; set; } = string.Empty;
        public int Score { get; set; }
        public double Weight { get; set; }
        public string Detail { get; set; } = string.Empty;
    }
}
