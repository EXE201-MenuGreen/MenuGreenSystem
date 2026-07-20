using System;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class UserDashboardService : IUserDashboardService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INutritionTrackingService _nutritionTrackingService;

        public UserDashboardService(
            IUnitOfWork unitOfWork,
            INutritionTrackingService nutritionTrackingService)
        {
            _unitOfWork = unitOfWork;
            _nutritionTrackingService = nutritionTrackingService;
        }

        public async Task<UserDashboardSummaryResponse> GetUserSummaryAsync(Guid userId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId) 
                ?? throw new Exception("User not found.");

            // Get health profile
            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(x => x.UserId == userId);
            var healthProfile = healthProfiles.FirstOrDefault();

            // Get current subscription
            var subscriptions = await _unitOfWork.UserSubscriptions.FindAsync(x => x.UserId == userId);
            var currentSubscription = subscriptions
                .Where(x => x.Status == "Active" && x.EndDate > DateTime.UtcNow)
                .OrderByDescending(x => x.CreatedAt)
                .FirstOrDefault();

            var subscriptionPlanName = "Free";
            var daysRemaining = 0;
            var isPremium = false;

            if (currentSubscription != null)
            {
                var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(currentSubscription.SubscriptionPlanId);
                subscriptionPlanName = plan?.Name ?? "Unknown";
                var remaining = currentSubscription.EndDate - DateTime.UtcNow;
                daysRemaining = remaining <= TimeSpan.Zero
                    ? 0
                    : (int)Math.Ceiling(remaining.TotalDays);
                isPremium = (plan?.PriceVnd ?? 0) > 0;
            }

            // Get today's nutrition
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var todayLogs = await _unitOfWork.MealLogs.FindAsync(
                x => x.UserId == userId && 
                x.LoggedAt.HasValue && 
                DateOnly.FromDateTime(x.LoggedAt.Value) == today);

            var todayCalories = todayLogs.Sum(x => x.CaloriesKcal ?? 0);
            var targetCalories = healthProfile?.TargetCalories ?? 2000;
            var progressPercent = targetCalories > 0 ? Math.Round(todayCalories / targetCalories * 100, 1) : 0;

            // Calculate tracking streak
            var allMealLogs = await _unitOfWork.MealLogs.FindAsync(x => x.UserId == userId);
            var trackingStreak = CalculateStreak(allMealLogs.Select(x => x.LoggedAt).ToList());
            var totalDaysTracked = allMealLogs
                .Where(x => x.LoggedAt.HasValue)
                .Select(x => DateOnly.FromDateTime(x.LoggedAt!.Value))
                .Distinct()
                .Count();

            // Calculate BMI
            decimal? bmi = null;
            if (healthProfile?.WeightKg.HasValue == true && healthProfile?.HeightCm.HasValue == true)
            {
                var heightM = healthProfile.HeightCm!.Value / 100m;
                bmi = Math.Round(healthProfile.WeightKg!.Value / (heightM * heightM), 1);
            }

            return new UserDashboardSummaryResponse
            {
                UserId = user.Id,
                UserName = user.Email ?? string.Empty,
                Email = user.Email,
                AvatarUrl = null, // Add if you have avatar field
                
                SubscriptionPlanName = subscriptionPlanName,
                SubscriptionDaysRemaining = daysRemaining,
                IsPremium = isPremium,
                
                CurrentWeightKg = healthProfile?.WeightKg,
                TargetWeightKg = healthProfile?.TargetWeightKg,
                HeightCm = healthProfile?.HeightCm,
                BMI = bmi,
                TargetCalories = targetCalories,
                
                Today = today,
                TodayCaloriesConsumed = todayCalories,
                TodayCaloriesTarget = targetCalories,
                CaloriesProgressPercent = progressPercent,
                
                TrackingStreak = trackingStreak,
                TotalMealLogsCount = allMealLogs.Count(),
                TotalDaysTracked = totalDaysTracked
            };
        }

        public async Task<NutritionTrendResponse> GetNutritionTrendAsync(Guid userId, DateOnly startDate, DateOnly endDate)
        {
            // Reuse existing service method
            return await _nutritionTrackingService.GetNutritionTrendsAsync(userId, startDate, endDate);
        }

        public async Task<WeightTrendResponse> GetWeightTrendAsync(Guid userId, DateOnly startDate, DateOnly endDate)
        {
            // Reuse existing service method
            return await _nutritionTrackingService.GetWeightTrendAsync(userId, startDate, endDate);
        }

        public async Task<RecommendationDashboardSummaryResponse> GetRecommendationSummaryAsync(Guid userId, int topCount = 5)
        {
            var recommendations = await _unitOfWork.RecommendationHistories.FindAsync(x => x.UserId == userId);
            var recentRecommendations = recommendations
                .OrderByDescending(x => x.CreatedAt)
                .Take(topCount)
                .ToList();

            var items = recentRecommendations.Select(r => new RecommendationItemSummary
            {
                Id = r.Id,
                Type = r.Type ?? "Unknown",
                ItemName = null, // Would need to join with Food/Recipe to get name
                MatchScore = r.Confidence,
                RecommendedDate = r.CreatedAt.HasValue ? DateOnly.FromDateTime(r.CreatedAt.Value.DateTime) : DateOnly.FromDateTime(DateTime.UtcNow)
            }).ToList();

            var lastGenerated = recommendations
                .Where(x => x.CreatedAt.HasValue)
                .OrderByDescending(x => x.CreatedAt)
                .Select(x => DateOnly.FromDateTime(x.CreatedAt!.Value.DateTime))
                .FirstOrDefault();

            return new RecommendationDashboardSummaryResponse
            {
                LatestRecommendations = items,
                TotalRecommendations = recommendations.Count(),
                LastGeneratedDate = lastGenerated != default ? lastGenerated : null,
                PersonalizedMessage = GetPersonalizedMessage(items.Count)
            };
        }

        private static int CalculateStreak(System.Collections.Generic.List<DateTime?> loggedDates)
        {
            if (loggedDates == null || loggedDates.Count == 0) return 0;

            var distinctDates = loggedDates
                .Where(x => x.HasValue)
                .Select(x => DateOnly.FromDateTime(x!.Value))
                .Distinct()
                .OrderByDescending(x => x)
                .ToList();

            if (distinctDates.Count == 0) return 0;

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var yesterday = today.AddDays(-1);

            // Check if logged today or yesterday
            if (distinctDates[0] != today && distinctDates[0] != yesterday)
            {
                return 0;
            }

            int streak = 0;
            var currentDate = distinctDates[0];

            foreach (var date in distinctDates)
            {
                if (date == currentDate)
                {
                    streak++;
                    currentDate = currentDate.AddDays(-1);
                }
                else if (date == currentDate.AddDays(-1))
                {
                    streak++;
                    currentDate = date.AddDays(-1);
                }
                else
                {
                    break;
                }
            }

            return streak;
        }

        private static string GetPersonalizedMessage(int recommendationCount)
        {
            if (recommendationCount == 0)
            {
                return "Chưa có gợi ý cho bạn. Hãy cập nhật hồ sơ sức khỏe để nhận gợi ý phù hợp!";
            }

            return $"Có {recommendationCount} gợi ý món ăn và công thức phù hợp với bạn!";
        }
    }
}
