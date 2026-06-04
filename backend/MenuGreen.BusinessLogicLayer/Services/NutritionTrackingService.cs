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
    public class NutritionTrackingService : INutritionTrackingService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INutritionSnapshotService _nutritionSnapshotService;

        public NutritionTrackingService(
            IUnitOfWork unitOfWork,
            INutritionSnapshotService nutritionSnapshotService)
        {
            _unitOfWork = unitOfWork;
            _nutritionSnapshotService = nutritionSnapshotService;
        }

        public async Task<MealLogResponse> CreateMealLogAsync(Guid userId, MealLogUpsertRequest request)
        {
            var entity = await BuildMealLogAsync(userId, request);
            await _unitOfWork.MealLogs.AddAsync(entity);
            await _unitOfWork.CompleteAsync();
            await SyncSnapshotForLogAsync(userId, entity);
            return await MapMealLogAsync(entity);
        }

        public async Task<MealLogResponse> UpdateMealLogAsync(Guid userId, Guid mealLogId, MealLogUpsertRequest request)
        {
            var entity = await GetOwnedMealLogAsync(userId, mealLogId);
            await ApplyMealLogRequestAsync(entity, request);
            _unitOfWork.MealLogs.Update(entity);
            await _unitOfWork.CompleteAsync();
            await SyncSnapshotForLogAsync(userId, entity);
            return await MapMealLogAsync(entity);
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
            var logs = await _unitOfWork.MealLogs.FindAsync(x => x.UserId == userId && x.LoggedAt.HasValue && DateOnly.FromDateTime(x.LoggedAt.Value) == date);
            await _nutritionSnapshotService.SyncDailySnapshotAsync(userId, date);
            return await BuildDailySummaryAsync(userId, date, logs.ToList());
        }

        public async Task<NutritionDashboardResponse> GetDashboardAsync(Guid userId, string range, DateOnly? startDate, DateOnly? endDate)
        {
            var (from, to) = ResolveRange(range, startDate, endDate);
            for (var day = from; day <= to; day = day.AddDays(1))
            {
                await _nutritionSnapshotService.SyncDailySnapshotAsync(userId, day);
            }

            var logs = await _unitOfWork.MealLogs.FindAsync(x => x.UserId == userId && x.LoggedAt.HasValue && DateOnly.FromDateTime(x.LoggedAt.Value) >= from && DateOnly.FromDateTime(x.LoggedAt.Value) <= to);
            var days = await BuildRangeSummariesAsync(userId, from, to, logs.ToList());
            var weightLogs = await _unitOfWork.WeightLogs.FindAsync(x => x.UserId == userId && x.RecordedAt.HasValue && DateOnly.FromDateTime(x.RecordedAt.Value) >= from && DateOnly.FromDateTime(x.RecordedAt.Value) <= to);

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
                RecordedAt = request.RecordedAt ?? DateTime.UtcNow
            };

            await _unitOfWork.WeightLogs.AddAsync(entity);
            await _unitOfWork.CompleteAsync();
            return Map(entity);
        }

        public async Task<WeightLogResponse> UpdateWeightLogAsync(Guid userId, Guid weightLogId, WeightLogUpsertRequest request)
        {
            var entity = await GetOwnedWeightLogAsync(userId, weightLogId);
            entity.WeightKg = request.WeightKg;
            entity.BodyFatPercent = request.BodyFatPercent;
            entity.RecordedAt = request.RecordedAt ?? entity.RecordedAt;
            _unitOfWork.WeightLogs.Update(entity);
            await _unitOfWork.CompleteAsync();
            return Map(entity);
        }

        public async Task DeleteWeightLogAsync(Guid userId, Guid weightLogId)
        {
            var entity = await GetOwnedWeightLogAsync(userId, weightLogId);
            _unitOfWork.WeightLogs.Remove(entity);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<MealLogListResponse> GetMealLogsAsync(Guid userId, int page = 1, int pageSize = 20)
        {
            var allLogs = await _unitOfWork.MealLogs.FindAsync(x => x.UserId == userId);
            var totalCount = allLogs.Count();
            var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
            
            var pagedLogs = allLogs
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
            var logs = await _unitOfWork.MealLogs.FindAsync(
                x => x.UserId == userId && 
                x.LoggedAt.HasValue && 
                DateOnly.FromDateTime(x.LoggedAt.Value) >= startDate && 
                DateOnly.FromDateTime(x.LoggedAt.Value) <= endDate);

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
            
            var logs = await _unitOfWork.MealLogs.FindAsync(
                x => x.UserId == userId && 
                x.LoggedAt.HasValue && 
                DateOnly.FromDateTime(x.LoggedAt.Value) >= startDate && 
                DateOnly.FromDateTime(x.LoggedAt.Value) <= endDate);

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
            var logs = await _unitOfWork.MealLogs.FindAsync(
                x => x.UserId == userId && 
                x.LoggedAt.HasValue && 
                DateOnly.FromDateTime(x.LoggedAt.Value) >= startDate && 
                DateOnly.FromDateTime(x.LoggedAt.Value) <= endDate);

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
            var logs = await _unitOfWork.WeightLogs.FindAsync(
                x => x.UserId == userId && 
                x.RecordedAt.HasValue && 
                DateOnly.FromDateTime(x.RecordedAt.Value) >= startDate && 
                DateOnly.FromDateTime(x.RecordedAt.Value) <= endDate);

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
                QuantityG = request.QuantityG,
                Notes = request.Notes,
                LoggedAt = request.LoggedAt ?? DateTime.UtcNow
            };

            await ApplyMealLogRequestAsync(entity, request);
            return entity;
        }

        private async Task ApplyMealLogRequestAsync(MealLog entity, MealLogUpsertRequest request)
        {
            entity.FoodId = request.FoodId;
            entity.RecipeId = request.RecipeId;
            entity.MealType = request.MealType;
            entity.QuantityG = request.QuantityG;
            entity.Notes = request.Notes;
            entity.LoggedAt = request.LoggedAt ?? entity.LoggedAt ?? DateTime.UtcNow;

            if (request.FoodId.HasValue)
            {
                var food = await _unitOfWork.Foods.GetByIdAsync(request.FoodId.Value) ?? throw new Exception("Food not found.");
                ApplyNutritionFromFood(entity, food, request.QuantityG);
                entity.SourceType = "Food";
                return;
            }

            if (request.RecipeId.HasValue)
            {
                var recipe = await _unitOfWork.Recipes.GetByIdAsync(request.RecipeId.Value) ?? throw new Exception("Recipe not found.");
                ApplyNutritionFromRecipe(entity, recipe, request.QuantityG);
                entity.SourceType = "Recipe";
                return;
            }

            throw new Exception("FoodId or RecipeId is required.");
        }

        private static void ApplyNutritionFromFood(MealLog entity, Food food, decimal quantityG)
        {
            var ratio = quantityG / 100m;
            entity.CaloriesKcal = Multiply(food.CaloriesKcal, ratio);
            entity.ProteinG = Multiply(food.ProteinG, ratio);
            entity.CarbsG = Multiply(food.CarbsG, ratio);
            entity.FatG = Multiply(food.FatG, ratio);
        }

        private static void ApplyNutritionFromRecipe(MealLog entity, Recipe recipe, decimal quantityG)
        {
            var ratio = quantityG / 100m;
            entity.CaloriesKcal = Multiply(recipe.EstimatedPriceVnd.HasValue ? 0 : 0, ratio); // fallback if recipe nutrition is not stored directly
            entity.ProteinG = 0;
            entity.CarbsG = 0;
            entity.FatG = 0;
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
            var health = (await _unitOfWork.HealthProfiles.FindAsync(x => x.UserId == userId)).FirstOrDefault();
            var targetCalories = health?.TargetCalories ?? 0;
            var targetProtein = health?.TargetProteinG ?? 0;
            var targetCarbs = health?.TargetCarbsG ?? 0;
            var targetFat = health?.TargetFatG ?? 0;

            var totalCalories = logs.Sum(x => x.CaloriesKcal ?? 0);
            var totalProtein = logs.Sum(x => x.ProteinG ?? 0);
            var totalCarbs = logs.Sum(x => x.CarbsG ?? 0);
            var totalFat = logs.Sum(x => x.FatG ?? 0);

            decimal? goalCompletionPercent = null;
            var hasSnapshot = false;
            var snapshots = await _unitOfWork.NutritionSnapshots.FindAsync(
                x => x.UserId == userId && x.SnapshotDate == date);
            var snapshot = snapshots.FirstOrDefault();
            if (snapshot != null)
            {
                hasSnapshot = true;
                goalCompletionPercent = snapshot.GoalCompletionPercent;
            }
            else if (targetCalories > 0)
            {
                goalCompletionPercent = Math.Round(totalCalories / targetCalories * 100m, 2);
            }

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
                HasWarning = Math.Abs((double)(totalCalories - targetCalories)) > (double)Math.Max(100, targetCalories * 0.10m),
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
            for (var day = from; day <= to; day = day.AddDays(1))
            {
                var dayLogs = logs.Where(x => x.LoggedAt.HasValue && DateOnly.FromDateTime(x.LoggedAt.Value) == day).ToList();
                result.Add(await BuildDailySummaryAsync(userId, day, dayLogs));
            }
            return result;
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
                Notes = x.Notes,
                LoggedAt = x.LoggedAt,
                FoodName = foodName,
                RecipeTitle = recipeTitle,
                DisplayName = displayName
            };
        }

        private static WeightLogResponse Map(WeightLog x) => new() { Id = x.Id, UserId = x.UserId, WeightKg = x.WeightKg, BodyFatPercent = x.BodyFatPercent, RecordedAt = x.RecordedAt };
    }
}
