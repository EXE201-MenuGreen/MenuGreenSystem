using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.BusinessLogicLayer.Helpers;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class NutritionTrackingService : INutritionTrackingService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INutritionSnapshotService _nutritionSnapshotService;
        private readonly IRecipeService _recipeService;
        private readonly IPortionConverterService _portionConverterService;
        private readonly ICacheService _cache;

        public NutritionTrackingService(
            IUnitOfWork unitOfWork,
            INutritionSnapshotService nutritionSnapshotService,
            IRecipeService recipeService,
            IPortionConverterService portionConverterService,
            ICacheService cache)
        {
            _unitOfWork = unitOfWork;
            _nutritionSnapshotService = nutritionSnapshotService;
            _recipeService = recipeService;
            _portionConverterService = portionConverterService;
            _cache = cache;
        }

        public async Task<MealLogResponse> CreateMealLogAsync(Guid userId, MealLogUpsertRequest request)
        {
            var entity = await BuildMealLogAsync(userId, request);
            await _unitOfWork.MealLogs.AddAsync(entity);
            await _unitOfWork.CompleteAsync();
            await SyncSnapshotForLogAsync(userId, entity);
            var response = await MapMealLogAsync(entity);
            ApplyRequestDisplayPortion(response, request);
            return response;
        }

        public async Task<MealLogResponse> GetMealLogAsync(Guid userId, Guid mealLogId)
        {
            var entity = await GetOwnedMealLogAsync(userId, mealLogId);
            return await MapMealLogAsync(entity);
        }

        public async Task<MealLogResponse> UpdateMealLogAsync(Guid userId, Guid mealLogId, MealLogUpsertRequest request)
        {
            var entity = await GetOwnedMealLogAsync(userId, mealLogId);
            await ApplyMealLogRequestAsync(entity, request);
            _unitOfWork.MealLogs.Update(entity);
            await _unitOfWork.CompleteAsync();
            await SyncSnapshotForLogAsync(userId, entity);
            var response = await MapMealLogAsync(entity);
            ApplyRequestDisplayPortion(response, request);
            return response;
        }

        public async Task DeleteMealLogAsync(Guid userId, Guid mealLogId)
        {
            var entity = await GetOwnedMealLogAsync(userId, mealLogId);
            var logDate = entity.LoggedAt.HasValue
                ? DateOnly.FromDateTime(entity.LoggedAt.Value)
                : DateOnly.FromDateTime(DateTime.UtcNow);
            _unitOfWork.MealLogs.Remove(entity);
            await _unitOfWork.CompleteAsync();
            await _nutritionSnapshotService.SyncDailySnapshotAsync(userId, logDate);
        }

        public async Task<MealDaySummaryResponse> GetDailySummaryAsync(Guid userId, DateOnly date)
        {
            var startOfDay = date.ToDateTime(TimeOnly.MinValue);
            var endOfDay = date.ToDateTime(TimeOnly.MaxValue);
            var logs = await _unitOfWork.MealLogs.FindAsync(x => 
                x.UserId == userId && 
                x.LoggedAt.HasValue && 
                x.LoggedAt.Value >= startOfDay && 
                x.LoggedAt.Value <= endOfDay);
            await _nutritionSnapshotService.SyncDailySnapshotAsync(userId, date);
            return await BuildDailySummaryAsync(userId, date, logs.ToList());
        }

        public async Task<NutritionDashboardResponse> GetDashboardAsync(Guid userId, string range, DateOnly? startDate, DateOnly? endDate)
        {
            var (from, to) = ResolveRange(range, startDate, endDate);
            var fromDateTime = from.ToDateTime(TimeOnly.MinValue);
            var toDateTime = to.ToDateTime(TimeOnly.MaxValue);

            var logs = (await _unitOfWork.MealLogs.FindAsync(
                x => x.UserId == userId && x.LoggedAt.HasValue
                    && x.LoggedAt.Value >= fromDateTime
                    && x.LoggedAt.Value <= toDateTime)).ToList();

            var logDates = logs
                .Where(x => x.LoggedAt.HasValue)
                .Select(x => DateOnly.FromDateTime(x.LoggedAt!.Value))
                .Distinct()
                .ToList();

            // Sync sequentially to keep shared DbContext single-threaded and prevent InvalidOperationException
            if (logDates.Any())
            {
                foreach (var day in logDates)
                {
                    await _nutritionSnapshotService.SyncDailySnapshotAsync(userId, day);
                }
            }

            var days = await BuildRangeSummariesAsync(userId, from, to, logs);
            var weightFromDateTime = from.ToDateTime(TimeOnly.MinValue);
            var weightToDateTime = to.ToDateTime(TimeOnly.MaxValue);
            var weightLogs = await _unitOfWork.WeightLogs.FindAsync(
                x => x.UserId == userId && x.RecordedAt.HasValue
                    && x.RecordedAt.Value >= weightFromDateTime
                    && x.RecordedAt.Value <= weightToDateTime);

            return new NutritionDashboardResponse
            {
                Range = range,
                Days = days,
                WeightLogs = weightLogs.OrderBy(x => x.RecordedAt).Select(Map).ToList()
            };
        }

        public async Task<WeightLogResponse> CreateWeightLogAsync(Guid userId, WeightLogUpsertRequest request)
        {
            var entity = new WeightLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                WeightKg = request.WeightKg,
                BodyFatPercent = request.BodyFatPercent,
                RecordedAt = EnsureUtc(request.RecordedAt ?? DateTime.UtcNow)
            };

            await _unitOfWork.WeightLogs.AddAsync(entity);
            await _unitOfWork.CompleteAsync();

            // Keep HealthProfile.WeightKg + BodyFatPercent in sync with the
            // latest log so any view that reads HealthProfile (Home,
            // GymGoals, recalibration, daily targets) sees the user's
            // current weight without requiring a second manual update.
            await SyncHealthProfileFromLatestWeightAsync(userId);

            return Map(entity);
        }

        public async Task<WeightLogResponse> UpdateWeightLogAsync(Guid userId, Guid weightLogId, WeightLogUpsertRequest request)
        {
            var entity = await GetOwnedWeightLogAsync(userId, weightLogId);
            entity.WeightKg = request.WeightKg;
            entity.BodyFatPercent = request.BodyFatPercent;
            entity.RecordedAt = EnsureUtc(request.RecordedAt ?? entity.RecordedAt);
            _unitOfWork.WeightLogs.Update(entity);
            await _unitOfWork.CompleteAsync();

            // After editing a historical log the "latest" weight log may
            // have changed. Refresh HealthProfile so the UI reflects the
            // truly most-recent value, not the one we just wrote.
            await SyncHealthProfileFromLatestWeightAsync(userId);
            return Map(entity);
        }

        /// <summary>
        /// Mirror the user's most-recent <see cref="WeightLog"/> values into
        /// their <see cref="HealthProfile"/> and recalculate BMI, BMR, TDEE
        /// and macro targets. The existing calorie target is preserved so a
        /// measurement update cannot silently perform goal recalibration.
        /// </summary>
        private async Task SyncHealthProfileFromLatestWeightAsync(Guid userId)
        {
            var latest = (await _unitOfWork.WeightLogs.FindAsync(
                x => x.UserId == userId && x.WeightKg.HasValue))
                .OrderByDescending(x => x.RecordedAt)
                .FirstOrDefault();

            if (latest == null || !latest.WeightKg.HasValue) return;

            var healthProfile = (await _unitOfWork.HealthProfiles.FindAsync(
                x => x.UserId == userId))
                .FirstOrDefault();

            if (healthProfile == null)
            {
                // No profile yet — nothing to sync against. The profile
                // will be created the next time the user updates it.
                return;
            }

            // Only overwrite when the stored value differs to avoid
            // churn in UpdatedAt and to prevent stomping a value the
            // user entered elsewhere that is intentionally different.
            if (healthProfile.WeightKg != latest.WeightKg)
            {
                healthProfile.WeightKg = latest.WeightKg;
            }
            if (latest.BodyFatPercent.HasValue &&
                healthProfile.BodyFatPercent != latest.BodyFatPercent)
            {
                healthProfile.BodyFatPercent = latest.BodyFatPercent;
            }

            var userProfile = await _unitOfWork.Profiles.GetByIdAsync(userId);
            var currentTargetCalories = healthProfile.TargetCalories;
            HealthProfileMetricsCalculator.Apply(
                healthProfile,
                userProfile?.Gender,
                userProfile?.DateOfBirth,
                currentTargetCalories);

            healthProfile.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.HealthProfiles.Update(healthProfile);
            await _unitOfWork.CompleteAsync();

            // HealthProfile responses are cached behind
            // UserHealthTargets. Invalidate so the next read recomputes.
            await _cache.RemoveAsync(CacheKeys.UserHealthTargets(userId));
        }

        public async Task DeleteWeightLogAsync(Guid userId, Guid weightLogId)
        {
            var entity = await GetOwnedWeightLogAsync(userId, weightLogId);
            _unitOfWork.WeightLogs.Remove(entity);
            await _unitOfWork.CompleteAsync();
            await SyncHealthProfileFromLatestWeightAsync(userId);
        }

        public async Task<MealLogListResponse> GetMealLogsAsync(Guid userId, int page = 1, int pageSize = 20)
        {
            var query = await _unitOfWork.MealLogs.FindAsync(x => x.UserId == userId);
            var totalCount = query.Count();
            var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
            
            var pagedLogs = query
                .OrderByDescending(x => x.LoggedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            var mappedLogs = await MapMealLogsAsync(pagedLogs);

            return new MealLogListResponse
            {
                MealLogs = mappedLogs,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = totalPages
            };
        }

        public async Task<MealLogResponse> GetMealLogByIdAsync(Guid userId, Guid mealLogId)
        {
            var entity = await GetOwnedMealLogAsync(userId, mealLogId);
            return await MapMealLogAsync(entity);
        }

        public async Task<MealLogListResponse> GetMealLogsByRangeAsync(Guid userId, DateOnly startDate, DateOnly endDate)
        {
            var startDateTime = startDate.ToDateTime(TimeOnly.MinValue);
            var endDateTime = endDate.ToDateTime(TimeOnly.MaxValue);
            var logs = await _unitOfWork.MealLogs.FindAsync(
                x => x.UserId == userId && 
                x.LoggedAt.HasValue && 
                x.LoggedAt.Value >= startDateTime && 
                x.LoggedAt.Value <= endDateTime);

            var logList = logs.OrderByDescending(x => x.LoggedAt).ToList();
            var mappedLogs = await MapMealLogsAsync(logList);

            return new MealLogListResponse
            {
                MealLogs = mappedLogs,
                TotalCount = logList.Count,
                Page = 1,
                PageSize = logList.Count,
                TotalPages = 1
            };
        }

        public async Task<NutritionSummaryResponse> GetNutritionSummaryAsync(Guid userId, string period = "day", DateOnly? date = null)
        {
            var (startDate, endDate) = ResolvePeriod(period, date);
            var startDateTime = startDate.ToDateTime(TimeOnly.MinValue);
            var endDateTime = endDate.ToDateTime(TimeOnly.MaxValue);
            
            var logs = await _unitOfWork.MealLogs.FindAsync(
                x => x.UserId == userId && 
                x.LoggedAt.HasValue && 
                x.LoggedAt.Value >= startDateTime && 
                x.LoggedAt.Value <= endDateTime);

            var logList = logs.ToList();
            var totalCalories = logList.Sum(x => x.CaloriesKcal ?? 0);
            var totalProtein = logList.Sum(x => x.ProteinG ?? 0);
            var totalCarbs = logList.Sum(x => x.CarbsG ?? 0);
            var totalFat = logList.Sum(x => x.FatG ?? 0);

            var dayCount = (endDate.DayNumber - startDate.DayNumber) + 1;

            return new NutritionSummaryResponse
            {
                Period = period,
                StartDate = startDate,
                EndDate = endDate,
                TotalCaloriesKcal = totalCalories,
                TotalProteinG = totalProtein,
                TotalCarbsG = totalCarbs,
                TotalFatG = totalFat,
                TotalMealLogs = logList.Count,
                AvgCaloriesPerDay = dayCount > 0 ? Math.Round(totalCalories / dayCount, 2) : 0,
                AvgProteinPerDay = dayCount > 0 ? Math.Round(totalProtein / dayCount, 2) : 0,
                AvgCarbsPerDay = dayCount > 0 ? Math.Round(totalCarbs / dayCount, 2) : 0,
                AvgFatPerDay = dayCount > 0 ? Math.Round(totalFat / dayCount, 2) : 0
            };
        }

        public async Task<NutritionTrendResponse> GetNutritionTrendsAsync(Guid userId, DateOnly startDate, DateOnly endDate)
        {
            var startDateTime = startDate.ToDateTime(TimeOnly.MinValue);
            var endDateTime = endDate.ToDateTime(TimeOnly.MaxValue);
            var logs = await _unitOfWork.MealLogs.FindAsync(
                x => x.UserId == userId && 
                x.LoggedAt.HasValue && 
                x.LoggedAt.Value >= startDateTime && 
                x.LoggedAt.Value <= endDateTime);

            var logList = logs.ToList();
            var dailyData = new List<DailyNutritionPoint>();

            for (var day = startDate; day <= endDate; day = day.AddDays(1))
            {
                var dayLogs = logList.Where(x => x.LoggedAt.HasValue && DateOnly.FromDateTime(x.LoggedAt.Value) == day).ToList();
                
                dailyData.Add(new DailyNutritionPoint
                {
                    Date = day,
                    CaloriesKcal = dayLogs.Sum(x => x.CaloriesKcal ?? 0),
                    ProteinG = dayLogs.Sum(x => x.ProteinG ?? 0),
                    CarbsG = dayLogs.Sum(x => x.CarbsG ?? 0),
                    FatG = dayLogs.Sum(x => x.FatG ?? 0),
                    MealCount = dayLogs.Count
                });
            }

            return new NutritionTrendResponse
            {
                StartDate = startDate,
                EndDate = endDate,
                DailyData = dailyData
            };
        }

        public async Task<WeightLogListResponse> GetWeightLogsAsync(Guid userId, int page = 1, int pageSize = 20)
        {
            var allLogs = await _unitOfWork.WeightLogs.FindAsync(x => x.UserId == userId);
            var totalCount = allLogs.Count();
            var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
            
            var pagedLogs = allLogs
                .OrderByDescending(x => x.RecordedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(Map)
                .ToList();

            return new WeightLogListResponse
            {
                WeightLogs = pagedLogs,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = totalPages
            };
        }

        public async Task<WeightLogResponse> GetWeightLogByIdAsync(Guid userId, Guid weightLogId)
        {
            var entity = await GetOwnedWeightLogAsync(userId, weightLogId);
            return Map(entity);
        }

        public async Task<WeightTrendResponse> GetWeightTrendAsync(Guid userId, DateOnly startDate, DateOnly endDate)
        {
            var startDateTime = startDate.ToDateTime(TimeOnly.MinValue);
            var endDateTime = endDate.ToDateTime(TimeOnly.MaxValue);
            var logs = await _unitOfWork.WeightLogs.FindAsync(
                x => x.UserId == userId && 
                x.RecordedAt.HasValue && 
                x.RecordedAt.Value >= startDateTime && 
                x.RecordedAt.Value <= endDateTime);

            var logList = logs.OrderBy(x => x.RecordedAt).ToList();
            
            var weightData = logList
                .Where(x => x.RecordedAt.HasValue && x.WeightKg.HasValue)
                .Select(x => new WeightPoint
                {
                    Date = DateOnly.FromDateTime(x.RecordedAt!.Value),
                    WeightKg = x.WeightKg!.Value,
                    BodyFatPercent = x.BodyFatPercent
                })
                .ToList();

            decimal? initialWeight = weightData.FirstOrDefault()?.WeightKg;
            decimal? latestWeight = weightData.LastOrDefault()?.WeightKg;
            decimal? weightChange = initialWeight.HasValue && latestWeight.HasValue 
                ? Math.Round(latestWeight.Value - initialWeight.Value, 2) 
                : null;
            decimal? averageWeight = weightData.Count > 0 
                ? Math.Round(weightData.Average(x => x.WeightKg), 2) 
                : null;

            return new WeightTrendResponse
            {
                StartDate = startDate,
                EndDate = endDate,
                InitialWeightKg = initialWeight,
                LatestWeightKg = latestWeight,
                WeightChangeKg = weightChange,
                AverageWeightKg = averageWeight,
                WeightData = weightData
            };
        }

        private static (DateOnly startDate, DateOnly endDate) ResolvePeriod(string period, DateOnly? date)
        {
            var today = date ?? DateOnly.FromDateTime(DateTime.UtcNow);
            
            return period.Trim().ToLower() switch
            {
                "week" => (today.AddDays(-6), today),
                "month" => (new DateOnly(today.Year, today.Month, 1), today),
                _ => (today, today) // "day" or default
            };
        }

        private async Task<MealLog> BuildMealLogAsync(Guid userId, MealLogUpsertRequest request)
        {
            var entity = new MealLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                FoodId = request.FoodId,
                RecipeId = request.RecipeId,
                MealType = request.MealType,
                CustomName = request.CustomName,
                Notes = request.Notes,
                LoggedAt = EnsureUtc(request.LoggedAt ?? DateTime.UtcNow),
                MealPlanItemId = request.MealPlanItemId,
                IsFromMealPlan = request.MealPlanItemId.HasValue
            };

            await ApplyMealLogRequestAsync(entity, request);
            return entity;
        }

        private async Task ApplyMealLogRequestAsync(MealLog entity, MealLogUpsertRequest request)
        {
            entity.FoodId = request.FoodId;
            entity.RecipeId = request.RecipeId;
            entity.MealType = request.MealType;
            entity.CustomName = request.CustomName;
            var quantityG = await ResolveQuantityGAsync(request, entity.UserId);
            entity.QuantityG = quantityG;
            entity.Notes = request.Notes;
            entity.LoggedAt = EnsureUtc(request.LoggedAt ?? entity.LoggedAt ?? DateTime.UtcNow);
            if (request.MealPlanItemId.HasValue)
            {
                entity.MealPlanItemId = request.MealPlanItemId;
                entity.IsFromMealPlan = true;
            }

            if (request.FoodId.HasValue)
            {
                var food = await _unitOfWork.Foods.GetByIdAsync(request.FoodId.Value) ?? throw new Exception("Food not found.");
                ApplyNutritionFromFood(entity, food, quantityG);
                entity.SourceType = "Food";
                return;
            }

            if (request.RecipeId.HasValue)
            {
                _ = await _unitOfWork.Recipes.GetByIdAsync(request.RecipeId.Value) ?? throw new Exception("Recipe not found.");
                await ApplyNutritionFromRecipeAsync(entity, request.RecipeId.Value, quantityG);
                entity.SourceType = "Recipe";
                return;
            }

            if (request.CaloriesKcal.HasValue || request.ProteinG.HasValue || request.CarbsG.HasValue || request.FatG.HasValue)
            {
                entity.CaloriesKcal = request.CaloriesKcal;
                entity.ProteinG = request.ProteinG;
                entity.CarbsG = request.CarbsG;
                entity.FatG = request.FatG;
                entity.SourceType = string.IsNullOrWhiteSpace(request.CustomName)
                    ? "Manual"
                    : "AiScan";
                return;
            }

            throw new Exception("FoodId or RecipeId or custom nutritional values are required.");
        }

        private static void ApplyNutritionFromFood(MealLog entity, Food food, decimal quantityG)
        {
            var ratio = quantityG / 100m;
            entity.CaloriesKcal = Multiply(food.CaloriesKcal, ratio);
            entity.ProteinG = Multiply(food.ProteinG, ratio);
            entity.CarbsG = Multiply(food.CarbsG, ratio);
            entity.FatG = Multiply(food.FatG, ratio);
        }

        private async Task ApplyNutritionFromRecipeAsync(MealLog entity, Guid recipeId, decimal quantityG)
        {
            var nutrition = await _recipeService.GetNutritionAsync(recipeId);
            var ratio = quantityG / 100m;
            entity.CaloriesKcal = Math.Round(nutrition.CaloriesKcal * ratio, 2);
            entity.ProteinG = Math.Round(nutrition.ProteinG * ratio, 2);
            entity.CarbsG = Math.Round(nutrition.CarbsG * ratio, 2);
            entity.FatG = Math.Round(nutrition.FatG * ratio, 2);
        }

        private static decimal? Multiply(decimal? value, decimal ratio) => value.HasValue ? Math.Round(value.Value * ratio, 2) : null;

        private async Task<MealLog> GetOwnedMealLogAsync(Guid userId, Guid mealLogId)
        {
            var entity = await _unitOfWork.MealLogs.GetByIdAsync(mealLogId) ?? throw new Exception("Meal log not found.");
            if (entity.UserId != userId) throw new Exception("Forbidden.");
            return entity;
        }

        private async Task<WeightLog> GetOwnedWeightLogAsync(Guid userId, Guid weightLogId)
        {
            var entity = await _unitOfWork.WeightLogs.GetByIdAsync(weightLogId) ?? throw new Exception("Weight log not found.");
            if (entity.UserId != userId) throw new Exception("Forbidden.");
            return entity;
        }

        private async Task<MealDaySummaryResponse> BuildDailySummaryAsync(Guid userId, DateOnly date, List<MealLog> logs)
        {
            var targetContext = await BuildNutritionTargetContextAsync(userId, date, date);
            return await BuildDailySummaryAsync(userId, date, logs, targetContext);
        }

        private async Task<MealDaySummaryResponse> BuildDailySummaryAsync(
            Guid userId,
            DateOnly date,
            List<MealLog> logs,
            NutritionTargetContext targetContext)
        {
            var targets = ResolveNutritionTargets(targetContext, date);
            var targetCalories = targets.Calories;
            var targetProtein = targets.ProteinG;
            var targetCarbs = targets.CarbsG;
            var targetFat = targets.FatG;

            var totalCalories = logs.Sum(x => x.CaloriesKcal ?? 0);
            var totalProtein = logs.Sum(x => x.ProteinG ?? 0);
            var totalCarbs = logs.Sum(x => x.CarbsG ?? 0);
            var totalFat = logs.Sum(x => x.FatG ?? 0);

            decimal? goalCompletionPercent = null;
            var hasSnapshot = false;
            var snapshots = await _unitOfWork.NutritionSnapshots.FindAsync(
                x => x.UserId == userId && x.SnapshotDate == date);
            var snapshot = snapshots.FirstOrDefault();
            if (snapshot != null && !targets.UsesGymConfiguration)
            {
                hasSnapshot = true;
                goalCompletionPercent = snapshot.GoalCompletionPercent;
            }
            else
            {
                hasSnapshot = snapshot != null;
                if (targetCalories > 0)
                {
                    goalCompletionPercent = Math.Round(totalCalories / targetCalories * 100m, 2);
                }
            }

            var warningMessages = NutritionWarningsBuilder.Build(
                totalCalories, targetCalories,
                totalProtein, targetProtein,
                totalCarbs, targetCarbs,
                totalFat, targetFat);

            return new MealDaySummaryResponse
            {
                Date = date.ToString("yyyy-MM-dd"),
                TotalCalories = totalCalories,
                TotalProteinG = totalProtein,
                TotalCarbsG = totalCarbs,
                TotalFatG = totalFat,
                TargetCalories = targetCalories,
                TargetProteinG = targetProtein,
                TargetCarbsG = targetCarbs,
                TargetFatG = targetFat,
                CaloriesDeviation = totalCalories - targetCalories,
                ProteinDeviation = totalProtein - targetProtein,
                CarbsDeviation = totalCarbs - targetCarbs,
                FatDeviation = totalFat - targetFat,
                HasWarning = warningMessages.Count > 0,
                WarningMessages = warningMessages,
                GoalCompletionPercent = goalCompletionPercent,
                HasSnapshot = hasSnapshot,
                MealLogs = await MapMealLogsAsync(logs)
            };
        }

        private async Task SyncSnapshotForLogAsync(Guid userId, MealLog entity)
        {
            var logDate = entity.LoggedAt.HasValue
                ? DateOnly.FromDateTime(entity.LoggedAt.Value)
                : DateOnly.FromDateTime(DateTime.UtcNow);
            await _nutritionSnapshotService.SyncDailySnapshotAsync(userId, logDate);
        }

        private async Task<List<MealDaySummaryResponse>> BuildRangeSummariesAsync(Guid userId, DateOnly from, DateOnly to, List<MealLog> logs)
        {
            var result = new List<MealDaySummaryResponse>();
            var targetContext = await BuildNutritionTargetContextAsync(userId, from, to);
            for (var day = from; day <= to; day = day.AddDays(1))
            {
                var dayLogs = logs.Where(x => x.LoggedAt.HasValue && DateOnly.FromDateTime(x.LoggedAt.Value) == day).ToList();
                result.Add(await BuildDailySummaryAsync(userId, day, dayLogs, targetContext));
            }
            return result;
        }

        private async Task<NutritionTargetContext> BuildNutritionTargetContextAsync(
            Guid userId,
            DateOnly from,
            DateOnly to)
        {
            var health = (await _unitOfWork.HealthProfiles.FindAsync(
                item => item.UserId == userId)).FirstOrDefault();
            var context = new NutritionTargetContext
            {
                BaseCalories = health?.TargetCalories ?? 0,
                BaseProteinG = health?.TargetProteinG ?? 0,
                BaseCarbsG = health?.TargetCarbsG ?? 0,
                BaseFatG = health?.TargetFatG ?? 0
            };

            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null)
            {
                return context;
            }

            var role = (await _unitOfWork.Roles.FindAsync(
                item => item.Id == user.RoleId)).FirstOrDefault();
            if (!string.Equals(role?.Name, "Gymer", StringComparison.OrdinalIgnoreCase))
            {
                return context;
            }

            context.IsGymer = true;
            var approvedPlans = await _unitOfWork.MealPlanHeaders.FindAsync(item =>
                item.UserId == userId
                && item.IsActive
                && item.Status == "Approved"
                && item.ApprovedAt.HasValue
                && item.StartDate.HasValue
                && item.EndDate.HasValue
                && item.StartDate.Value <= to
                && item.EndDate.Value >= from);
            context.ApprovedPlanRanges = approvedPlans
                .Select(item => new ApprovedPlanRange(
                    item.StartDate!.Value,
                    item.EndDate!.Value))
                .ToList();

            var aiProfile = (await _unitOfWork.UserAiProfiles.FindAsync(
                item => item.UserId == userId)).FirstOrDefault();
            if (string.IsNullOrWhiteSpace(aiProfile?.Preferences))
            {
                return context;
            }

            try
            {
                context.GymConfiguration = JsonSerializer.Deserialize<GymNutritionConfiguration>(
                    aiProfile.Preferences,
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            }
            catch (JsonException)
            {
                // Legacy/non-JSON preferences must not break nutrition tracking.
            }

            return context;
        }

        private static ResolvedNutritionTargets ResolveNutritionTargets(
            NutritionTargetContext context,
            DateOnly date)
        {
            if (context.IsGymer && !context.HasApprovedPlanForDate(date))
            {
                return ResolvedNutritionTargets.Empty;
            }

            var configuration = context.GymConfiguration;
            if (configuration == null)
            {
                return context.BaseTargets();
            }

            var dateKey = date.ToString("yyyy-MM-dd");
            var weekStart = date.AddDays(-WeekdayOffsetFromMonday(date.DayOfWeek));
            var weekKey = weekStart.ToString("yyyy-MM-dd");
            var monthKey = date.ToString("yyyy-MM");

            var day = configuration.DailyDetails.FirstOrDefault(
                item => string.Equals(item.DateString, dateKey, StringComparison.Ordinal));
            var week = configuration.WeeklyDetails.FirstOrDefault(
                item => string.Equals(item.WeekStartDateString, weekKey, StringComparison.Ordinal));
            var month = configuration.MonthlyDetails.FirstOrDefault(
                item => string.Equals(item.MonthString, monthKey, StringComparison.Ordinal));

            var isTrainingDay = day?.IsTraining
                ?? configuration.WeeklyTrainingSchedule
                    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                    .Any(item => string.Equals(
                        item,
                        date.DayOfWeek.ToString(),
                        StringComparison.OrdinalIgnoreCase));

            var configuredCalories = FirstValue(
                day?.CustomCalories,
                week?.CustomCalories,
                month?.CustomCalories,
                isTrainingDay
                    ? configuration.TrainingDayTargetCalories
                    : configuration.RestDayTargetCalories);
            var minCalories = FirstValue(
                day?.MinCalories,
                week?.MinCalories,
                month?.MinCalories,
                configuredCalories.HasValue ? null : configuration.MinCalories);
            var maxCalories = FirstValue(
                day?.MaxCalories,
                week?.MaxCalories,
                month?.MaxCalories,
                configuredCalories.HasValue ? null : configuration.MaxCalories);
            var minProtein = FirstValue(
                day?.MinProteinG,
                week?.MinProteinG,
                month?.MinProteinG,
                configuration.MinProteinG);
            var maxProtein = FirstValue(
                day?.MaxProteinG,
                week?.MaxProteinG,
                month?.MaxProteinG,
                configuration.MaxProteinG);

            // "Calo mục tiêu" is an explicit target. When it is configured for
            // the selected day/week/month (or for training/rest days), return it
            // exactly as saved. Min/max calories are only a fallback guard when
            // no explicit target exists.
            var targetCalories = configuredCalories
                ?? ClampToConfiguredRange(context.BaseCalories, minCalories, maxCalories);

            var scale = context.BaseCalories > 0 && targetCalories > 0
                ? targetCalories / context.BaseCalories
                : 1m;
            var targetProtein = Math.Round(context.BaseProteinG * scale, 2);
            var targetCarbs = Math.Round(context.BaseCarbsG * scale, 2);
            var targetFat = Math.Round(context.BaseFatG * scale, 2);
            targetProtein = ClampToConfiguredRange(targetProtein, minProtein, maxProtein);

            var usesGymConfiguration = day != null
                || week != null
                || month != null
                || configuredCalories.HasValue
                || minCalories.HasValue
                || maxCalories.HasValue
                || minProtein.HasValue
                || maxProtein.HasValue;

            return new ResolvedNutritionTargets(
                targetCalories,
                targetProtein,
                targetCarbs,
                targetFat,
                usesGymConfiguration);
        }

        private static int WeekdayOffsetFromMonday(DayOfWeek dayOfWeek)
        {
            return ((int)dayOfWeek + 6) % 7;
        }

        private static decimal? FirstValue(params decimal?[] values)
        {
            return values.FirstOrDefault(value => value.HasValue);
        }

        private static decimal ClampToConfiguredRange(
            decimal value,
            decimal? minimum,
            decimal? maximum)
        {
            if (minimum.HasValue && value < minimum.Value)
            {
                value = minimum.Value;
            }
            if (maximum.HasValue && value > maximum.Value)
            {
                value = maximum.Value;
            }
            return value;
        }

        private static (DateOnly from, DateOnly to) ResolveRange(string range, DateOnly? startDate, DateOnly? endDate)
        {
            if (startDate.HasValue && endDate.HasValue)
            {
                return (startDate.Value, endDate.Value);
            }

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            return range.Trim().ToLower() switch
            {
                "week" => (today.AddDays(-6), today),
                "month" => (new DateOnly(today.Year, today.Month, 1), today),
                _ => (today, today)
            };
        }

        private async Task<MealLogResponse> MapMealLogAsync(MealLog x)
        {
            var mapped = await MapMealLogsAsync(new[] { x });
            return mapped[0];
        }

        private async Task<List<MealLogResponse>> MapMealLogsAsync(IEnumerable<MealLog> logs)
        {
            var logList = logs.ToList();
            if (logList.Count == 0) return new List<MealLogResponse>();

            var foodIds = logList.Where(x => x.FoodId.HasValue).Select(x => x.FoodId!.Value).Distinct().ToList();
            var recipeIds = logList.Where(x => x.RecipeId.HasValue).Select(x => x.RecipeId!.Value).Distinct().ToList();

            var foods = foodIds.Count > 0
                ? (await _unitOfWork.Foods.FindAsync(f => foodIds.Contains(f.Id))).ToDictionary(f => f.Id)
                : new Dictionary<Guid, Food>();
            var recipes = recipeIds.Count > 0
                ? (await _unitOfWork.Recipes.FindAsync(r => recipeIds.Contains(r.Id))).ToDictionary(r => r.Id)
                : new Dictionary<Guid, Recipe>();

            return logList
                .OrderBy(x => x.LoggedAt)
                .Select(x => MapMealLog(x, foods, recipes))
                .ToList();
        }

        private static MealLogResponse MapMealLog(MealLog x, IReadOnlyDictionary<Guid, Food> foods, IReadOnlyDictionary<Guid, Recipe> recipes)
        {
            string? foodName = null;
            string? recipeTitle = null;

            if (x.FoodId.HasValue && foods.TryGetValue(x.FoodId.Value, out var food))
                foodName = food.NameVi;
            if (x.RecipeId.HasValue && recipes.TryGetValue(x.RecipeId.Value, out var recipe))
                recipeTitle = recipe.Title;

            var displayName = !string.IsNullOrWhiteSpace(foodName)
                ? foodName
                : !string.IsNullOrWhiteSpace(recipeTitle)
                    ? recipeTitle
                    : !string.IsNullOrWhiteSpace(x.CustomName)
                        ? x.CustomName
                        : !string.IsNullOrWhiteSpace(x.Notes)
                            ? x.Notes
                            : "Món đã ghi";

            return new MealLogResponse
            {
                Id = x.Id,
                UserId = x.UserId,
                FoodId = x.FoodId,
                RecipeId = x.RecipeId,
                MealType = x.MealType,
                QuantityG = x.QuantityG,
                CaloriesKcal = x.CaloriesKcal,
                ProteinG = x.ProteinG,
                CarbsG = x.CarbsG,
                FatG = x.FatG,
                SourceType = x.SourceType,
                CustomName = x.CustomName,
                Notes = x.Notes,
                LoggedAt = x.LoggedAt,
                MealPlanItemId = x.MealPlanItemId,
                IsFromMealPlan = x.IsFromMealPlan,
                FoodName = foodName,
                RecipeTitle = recipeTitle,
                DisplayName = displayName,
                DisplayPortion = x.QuantityG.HasValue ? $"{x.QuantityG.Value:0.##}g" : null
            };
        }

        private static WeightLogResponse Map(WeightLog x) => new() { Id = x.Id, UserId = x.UserId, WeightKg = x.WeightKg, BodyFatPercent = x.BodyFatPercent, RecordedAt = x.RecordedAt };

        private async Task<decimal> ResolveQuantityGAsync(MealLogUpsertRequest request, Guid userId)
        {
            if (request.QuantityG.HasValue && request.QuantityG.Value > 0)
            {
                return request.QuantityG.Value;
            }

            if (!request.Quantity.HasValue || request.Quantity.Value <= 0)
            {
                throw new Exception("QuantityG or Quantity must be greater than 0.");
            }

            var unit = request.Unit?.Trim();
            if (string.IsNullOrWhiteSpace(unit) ||
                unit.Equals("g", StringComparison.OrdinalIgnoreCase) ||
                unit.Equals("gram", StringComparison.OrdinalIgnoreCase) ||
                unit.Equals("grams", StringComparison.OrdinalIgnoreCase))
            {
                return request.Quantity.Value;
            }

            if (!request.FoodId.HasValue)
            {
                throw new Exception("FoodId is required when converting a local portion unit.");
            }

            var converted = await _portionConverterService.ConvertPortionAsync(new PortionConvertRequest
            {
                FoodId = request.FoodId.Value,
                Unit = unit,
                Quantity = request.Quantity.Value
            }, userId);

            return converted.ConvertedGrams;
        }

        private static void ApplyRequestDisplayPortion(MealLogResponse response, MealLogUpsertRequest request)
        {
            if (request.Quantity.HasValue && !string.IsNullOrWhiteSpace(request.Unit))
            {
                response.DisplayPortion = $"{request.Quantity.Value:0.##} {request.Unit.Trim()}";
            }
        }

        private sealed class NutritionTargetContext
        {
            public decimal BaseCalories { get; init; }
            public decimal BaseProteinG { get; init; }
            public decimal BaseCarbsG { get; init; }
            public decimal BaseFatG { get; init; }
            public bool IsGymer { get; set; }
            public List<ApprovedPlanRange> ApprovedPlanRanges { get; set; } = new();
            public GymNutritionConfiguration? GymConfiguration { get; set; }

            public bool HasApprovedPlanForDate(DateOnly date)
            {
                return ApprovedPlanRanges.Any(item =>
                    item.StartDate <= date && item.EndDate >= date);
            }

            public ResolvedNutritionTargets BaseTargets()
            {
                return new ResolvedNutritionTargets(
                    BaseCalories,
                    BaseProteinG,
                    BaseCarbsG,
                    BaseFatG,
                    UsesGymConfiguration: false);
            }
        }

        private sealed class GymNutritionConfiguration
        {
            public string WeeklyTrainingSchedule { get; set; } = string.Empty;
            public decimal? TrainingDayTargetCalories { get; set; }
            public decimal? RestDayTargetCalories { get; set; }
            public decimal? MinCalories { get; set; }
            public decimal? MaxCalories { get; set; }
            public decimal? MinProteinG { get; set; }
            public decimal? MaxProteinG { get; set; }
            public List<GymNutritionDetail> DailyDetails { get; set; } = new();
            public List<GymNutritionDetail> WeeklyDetails { get; set; } = new();
            public List<GymNutritionDetail> MonthlyDetails { get; set; } = new();
        }

        private sealed class GymNutritionDetail
        {
            public string? DateString { get; set; }
            public string? WeekStartDateString { get; set; }
            public string? MonthString { get; set; }
            public bool? IsTraining { get; set; }
            public decimal? CustomCalories { get; set; }
            public decimal? MinCalories { get; set; }
            public decimal? MaxCalories { get; set; }
            public decimal? MinProteinG { get; set; }
            public decimal? MaxProteinG { get; set; }
        }

        private readonly record struct ResolvedNutritionTargets(
            decimal Calories,
            decimal ProteinG,
            decimal CarbsG,
            decimal FatG,
            bool UsesGymConfiguration)
        {
            public static ResolvedNutritionTargets Empty => new(
                0,
                0,
                0,
                0,
                UsesGymConfiguration: true);
        }

        private readonly record struct ApprovedPlanRange(
            DateOnly StartDate,
            DateOnly EndDate);

        private static DateTime EnsureUtc(DateTime dt)
        {
            return dt.Kind == DateTimeKind.Utc ? dt : dt.ToUniversalTime();
        }

        private static DateTime? EnsureUtc(DateTime? dt)
        {
            if (!dt.HasValue) return null;
            return dt.Value.Kind == DateTimeKind.Utc ? dt.Value : dt.Value.ToUniversalTime();
        }
    }
}
