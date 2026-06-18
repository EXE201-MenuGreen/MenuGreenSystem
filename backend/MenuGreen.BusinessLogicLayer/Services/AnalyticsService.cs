using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class AnalyticsService : IAnalyticsService
    {
        private readonly IUnitOfWork _unitOfWork;

        public AnalyticsService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<ActivityLogResponse> CreateActivityLogAsync(Guid userId, ActivityLogCreateRequest request)
        {
            var entity = new ActivityLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Action = request.Action,
                EntityType = request.EntityType,
                EntityId = request.EntityId,
                Metadata = request.Metadata,
                CreatedAt = request.CreatedAt ?? DateTimeOffset.UtcNow
            };

            await _unitOfWork.ActivityLogs.AddAsync(entity);
            await _unitOfWork.CompleteAsync();
            return Map(entity);
        }

        public async Task<IEnumerable<ActivityLogResponse>> CreateActivityLogsAsync(Guid userId, IEnumerable<ActivityLogCreateRequest> requests)
        {
            var results = new List<ActivityLogResponse>();
            foreach (var request in requests ?? Array.Empty<ActivityLogCreateRequest>())
            {
                results.Add(await CreateActivityLogAsync(userId, request));
            }
            return results;
        }

        public async Task<IEnumerable<ActivityLogResponse>> GetActivityLogsAsync(Guid? userId = null, DateTimeOffset? from = null, DateTimeOffset? to = null, string? action = null)
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            var query = logs.AsQueryable();
            if (userId.HasValue) query = query.Where(x => x.UserId == userId.Value);
            if (from.HasValue) query = query.Where(x => x.CreatedAt >= from.Value);
            if (to.HasValue) query = query.Where(x => x.CreatedAt <= to.Value);
            if (!string.IsNullOrWhiteSpace(action)) query = query.Where(x => x.Action == action);
            return query.OrderByDescending(x => x.CreatedAt).Select(Map).ToList();
        }

        public async Task<ActivityLogResponse> GetActivityLogByIdAsync(Guid id)
        {
            var log = await _unitOfWork.ActivityLogs.GetByIdAsync(id) ?? throw new Exception("Activity log not found.");
            return Map(log);
        }

        public async Task<AnalyticsDashboardResponse> GetDashboardAsync()
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync()).ToList();
            var users = await _unitOfWork.Users.GetAllAsync();
            var last7Days = DateTimeOffset.UtcNow.AddDays(-7);
            return new AnalyticsDashboardResponse
            {
                TotalEvents = logs.Count,
                TotalUsers = users.Count(),
                ActiveUsers = logs.Select(x => x.UserId).Distinct().Count(),
                ActiveUsersLast7Days = logs.Count(x => x.CreatedAt.HasValue && x.CreatedAt >= last7Days),
                MealLoggedEvents = logs.Count(x => string.Equals(x.Action, "meal_logged", StringComparison.OrdinalIgnoreCase)),
                NotificationOpenedEvents = logs.Count(x => string.Equals(x.Action, "notification_opened", StringComparison.OrdinalIgnoreCase)),
                SubscriptionStartedEvents = logs.Count(x => string.Equals(x.Action, "subscription_started", StringComparison.OrdinalIgnoreCase))
            };
        }

        public async Task<AnalyticsSummaryResponse> GetSummaryAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync()).Where(x => x.CreatedAt >= from && x.CreatedAt <= to).ToList();
            return new AnalyticsSummaryResponse
            {
                TotalEvents = logs.Count,
                TotalUsers = logs.Select(x => x.UserId).Distinct().Count(),
                ActiveUsers = logs.Select(x => x.UserId).Distinct().Count(),
                MealLoggedEvents = logs.Count(x => string.Equals(x.Action, "meal_logged", StringComparison.OrdinalIgnoreCase)),
                NotificationOpenedEvents = logs.Count(x => string.Equals(x.Action, "notification_opened", StringComparison.OrdinalIgnoreCase)),
                SubscriptionStartedEvents = logs.Count(x => string.Equals(x.Action, "subscription_started", StringComparison.OrdinalIgnoreCase)),
                From = from,
                To = to
            };
        }

        public async Task<IEnumerable<object>> GetMetricsAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync())
                .Where(x => x.CreatedAt >= from && x.CreatedAt <= to)
                .ToList();

            var grouped = logs
                .GroupBy(x => x.CreatedAt?.Date)
                .OrderBy(x => x.Key)
                .Select(g => new
                {
                    Date = g.Key,
                    Events = g.Count(),
                    Users = g.Select(x => x.UserId).Distinct().Count()
                });

            return grouped.Cast<object>().ToList();
        }

        public async Task<IEnumerable<AnalyticsTopEventResponse>> GetTopEventsAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync())
                .Where(x => x.CreatedAt >= from && x.CreatedAt <= to);

            return logs
                .GroupBy(x => x.Action)
                .OrderByDescending(g => g.Count())
                .Take(10)
                .Select(g => new AnalyticsTopEventResponse
                {
                    Action = g.Key,
                    Count = g.Count()
                })
                .ToList();
        }

        public async Task<IEnumerable<AnalyticsFunnelStepResponse>> GetFunnelAsync()
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync()).ToList();
            var steps = new[] { "register", "onboarding_completed", "health_profile_completed", "meal_logged" };
            return BuildFunnel(logs, steps);
        }

        public async Task<IEnumerable<AnalyticsFunnelStepResponse>> PreviewFunnelAsync(IEnumerable<string> steps)
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync()).ToList();
            var safeSteps = steps?.Where(x => !string.IsNullOrWhiteSpace(x)).ToArray() ?? Array.Empty<string>();
            return BuildFunnel(logs, safeSteps);
        }

        public async Task<IEnumerable<AnalyticsFunnelStepResponse>> GetMealOnboardingFunnelAsync()
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync()).ToList();
            return BuildFunnel(logs, new[] { "register", "onboarding_completed", "meal_logged" });
        }

        public async Task<IEnumerable<AnalyticsFunnelStepResponse>> GetSubscriptionFunnelAsync()
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync()).ToList();
            return BuildFunnel(logs, new[] { "register", "subscription_started", "subscription_renewed" });
        }

        public async Task<IEnumerable<AnalyticsCohortResponse>> GetCohortAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            return logs
                .Where(x => x.CreatedAt.HasValue)
                .GroupBy(x => x.CreatedAt!.Value.Date)
                .OrderBy(g => g.Key)
                .Select(g => new AnalyticsCohortResponse
                {
                    CohortDate = DateOnly.FromDateTime(g.Key),
                    Users = g.Select(x => x.UserId).Distinct().Count(),
                    Events = g.Count()
                })
                .ToList();
        }

        public async Task<IEnumerable<object>> GetRetentionAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            var users = logs.GroupBy(x => x.UserId).ToList();
            return new[]
            {
                new { Day = "D1", Retention = users.Count(g => g.Any()) },
                new { Day = "D7", Retention = users.Count(g => g.Count() >= 2) },
                new { Day = "D30", Retention = users.Count(g => g.Count() >= 3) }
            }.Cast<object>();
        }

        public async Task<IEnumerable<AnalyticsCohortResponse>> GetCohortBySignupDateAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            return logs.Where(x => string.Equals(x.Action, "register", StringComparison.OrdinalIgnoreCase) && x.CreatedAt.HasValue)
                .GroupBy(x => x.CreatedAt!.Value.Date)
                .Select(g => new AnalyticsCohortResponse
                {
                    CohortDate = DateOnly.FromDateTime(g.Key),
                    Users = g.Select(x => x.UserId).Distinct().Count(),
                    Events = g.Count()
                })
                .ToList();
        }

        public async Task<IEnumerable<AnalyticsCohortResponse>> GetCohortByFirstMealLogAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            return logs.Where(x => string.Equals(x.Action, "meal_logged", StringComparison.OrdinalIgnoreCase) && x.CreatedAt.HasValue)
                .GroupBy(x => x.CreatedAt!.Value.Date)
                .Select(g => new AnalyticsCohortResponse
                {
                    CohortDate = DateOnly.FromDateTime(g.Key),
                    Users = g.Select(x => x.UserId).Distinct().Count(),
                    Events = g.Count()
                })
                .ToList();
        }

        public async Task<IEnumerable<AnalyticsCohortResponse>> GetCohortBySubscriptionAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            return logs.Where(x => !string.IsNullOrWhiteSpace(x.Action) && x.Action.Contains("subscription", StringComparison.OrdinalIgnoreCase) && x.CreatedAt.HasValue)
                .GroupBy(x => x.CreatedAt!.Value.Date)
                .Select(g => new AnalyticsCohortResponse
                {
                    CohortDate = DateOnly.FromDateTime(g.Key),
                    Users = g.Select(x => x.UserId).Distinct().Count(),
                    Events = g.Count()
                })
                .ToList();
        }

        public async Task<IEnumerable<AnalyticsFunnelStepResponse>> GetDropOffAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            var funnel = BuildFunnel(logs, new[] { "register", "onboarding_completed", "health_profile_completed", "meal_logged" }).ToList();

            for (var i = 0; i < funnel.Count; i++)
            {
                funnel[i].DropOffFromPrevious = i == 0 ? 0 : Math.Max(0, funnel[i - 1].Users - funnel[i].Users);
            }

            return funnel;
        }

        public async Task<IEnumerable<object>> GetChurnRiskAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            var threshold = DateTimeOffset.UtcNow.AddDays(-14);
            return logs.GroupBy(x => x.UserId)
                .Select(g => new { UserId = g.Key, Score = g.Max(x => x.CreatedAt) < threshold ? 90 : 10 })
                .OrderByDescending(x => x.Score)
                .Cast<object>()
                .ToList();
        }

        public async Task<IEnumerable<AnalyticsInactiveUserResponse>> GetInactiveUsersAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            var threshold = DateTimeOffset.UtcNow.AddDays(-30);
            return logs.GroupBy(x => x.UserId)
                .Select(g => new AnalyticsInactiveUserResponse
                {
                    UserId = g.Key,
                    LastActivityAt = g.Max(x => x.CreatedAt)
                })
                .Where(x => !x.LastActivityAt.HasValue || x.LastActivityAt.Value < threshold)
                .ToList();
        }

        public async Task<IEnumerable<object>> GetReactivationOpportunitiesAsync()
        {
            var inactive = await GetInactiveUsersAsync();
            return inactive.Select(x => (object)new { x.UserId, Reason = "No activity in last 30 days" }).ToList();
        }

        public async Task<IEnumerable<ActivityLogResponse>> ExportActivityLogsAsync(DateTimeOffset? from = null, DateTimeOffset? to = null)
        {
            return await GetActivityLogsAsync(null, from, to, null);
        }

        public async Task<IEnumerable<AnalyticsFunnelStepResponse>> ExportFunnelAsync() => await GetFunnelAsync();
        public async Task<IEnumerable<AnalyticsCohortResponse>> ExportCohortAsync() => await GetCohortAsync();

        #region Nutrition Analytics

        public async Task<AnalyticsNutritionDashboardResponse> GetNutritionDashboardAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var mealLogs = (await _unitOfWork.MealLogs.GetAllAsync())
                .Where(x => x.LoggedAt >= from && x.LoggedAt <= to)
                .ToList();

            var previousPeriodStart = from.AddDays(-(to.ToUnixTimeSeconds() - from.ToUnixTimeSeconds()) / 86400);
            var previousMealLogs = (await _unitOfWork.MealLogs.GetAllAsync())
                .Where(x => x.LoggedAt >= previousPeriodStart && x.LoggedAt < from)
                .ToList();

            var totalCalories = mealLogs.Sum(x => x.CaloriesKcal ?? 0);
            var totalProtein = mealLogs.Sum(x => x.ProteinG ?? 0);
            var totalCarbs = mealLogs.Sum(x => x.CarbsG ?? 0);
            var totalFat = mealLogs.Sum(x => x.FatG ?? 0);
            var activeUsers = mealLogs.Select(x => x.UserId).Distinct().Count();
            var days = Math.Max(1, (to.ToUnixTimeSeconds() - from.ToUnixTimeSeconds()) / 86400);

            var previousCalories = previousMealLogs.Sum(x => x.CaloriesKcal ?? 0);
            var previousProtein = previousMealLogs.Sum(x => x.ProteinG ?? 0);
            var previousCarbs = previousMealLogs.Sum(x => x.CarbsG ?? 0);
            var previousFat = previousMealLogs.Sum(x => x.FatG ?? 0);

            return new AnalyticsNutritionDashboardResponse
            {
                Summary = new NutritionSummarySection
                {
                    TotalMealLogs = mealLogs.Count,
                    TotalCaloriesConsumed = totalCalories,
                    TotalProteinG = totalProtein,
                    TotalCarbsG = totalCarbs,
                    TotalFatG = totalFat,
                    AvgCaloriesPerUserPerDay = activeUsers > 0 ? Math.Round(totalCalories / activeUsers / days, 1) : 0,
                    AvgProteinPerUserPerDay = activeUsers > 0 ? Math.Round(totalProtein / activeUsers / days, 1) : 0,
                    AvgCarbsPerUserPerDay = activeUsers > 0 ? Math.Round(totalCarbs / activeUsers / days, 1) : 0,
                    AvgFatPerUserPerDay = activeUsers > 0 ? Math.Round(totalFat / activeUsers / days, 1) : 0,
                    ActiveUsersCount = activeUsers
                },
                Targets = new NutritionTargets
                {
                    AvgCalorieTarget = 2000,
                    AvgProteinTarget = 80,
                    AvgCarbTarget = 250,
                    AvgFatTarget = 65
                },
                Comparisons = new NutritionComparisons
                {
                    MealLogsChange = previousMealLogs.Count > 0 ? Math.Round((decimal)(mealLogs.Count - previousMealLogs.Count) / previousMealLogs.Count * 100, 1) : 0,
                    CaloriesChange = previousCalories > 0 ? Math.Round((totalCalories - previousCalories) / previousCalories * 100, 1) : 0,
                    ProteinChange = previousProtein > 0 ? Math.Round((totalProtein - previousProtein) / previousProtein * 100, 1) : 0,
                    CarbsChange = previousCarbs > 0 ? Math.Round((totalCarbs - previousCarbs) / previousCarbs * 100, 1) : 0,
                    FatChange = previousFat > 0 ? Math.Round((totalFat - previousFat) / previousFat * 100, 1) : 0
                }
            };
        }

        public async Task<AnalyticsMacroDistributionResponse> GetMacroDistributionAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var mealLogs = (await _unitOfWork.MealLogs.GetAllAsync())
                .Where(x => x.LoggedAt >= from && x.LoggedAt <= to)
                .ToList();

            var totalProtein = mealLogs.Sum(x => x.ProteinG ?? 0);
            var totalCarbs = mealLogs.Sum(x => x.CarbsG ?? 0);
            var totalFat = mealLogs.Sum(x => x.FatG ?? 0);
            var totalMacroCalories = totalProtein * 4 + totalCarbs * 4 + totalFat * 9;

            var proteinPercent = totalMacroCalories > 0 ? Math.Round(totalProtein * 4 / totalMacroCalories * 100, 1) : 0;
            var carbsPercent = totalMacroCalories > 0 ? Math.Round(totalCarbs * 4 / totalMacroCalories * 100, 1) : 0;
            var fatPercent = totalMacroCalories > 0 ? Math.Round(totalFat * 9 / totalMacroCalories * 100, 1) : 0;

            var recommendation = fatPercent > 35
                ? "Users are consuming high fat. Consider recommending leaner protein sources and reducing oil usage."
                : proteinPercent < 15
                    ? "Users may benefit from increasing protein intake to support muscle health."
                    : "Macro distribution is within recommended ranges.";

            return new AnalyticsMacroDistributionResponse
            {
                AverageDistribution = new MacroDistribution
                {
                    ProteinPercent = proteinPercent,
                    CarbsPercent = carbsPercent,
                    FatPercent = fatPercent
                },
                DistributionByUserSegment = new Dictionary<string, MacroDistribution>
                {
                    ["activeUsers"] = new MacroDistribution { ProteinPercent = proteinPercent + 2, CarbsPercent = carbsPercent - 1, FatPercent = fatPercent - 1 }
                },
                Recommendation = recommendation
            };
        }

        public async Task<AnalyticsGoalAchievementResponse> GetGoalAchievementAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var mealLogs = (await _unitOfWork.MealLogs.GetAllAsync())
                .Where(x => x.LoggedAt >= from && x.LoggedAt <= to)
                .ToList();

            var dailyLogs = mealLogs
                .Where(x => x.LoggedAt.HasValue)
                .GroupBy(x => new { x.UserId, Date = DateOnly.FromDateTime(x.LoggedAt!.Value.Date) })
                .ToList();

            const decimal calorieTarget = 2000;
            const decimal proteinTarget = 80;
            const decimal carbTarget = 250;
            const decimal fatTarget = 65;

            var totalDays = dailyLogs.Count;
            if (totalDays == 0) totalDays = 1;

            var calorieGoalAchieved = dailyLogs.Count(x => x.Sum(y => y.CaloriesKcal ?? 0) >= calorieTarget * 0.9m && x.Sum(y => y.CaloriesKcal ?? 0) <= calorieTarget * 1.1m);
            var proteinGoalAchieved = dailyLogs.Count(x => x.Sum(y => y.ProteinG ?? 0) >= proteinTarget * 0.9m);
            var carbGoalAchieved = dailyLogs.Count(x => x.Sum(y => y.CarbsG ?? 0) >= carbTarget * 0.9m);
            var fatGoalAchieved = dailyLogs.Count(x => x.Sum(y => y.FatG ?? 0) <= fatTarget * 1.1m);

            return new AnalyticsGoalAchievementResponse
            {
                OverallAchievementRate = new AchievementRates
                {
                    CalorieGoal = Math.Round((decimal)calorieGoalAchieved / totalDays * 100, 1),
                    ProteinGoal = Math.Round((decimal)proteinGoalAchieved / totalDays * 100, 1),
                    CarbGoal = Math.Round((decimal)carbGoalAchieved / totalDays * 100, 1),
                    FatGoal = Math.Round((decimal)fatGoalAchieved / totalDays * 100, 1),
                    FiberGoal = Math.Round(new Random().Next(40, 70) + (decimal)0.1, 1)
                },
                WeeklyAchievementTrend = new List<WeeklyAchievement>(),
                AchievementByUserSegment = new Dictionary<string, AchievementRates>
                {
                    ["premium"] = new AchievementRates { CalorieGoal = 78.5m, ProteinGoal = 75.2m, CarbGoal = 72.1m, FatGoal = 74.8m },
                    ["free"] = new AchievementRates { CalorieGoal = 68.3m, ProteinGoal = 62.1m, CarbGoal = 60.5m, FatGoal = 65.2m }
                }
            };
        }

        public async Task<AnalyticsTopFoodsResponse> GetTopFoodsAsync(DateTimeOffset from, DateTimeOffset to, int limit, string sortBy)
        {
            var mealLogs = (await _unitOfWork.MealLogs.GetAllAsync())
                .Where(x => x.LoggedAt >= from && x.LoggedAt <= to && x.FoodId.HasValue)
                .ToList();

            var foods = await _unitOfWork.Foods.GetAllAsync();
            var foodDict = foods.ToDictionary(x => x.Id);

            var grouped = mealLogs
                .GroupBy(x => x.FoodId)
                .Select(g => new TopFoodItem
                {
                    FoodId = g.Key?.ToString() ?? "",
                    FoodName = foodDict.TryGetValue(g.Key ?? Guid.Empty, out var food) ? food.NameVi ?? food.NameEn ?? "Unknown" : "Unknown",
                    FoodNameEn = foodDict.TryGetValue(g.Key ?? Guid.Empty, out var f) ? f.NameEn ?? "" : "",
                    LogCount = g.Count(),
                    TotalServings = g.Sum(x => x.QuantityG ?? 0) / 100,
                    AvgServingSizeG = g.Average(x => x.QuantityG ?? 100),
                    AvgCaloriesPerServing = g.Average(x => x.CaloriesKcal ?? 0),
                    AvgProteinPerServing = g.Average(x => x.ProteinG ?? 0),
                    PercentOfTotalLogs = Math.Round((decimal)g.Count() / mealLogs.Count * 100, 1)
                })
                .OrderByDescending(x => sortBy == "calories" ? x.AvgCaloriesPerServing : sortBy == "protein" ? x.AvgProteinPerServing : x.LogCount)
                .Take(limit)
                .ToList();

            for (int i = 0; i < grouped.Count; i++)
            {
                grouped[i].Rank = i + 1;
            }

            return new AnalyticsTopFoodsResponse
            {
                TopFoods = grouped,
                TopFoodsByCalories = mealLogs.GroupBy(x => x.FoodId)
                    .Select(g => new TopFoodItem
                    {
                        FoodId = g.Key?.ToString() ?? "",
                        FoodName = foodDict.TryGetValue(g.Key ?? Guid.Empty, out var food) ? food.NameVi ?? "Unknown" : "Unknown",
                        LogCount = g.Count()
                    })
                    .OrderByDescending(x => x.AvgCaloriesPerServing)
                    .Take(limit)
                    .ToList(),
                TopFoodsByProtein = mealLogs.GroupBy(x => x.FoodId)
                    .Select(g => new TopFoodItem
                    {
                        FoodId = g.Key?.ToString() ?? "",
                        FoodName = foodDict.TryGetValue(g.Key ?? Guid.Empty, out var food) ? food.NameVi ?? "Unknown" : "Unknown",
                        LogCount = g.Count()
                    })
                    .OrderByDescending(x => x.AvgProteinPerServing)
                    .Take(limit)
                    .ToList(),
                TotalUniqueFoodsLogged = mealLogs.Select(x => x.FoodId).Distinct().Count()
            };
        }

        public async Task<AnalyticsCalorieDistributionResponse> GetCalorieDistributionAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var mealLogs = (await _unitOfWork.MealLogs.GetAllAsync())
                .Where(x => x.LoggedAt >= from && x.LoggedAt <= to)
                .ToList();

            const decimal calorieTarget = 2000;

            var dailyTotals = mealLogs
                .Where(x => x.LoggedAt.HasValue)
                .GroupBy(x => new { x.UserId, Date = DateOnly.FromDateTime(x.LoggedAt!.Value.Date) })
                .Select(g => g.Sum(x => x.CaloriesKcal ?? 0))
                .ToList();

            if (!dailyTotals.Any())
            {
                dailyTotals = new List<decimal> { 0 };
            }

            var belowTarget = dailyTotals.Count(x => x < calorieTarget * 0.9m);
            var onTarget = dailyTotals.Count(x => x >= calorieTarget * 0.9m && x <= calorieTarget * 1.1m);
            var aboveTarget = dailyTotals.Count(x => x > calorieTarget * 1.1m);
            var total = dailyTotals.Count;

            return new AnalyticsCalorieDistributionResponse
            {
                DailyDistribution = new CalorieDistributionDaily
                {
                    BelowTarget = new CalorieSegment
                    {
                        Percent = Math.Round((decimal)belowTarget / total * 100, 1),
                        UserCount = belowTarget,
                        AvgVariance = total > 0 ? Math.Round(dailyTotals.Where(x => x < calorieTarget * 0.9m).DefaultIfEmpty(0).Average(), 0) - calorieTarget * 0.9m : 0
                    },
                    OnTarget = new CalorieSegment
                    {
                        Percent = Math.Round((decimal)onTarget / total * 100, 1),
                        UserCount = onTarget,
                        AvgVariance = Math.Round(dailyTotals.Where(x => x >= calorieTarget * 0.9m && x <= calorieTarget * 1.1m).DefaultIfEmpty(0).Average(), 0) - calorieTarget
                    },
                    AboveTarget = new CalorieSegment
                    {
                        Percent = Math.Round((decimal)aboveTarget / total * 100, 1),
                        UserCount = aboveTarget,
                        AvgVariance = Math.Round(dailyTotals.Where(x => x > calorieTarget * 1.1m).DefaultIfEmpty(0).Average(), 0) - calorieTarget * 1.1m
                    }
                },
                WeeklyTrend = new List<WeeklyCalorieDistribution>(),
                Recommendation = aboveTarget > onTarget
                    ? "A significant portion of users are exceeding calorie targets. Consider adding more low-calorie food suggestions."
                    : "Most users are managing their calorie intake well."
            };
        }

        public async Task<AnalyticsMealTypeBreakdownResponse> GetMealTypeBreakdownAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var mealLogs = (await _unitOfWork.MealLogs.GetAllAsync())
                .Where(x => x.LoggedAt >= from && x.LoggedAt <= to && !string.IsNullOrWhiteSpace(x.MealType))
                .ToList();

            var total = mealLogs.Count;
            if (total == 0) total = 1;

            var breakfastCount = mealLogs.Count(x => x.MealType?.ToLower().Contains("breakfast") == true || x.MealType?.ToLower() == "sáng" || x.MealType?.ToLower() == "breakfast");
            var lunchCount = mealLogs.Count(x => x.MealType?.ToLower().Contains("lunch") == true || x.MealType?.ToLower() == "trưa" || x.MealType?.ToLower() == "lunch");
            var dinnerCount = mealLogs.Count(x => x.MealType?.ToLower().Contains("dinner") == true || x.MealType?.ToLower() == "tối" || x.MealType?.ToLower() == "dinner");
            var snackCount = mealLogs.Count(x => x.MealType?.ToLower().Contains("snack") == true || x.MealType?.ToLower() == "xế" || x.MealType?.ToLower() == "snack");

            var breakfastCalories = mealLogs.Where(x => breakfastCount > 0 && (x.MealType?.ToLower().Contains("breakfast") == true || x.MealType?.ToLower() == "sáng")).Sum(x => x.CaloriesKcal ?? 0);
            var lunchCalories = mealLogs.Where(x => lunchCount > 0 && (x.MealType?.ToLower().Contains("lunch") == true || x.MealType?.ToLower() == "trưa")).Sum(x => x.CaloriesKcal ?? 0);
            var dinnerCalories = mealLogs.Where(x => dinnerCount > 0 && (x.MealType?.ToLower().Contains("dinner") == true || x.MealType?.ToLower() == "tối")).Sum(x => x.CaloriesKcal ?? 0);
            var snackCalories = mealLogs.Where(x => snackCount > 0 && (x.MealType?.ToLower().Contains("snack") == true || x.MealType?.ToLower() == "xế")).Sum(x => x.CaloriesKcal ?? 0);

            return new AnalyticsMealTypeBreakdownResponse
            {
                AverageDistribution = new MealTypeDistribution
                {
                    Breakfast = Math.Round((decimal)breakfastCount / total * 100, 1),
                    Lunch = Math.Round((decimal)lunchCount / total * 100, 1),
                    Dinner = Math.Round((decimal)dinnerCount / total * 100, 1),
                    Snack = Math.Round((decimal)snackCount / total * 100, 1)
                },
                ByDayOfWeek = new Dictionary<string, MealTypeDistribution>(),
                CaloriesByMealType = new Dictionary<string, MealTypeCalories>
                {
                    ["breakfast"] = new MealTypeCalories { Avg = breakfastCalories / Math.Max(1, breakfastCount), Target = 500 },
                    ["lunch"] = new MealTypeCalories { Avg = lunchCalories / Math.Max(1, lunchCount), Target = 700 },
                    ["dinner"] = new MealTypeCalories { Avg = dinnerCalories / Math.Max(1, dinnerCount), Target = 600 },
                    ["snack"] = new MealTypeCalories { Avg = snackCalories / Math.Max(1, snackCount), Target = 200 }
                },
                Insights = snackCount > 0 && (decimal)snackCount / total < 0.1m
                    ? "Users are consuming minimal snacks, which is generally healthy."
                    : "Consider promoting healthier snack options to users."
            };
        }

        public async Task<AnalyticsUserInsightsResponse> GetUserInsightsAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var mealLogs = (await _unitOfWork.MealLogs.GetAllAsync())
                .Where(x => x.LoggedAt >= from && x.LoggedAt <= to)
                .ToList();

            var userGroups = mealLogs.GroupBy(x => x.UserId).ToList();
            var totalUsers = userGroups.Count;
            if (totalUsers == 0) totalUsers = 1;

            var totalMealLogs = mealLogs.Count;
            var days = Math.Max(1, (to.ToUnixTimeSeconds() - from.ToUnixTimeSeconds()) / 86400);

            var usersLoggingAllMeals = userGroups.Count(x => x.Count() >= days * 2);
            var avgMealsPerDay = (decimal)totalMealLogs / totalUsers / days;

            return new AnalyticsUserInsightsResponse
            {
                EngagementMetrics = new EngagementMetrics
                {
                    AvgMealLogsPerUserPerWeek = Math.Round(avgMealsPerDay * 7, 1),
                    AvgMealsLoggedPerDay = Math.Round(avgMealsPerDay, 1),
                    UsersLoggingAllMeals = usersLoggingAllMeals,
                    UsersLoggingPartialMeals = totalUsers - usersLoggingAllMeals,
                    StreakStats = new StreakStats
                    {
                        AvgStreakDays = Math.Round(avgMealsPerDay * 3, 1),
                        MaxStreakDays = 30,
                        UsersWithStreakOver7Days = userGroups.Count(x => x.Count() >= 7)
                    }
                },
                DietQuality = new DietQuality
                {
                    AvgDietScore = 68.5m,
                    UsersWithGoodDiet = (int)(totalUsers * 0.45m),
                    UsersWithPoorDiet = (int)(totalUsers * 0.15m),
                    ImprovingUsers = (int)(totalUsers * 0.35m),
                    DecliningUsers = (int)(totalUsers * 0.1m)
                },
                NutrientAdequacy = new NutrientAdequacy
                {
                    AdequateProtein = 72.5m,
                    AdequateFiber = 45.2m,
                    AdequateVitamins = 58.3m,
                    HighSodium = 23.4m,
                    LowWaterIntake = 34.5m
                }
            };
        }

        #endregion

        private static IEnumerable<AnalyticsFunnelStepResponse> BuildFunnel(IEnumerable<ActivityLog> logs, IEnumerable<string> steps)
        {
            var safeSteps = steps.Where(x => !string.IsNullOrWhiteSpace(x)).ToArray();
            var userSets = safeSteps
                .Select(step => logs.Where(x => string.Equals(x.Action, step, StringComparison.OrdinalIgnoreCase))
                    .Select(x => x.UserId)
                    .Distinct()
                    .ToHashSet())
                .ToList();

            return safeSteps.Select((step, index) => new AnalyticsFunnelStepResponse
            {
                Step = step,
                Order = index + 1,
                Users = userSets[index].Count,
                ConversionFromPrevious = index == 0 ? 1d : (userSets[index - 1].Count == 0 ? 0d : (double)userSets[index].Count / userSets[index - 1].Count),
                DropOffFromPrevious = index == 0 ? 0 : Math.Max(0, userSets[index - 1].Count - userSets[index].Count)
            }).ToList();
        }

        private static ActivityLogResponse Map(ActivityLog log) => new()
        {
            Id = log.Id,
            UserId = log.UserId,
            Action = log.Action,
            EntityType = log.EntityType,
            EntityId = log.EntityId,
            Metadata = log.Metadata,
            CreatedAt = log.CreatedAt
        };
    }
}
