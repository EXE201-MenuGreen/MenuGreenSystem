using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Helpers;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class MealPlanService : IMealPlanService
    {
        private const int VietnamUtcOffsetHours = 7;
        private readonly IUnitOfWork _unitOfWork;
        private readonly INutritionTrackingService _nutritionTracking;
        private readonly IGroceryListBuilderService _groceryListBuilder;
        private readonly IShoppingTripBuilderService _shoppingTripBuilder;
        private readonly ICacheService _cache;
        private static readonly TimeSpan MealPlanTtl = TimeSpan.FromMinutes(5);

        public MealPlanService(
            IUnitOfWork unitOfWork,
            INutritionTrackingService nutritionTracking,
            IGroceryListBuilderService groceryListBuilder,
            IShoppingTripBuilderService shoppingTripBuilder,
            ICacheService cache)
        {
            _unitOfWork = unitOfWork;
            _nutritionTracking = nutritionTracking;
            _groceryListBuilder = groceryListBuilder;
            _shoppingTripBuilder = shoppingTripBuilder;
            _cache = cache;
        }

        public async Task<IEnumerable<MealPlanResponse>> GetAllAsync(bool? isActive = null, Guid? userId = null)
        {
            var plans = userId.HasValue && userId.Value != Guid.Empty
                ? await _unitOfWork.MealPlanHeaders.FindAsync(x => x.UserId == userId.Value)
                : await _unitOfWork.MealPlanHeaders.GetAllAsync();
            // Default to active plans only when no filter specified
            if (isActive == null)
            {
                isActive = true;
            }
            plans = plans.Where(x => x.IsActive == isActive.Value);
            // Coach-created drafts are private working copies. The Gymer only
            // receives them after the Coach submits and Status becomes Approved.
            if (userId.HasValue && userId.Value != Guid.Empty)
            {
                plans = plans.Where(x =>
                    !string.Equals(x.Status, "Draft", StringComparison.OrdinalIgnoreCase));
            }

            var results = new List<MealPlanResponse>();
            foreach (var plan in plans)
            {
                try
                {
                    var mapped = await MapAsync(plan);
                    results.Add(mapped);
                }
                catch (Exception)
                {
                    // Skip plans that fail to map (corrupted data, missing references, etc.)
                }
            }
            return results;
        }

        public async Task<MealPlanResponse> GetByIdAsync(Guid id, Guid? userId = null)
        {
            var entity = await GetMealPlanAsync(id, userId);
            return await MapAsync(entity);
        }

        public async Task<MealPlanResponse> CreateAsync(MealPlanUpsertRequest request, Guid? userId = null)
        {
            ValidateItems(request.Items);

            var entity = new MealPlanHeader
            {
                Id = Guid.NewGuid(),
                UserId = userId ?? Guid.Empty,
                Title = request.Title,
                PlanType = request.PlanType,
                StartDate = request.StartDate,
                EndDate = request.EndDate,
                TargetCalories = request.TargetCalories,
                GeneratedBy = request.GeneratedBy ?? "USER",
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MealPlanHeaders.AddAsync(entity);
            await _unitOfWork.CompleteAsync();

            await ReplaceItemsAsync(entity.Id, request.Items, entity.StartDate);
            await InvalidateMealPlanCacheAsync(userId);
            return await GetByIdAsync(entity.Id, userId);
        }

        public async Task<MealPlanResponse> CreateEmptyAsync(CreateEmptyPlanRequest request, Guid? userId = null)
        {
            var entity = new MealPlanHeader
            {
                Id = Guid.NewGuid(),
                UserId = userId ?? Guid.Empty,
                Title = request.Title,
                PlanType = request.PlanType,
                StartDate = request.StartDate,
                EndDate = request.EndDate,
                TargetCalories = request.TargetCalories,
                GeneratedBy = "USER",
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MealPlanHeaders.AddAsync(entity);
            await _unitOfWork.CompleteAsync();
            await InvalidateMealPlanCacheAsync(userId);
            return await GetByIdAsync(entity.Id, userId);
        }

        public async Task<MealPlanResponse> UpdateAsync(Guid id, MealPlanUpsertRequest request, Guid? userId = null)
        {
            var entity = await GetMealPlanAsync(id, userId);

            entity.Title = request.Title;
            entity.PlanType = request.PlanType;
            entity.StartDate = request.StartDate;
            entity.EndDate = request.EndDate;
            entity.TargetCalories = request.TargetCalories;
            entity.GeneratedBy = request.GeneratedBy ?? entity.GeneratedBy;
            entity.IsActive = request.IsActive;
            entity.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.MealPlanHeaders.Update(entity);
            await _unitOfWork.CompleteAsync();

            if (request.Items != null && request.Items.Any())
            {
                ValidateItems(request.Items);
                var existingItems = await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == entity.Id);
                _unitOfWork.MealPlanItems.RemoveRange(existingItems);
                await _unitOfWork.CompleteAsync();

                await ReplaceItemsAsync(entity.Id, request.Items, entity.StartDate);
            }

            await InvalidateMealPlanCacheAsync(userId);
            return await GetByIdAsync(entity.Id, userId);
        }

        public async Task DeleteAsync(Guid id, Guid? userId = null)
        {
            var entity = await GetMealPlanAsync(id, userId);

            // Delete all items in the meal plan first
            var items = await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == entity.Id);
            _unitOfWork.MealPlanItems.RemoveRange(items);
            await _unitOfWork.CompleteAsync();

            // Then soft delete the plan header
            entity.IsActive = false;
            _unitOfWork.MealPlanHeaders.Update(entity);
            await _unitOfWork.CompleteAsync();

            await InvalidateMealPlanCacheAsync(userId);
        }

        public async Task<MealPlanResponse> UpdateStatusAsync(Guid id, MealPlanStatusRequest request, Guid? userId = null)
        {
            var entity = await GetMealPlanAsync(id, userId);
            entity.IsActive = request.IsActive;
            entity.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.MealPlanHeaders.Update(entity);
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(id, userId);
        }

        public async Task<MealPlanDistributionResponse> DistributeAsync(Guid id, string targetAudience, string? notes = null, Guid? userId = null)
        {
            var entity = await GetMealPlanAsync(id, userId);
            entity.GeneratedBy = entity.GeneratedBy ?? "ADMIN";
            entity.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.MealPlanHeaders.Update(entity);
            await _unitOfWork.CompleteAsync();

            return new MealPlanDistributionResponse
            {
                MealPlanId = entity.Id,
                Message = notes ?? "Meal plan distributed successfully.",
                TargetAudience = targetAudience,
                DistributedAt = DateTime.UtcNow,
                Completed = true
            };
        }

        public async Task<MealPlanResponse> AddItemAsync(Guid planId, MealPlanItemUpsertRequest request, Guid? userId = null)
        {
            ValidateItem(request);
            var plan = await GetMealPlanAsync(planId, userId);

            var item = new MealPlanItem
            {
                Id = Guid.NewGuid(),
                MealPlanId = plan.Id,
                MealType = request.MealType,
                FoodId = request.FoodId,
                RecipeId = request.RecipeId,
                PlannedDate = request.PlannedDate ?? DateOnly.FromDateTime(DateTime.UtcNow.AddHours(VietnamUtcOffsetHours)),
                ScheduledTime = request.ScheduledTime,
                TargetCalories = request.TargetCalories,
                IsCompleted = request.IsCompleted,
                CreatedAt = DateTime.UtcNow,
                Origin = request.Origin,
                CustomName = request.CustomName,
                QuantityG = (decimal?)request.QuantityG
            };

            await _unitOfWork.MealPlanItems.AddAsync(item);
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(planId, userId);
        }

        public async Task<MealPlanResponse> UpdateItemAsync(Guid planId, Guid itemId, MealPlanItemUpsertRequest request, Guid? userId = null)
        {
            ValidateItem(request);
            var item = await GetPlanItemAsync(planId, itemId, userId);
            item.MealType = request.MealType;
            item.FoodId = request.FoodId;
            item.RecipeId = request.RecipeId;
            item.PlannedDate = request.PlannedDate;
            item.ScheduledTime = request.ScheduledTime;
            item.TargetCalories = request.TargetCalories;
            item.IsCompleted = request.IsCompleted;
            item.Origin = request.Origin;
            item.CustomName = request.CustomName;
            if (request.QuantityG.HasValue) item.QuantityG = (decimal?)request.QuantityG;
            _unitOfWork.MealPlanItems.Update(item);
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(planId, userId);
        }

        public async Task<MealPlanResponse> ReplaceItemAsync(
            Guid planId,
            Guid itemId,
            MealPlanItemReplaceRequest request,
            Guid userId)
        {
            var item = await GetPlanItemAsync(planId, itemId, userId);
            if (item.IsCompleted)
            {
                throw new InvalidOperationException("Không thể đổi món đã hoàn thành.");
            }

            var replacementRecipe = await _unitOfWork.Recipes.GetByIdAsync(request.NewFoodId);
            var replacementFood = replacementRecipe == null
                ? await _unitOfWork.Foods.GetByIdAsync(request.NewFoodId)
                : null;
            if (replacementRecipe == null && replacementFood == null)
            {
                throw new InvalidOperationException("Không tìm thấy món thay thế.");
            }

            if (replacementRecipe != null)
            {
                var expectedMealType = item.MealType ?? "lunch";
                if (replacementRecipe.MealType == null ||
                    !replacementRecipe.MealType.Contains(expectedMealType, StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException("Món thay thế không phù hợp với loại bữa ăn này.");
                }

                item.RecipeId = replacementRecipe.Id;
                item.FoodId = null;
                item.TargetCalories = await GetRecipeCaloriesAsync(replacementRecipe.Id);
            }
            else if (replacementFood != null)
            {
                item.FoodId = replacementFood.Id;
                item.RecipeId = null;
                item.TargetCalories = (int)Math.Round(replacementFood.CaloriesKcal ?? 0);
            }

            item.CustomName = null;
            item.SourceType = null;
            item.IngredientSnapshotJson = null;
            _unitOfWork.MealPlanItems.Update(item);
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(planId, userId);
        }

        public async Task DeleteItemAsync(Guid planId, Guid itemId, Guid? userId = null)
        {
            var item = await GetPlanItemAsync(planId, itemId, userId);
            _unitOfWork.MealPlanItems.Remove(item);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<MealPlanResponse> UpdateItemStatusAsync(Guid planId, Guid itemId, MealPlanStatusRequest request, Guid? userId = null)
        {
            var item = await GetPlanItemAsync(planId, itemId, userId);
            item.IsCompleted = request.IsActive;
            _unitOfWork.MealPlanItems.Update(item);
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(planId, userId);
        }

        public async Task<MealLogResponse> ConvertItemToLogAsync(Guid planId, Guid itemId, MealPlanConvertToLogRequest request, Guid? userId = null)
        {
            var item = await GetPlanItemAsync(planId, itemId, userId);
            var ownerId = userId ?? Guid.Empty;
            var existingLog = (await _unitOfWork.MealLogs.FindAsync(
                    x => x.MealPlanItemId == itemId && x.UserId == ownerId))
                .OrderByDescending(x => x.LoggedAt)
                .FirstOrDefault();

            if (existingLog != null)
            {
                item.IsCompleted = true;
                _unitOfWork.MealPlanItems.Update(item);
                await _unitOfWork.CompleteAsync();
                return await _nutritionTracking.GetMealLogAsync(ownerId, existingLog.Id);
            }

            var mealLogRequest = new MealLogUpsertRequest
            {
                FoodId = item.FoodId,
                RecipeId = item.RecipeId,
                MealType = item.MealType ?? "snack",
                QuantityG = item.QuantityG ?? 100,
                CaloriesKcal = item.TargetCalories,
                ProteinG = item.ProteinG,
                CarbsG = item.CarbsG,
                FatG = item.FatG,
                CustomName = item.CustomName,
                Notes = request.Notes ?? "Logged from meal plan.",
                LoggedAt = request.LoggedAt ?? ResolveMealLogUtc(item),
                MealPlanItemId = item.Id
            };

            var mealLog = await _nutritionTracking.CreateMealLogAsync(ownerId, mealLogRequest);
            item.IsCompleted = true;
            _unitOfWork.MealPlanItems.Update(item);
            await _unitOfWork.CompleteAsync();

            return mealLog;
        }

        public async Task<MealPlanResponse> CommitAsync(Guid planId, MealPlanCommitRequest request, Guid? userId = null)
        {
            var plan = await GetMealPlanAsync(planId, userId);
            plan.IsActive = false;
            plan.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.MealPlanHeaders.Update(plan);
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(planId, userId);
        }

        public async Task<MealPlanResponse> DuplicateAsync(Guid planId, MealPlanDuplicateRequest request, Guid? userId = null)
        {
            var source = await GetMealPlanAsync(planId, userId);
            var items = await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == source.Id);
            var newPlan = new MealPlanHeader
            {
                Id = Guid.NewGuid(),
                UserId = source.UserId,
                Title = source.Title + " (Copy)",
                PlanType = source.PlanType,
                StartDate = request.TargetStartDate,
                EndDate = request.TargetStartDate.AddDays(
                    ((source.EndDate ?? source.StartDate ?? request.TargetStartDate).ToDateTime(TimeOnly.MinValue) - (source.StartDate ?? request.SourceStartDate ?? request.TargetStartDate).ToDateTime(TimeOnly.MinValue)).Days),
                TargetCalories = source.TargetCalories,
                GeneratedBy = source.GeneratedBy,
                IsActive = source.IsActive,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            await _unitOfWork.MealPlanHeaders.AddAsync(newPlan);
            await _unitOfWork.CompleteAsync();

            foreach (var item in items)
            {
                await _unitOfWork.MealPlanItems.AddAsync(new MealPlanItem
                {
                    Id = Guid.NewGuid(),
                    MealPlanId = newPlan.Id,
                    MealType = item.MealType,
                    FoodId = item.FoodId,
                    RecipeId = item.RecipeId,
                    PlannedDate = request.TargetStartDate,
                    ScheduledTime = item.ScheduledTime,
                    TargetCalories = item.TargetCalories,
                    IsCompleted = false,
                    CreatedAt = DateTime.UtcNow,
                    Origin = item.Origin
                });
            }
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(newPlan.Id, userId);
        }

        public async Task<MealPlanDashboardResponse> GetDashboardAsync(DateOnly date, Guid? userId = null)
        {
            // Planned dates are Vietnam calendar dates, while meal logs are stored in UTC.
            var startDateTime = date
                .ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc)
                .AddHours(-VietnamUtcOffsetHours);
            var endDateTime = date
                .AddDays(1)
                .ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc)
                .AddHours(-VietnamUtcOffsetHours)
                .AddTicks(-1);

            List<MealPlanItem> itemList;
            List<MealLog> logList;

            if (userId.HasValue && userId.Value != Guid.Empty)
            {
                var headers = await _unitOfWork.MealPlanHeaders.FindAsync(x => x.UserId == userId.Value);
                var headerIds = headers.Select(h => h.Id).ToList();

                if (headerIds.Any())
                {
                    var planItems = await _unitOfWork.MealPlanItems.FindAsync(x => x.PlannedDate == date && headerIds.Contains(x.MealPlanId));
                    itemList = planItems.ToList();
                }
                else
                {
                    itemList = new List<MealPlanItem>();
                }

                var logs = await _unitOfWork.MealLogs.FindAsync(x => x.UserId == userId.Value && x.LoggedAt.HasValue && x.LoggedAt.Value >= startDateTime && x.LoggedAt.Value <= endDateTime);
                logList = logs.ToList();
            }
            else
            {
                var planItems = await _unitOfWork.MealPlanItems.FindAsync(x => x.PlannedDate == date);
                itemList = planItems.ToList();

                var logs = await _unitOfWork.MealLogs.FindAsync(x => x.LoggedAt.HasValue && x.LoggedAt.Value >= startDateTime && x.LoggedAt.Value <= endDateTime);
                logList = logs.ToList();
            }

            var actualItemIds = logList
                .Where(x => x.MealPlanItemId.HasValue)
                .Select(x => x.MealPlanItemId!.Value)
                .ToHashSet();

            foreach (var item in itemList)
            {
                if (actualItemIds.Contains(item.Id))
                {
                    item.IsCompleted = true;
                }
            }

            var mappedItems = new List<MealPlanItemResponse>();
            foreach (var item in itemList)
            {
                mappedItems.Add(await MapItemAsync(item));
            }

            return new MealPlanDashboardResponse
            {
                Date = date,
                TotalPlannedCalories = mappedItems.Sum(x => x.TargetCalories ?? 0),
                TotalActualCalories = (int)logList.Sum(x => x.CaloriesKcal ?? 0),
                PlannedProtein = (int)mappedItems.Sum(x => x.ProteinG ?? 0),
                ActualProtein = (int)Math.Round(logList.Sum(x => x.ProteinG ?? 0)),
                PlannedCarbs = (int)mappedItems.Sum(x => x.CarbsG ?? 0),
                ActualCarbs = (int)Math.Round(logList.Sum(x => x.CarbsG ?? 0)),
                PlannedFat = (int)mappedItems.Sum(x => x.FatG ?? 0),
                ActualFat = (int)Math.Round(logList.Sum(x => x.FatG ?? 0)),
                PlannedItemsCount = itemList.Count,
                CompletedItemsCount = itemList.Count(x => x.IsCompleted),
                SkippedItemsCount = itemList.Count(x => !x.IsCompleted && x.PlannedDate.HasValue && x.PlannedDate.Value <= date),
                Items = mappedItems,
                ActualLogs = logList.Select(MapLog).ToList()
            };
        }

        public async Task<MealPlanCompareResponse> GetCompareAsync(DateOnly from, DateOnly to, Guid? userId = null)
        {
            if (from > to)
            {
                throw new ArgumentException("The start date must be before or equal to the end date.");
            }

            // Batch load all data upfront to avoid N+1 queries (fix sequential awaits)
            var allPlanItems = await _unitOfWork.MealPlanItems.FindAsync(x => x.PlannedDate >= from && x.PlannedDate <= to);
            var allLogs = await _unitOfWork.MealLogs.FindAsync(x =>
                x.LoggedAt.HasValue &&
                x.LoggedAt.Value >= from.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc) &&
                x.LoggedAt.Value <= to.ToDateTime(TimeOnly.MaxValue, DateTimeKind.Utc));

            var itemsByDate = allPlanItems.GroupBy(x => x.PlannedDate ?? from).ToDictionary(g => g.Key, g => g.ToList());
            var logsByDate = allLogs.GroupBy(x => DateOnly.FromDateTime(x.LoggedAt!.Value)).ToDictionary(g => g.Key, g => g.ToList());

            var days = new List<MealPlanDashboardResponse>();
            var cursor = from;
            while (cursor <= to)
            {
                var dateItems = itemsByDate.GetValueOrDefault(cursor) ?? new List<MealPlanItem>();
                var dateLogs = logsByDate.GetValueOrDefault(cursor) ?? new List<MealLog>();

                var actualByItem = dateLogs
                    .Where(x => x.MealPlanItemId.HasValue)
                    .ToDictionary(x => x.MealPlanItemId!.Value, x => x.Id);

                foreach (var item in dateItems)
                {
                    if (actualByItem.ContainsKey(item.Id))
                    {
                        item.IsCompleted = true;
                    }
                }

                var items = dateItems.Select(x => new MealPlanItemResponse
                {
                    Id = x.Id,
                    MealPlanId = x.MealPlanId,
                    MealType = x.MealType,
                    FoodId = x.FoodId,
                    RecipeId = x.RecipeId,
                    PlannedDate = x.PlannedDate,
                    ScheduledTime = x.ScheduledTime,
                    TargetCalories = x.TargetCalories,
                    QuantityG = x.QuantityG,
                    ProteinG = x.ProteinG,
                    CarbsG = x.CarbsG,
                    FatG = x.FatG,
                    CustomName = x.CustomName,
                    IsCompleted = x.IsCompleted,
                    Status = x.IsCompleted ? "done" : "planned"
                }).ToList();

                days.Add(new MealPlanDashboardResponse
                {
                    Date = cursor,
                    TotalPlannedCalories = dateItems.Sum(x => x.TargetCalories ?? 0),
                    TotalActualCalories = (int)dateLogs.Sum(x => x.CaloriesKcal ?? 0),
                    PlannedItemsCount = dateItems.Count,
                    CompletedItemsCount = dateItems.Count(x => x.IsCompleted),
                    SkippedItemsCount = dateItems.Count(x => !x.IsCompleted && x.PlannedDate.HasValue && x.PlannedDate.Value <= cursor),
                    Items = items,
                    ActualLogs = dateLogs.Select(MapLog).ToList()
                });

                cursor = cursor.AddDays(1);
            }

            var plannedItems = days.Sum(x => x.PlannedItemsCount);
            var completedItems = days.Sum(x => x.CompletedItemsCount);
            var plannedCalories = days.Sum(x => x.TotalPlannedCalories);
            var actualCalories = days.Sum(x => x.TotalActualCalories);
            var plannedProtein = (int)Math.Round(days.Sum(x => x.Items.Sum(item => item.ProteinG ?? 0)));
            var actualProtein = (int)Math.Round(days.Sum(x => x.ActualLogs.Sum(log => log.ProteinG ?? 0)));
            var plannedCarbs = (int)Math.Round(days.Sum(x => x.Items.Sum(item => item.CarbsG ?? 0)));
            var actualCarbs = (int)Math.Round(days.Sum(x => x.ActualLogs.Sum(log => log.CarbsG ?? 0)));
            var plannedFat = (int)Math.Round(days.Sum(x => x.Items.Sum(item => item.FatG ?? 0)));
            var actualFat = (int)Math.Round(days.Sum(x => x.ActualLogs.Sum(log => log.FatG ?? 0)));

            var weeklyData = days
                .Select((day, index) => new { Day = day, WeekNumber = (index / 7) + 1 })
                .GroupBy(x => x.WeekNumber)
                .Select(group =>
                {
                    var weekPlannedCalories = group.Sum(x => x.Day.TotalPlannedCalories);
                    var weekActualCalories = group.Sum(x => x.Day.TotalActualCalories);
                    return new MealPlanWeekCompareResponse
                    {
                        WeekNumber = group.Key,
                        PlannedCalories = weekPlannedCalories,
                        ActualCalories = weekActualCalories,
                        Percent = CalculateRatio(weekActualCalories, weekPlannedCalories)
                    };
                })
                .ToList();

            return new MealPlanCompareResponse
            {
                From = from,
                To = to,
                PlannedCalories = plannedCalories,
                ActualCalories = actualCalories,
                CaloriePercent = CalculateRatio(actualCalories, plannedCalories),
                PlannedProtein = plannedProtein,
                ActualProtein = actualProtein,
                ProteinPercent = CalculateRatio(actualProtein, plannedProtein),
                PlannedCarbs = plannedCarbs,
                ActualCarbs = actualCarbs,
                CarbsPercent = CalculateRatio(actualCarbs, plannedCarbs),
                PlannedFat = plannedFat,
                ActualFat = actualFat,
                FatPercent = CalculateRatio(actualFat, plannedFat),
                PlannedItemsCount = plannedItems,
                ActualLogsCount = days.Sum(x => x.ActualLogs.Count),
                CompletionRate = plannedItems == 0 ? 0 : Math.Round((decimal)completedItems / plannedItems * 100m, 2),
                SkippedItemsCount = days.Sum(x => x.SkippedItemsCount),
                CompletedDays = days.Count(x => x.PlannedItemsCount > 0 && x.CompletedItemsCount == x.PlannedItemsCount),
                TotalDays = days.Count(x => x.PlannedItemsCount > 0),
                WeeklyData = weeklyData,
                Days = days
            };
        }

        public async Task<MealPlanStreakResponse> GetStreaksAsync(Guid? userId = null)
        {
            if (userId == null || userId == Guid.Empty)
            {
                return new MealPlanStreakResponse
                {
                    CurrentStreakDays = 0,
                    BestStreakDays = 0,
                    WeeklyAdherenceRate = 0
                };
            }

            var todayDate = DateOnly.FromDateTime(DateTime.UtcNow.AddHours(VietnamUtcOffsetHours));
            var mealLogs = await _unitOfWork.MealLogs.FindAsync(x => x.UserId == userId.Value);
            var loggedDates = mealLogs
                .Where(x => x.LoggedAt.HasValue)
                .Select(x => ToVietnamDate(x.LoggedAt!.Value))
                .Where(x => x <= todayDate)
                .Distinct()
                .OrderBy(x => x)
                .ToList();

            var plans = (await _unitOfWork.MealPlanHeaders.FindAsync(x => x.UserId == userId.Value)).ToList();
            var planIds = plans.Select(x => x.Id).ToList();
            var planItems = planIds.Count == 0
                ? new List<MealPlanItem>()
                : (await _unitOfWork.MealPlanItems.FindAsync(x => planIds.Contains(x.MealPlanId))).ToList();

            var trackedDates = loggedDates
                .Concat(planItems
                    .Where(x => x.IsCompleted && x.PlannedDate.HasValue && x.PlannedDate.Value <= todayDate)
                    .Select(x => x.PlannedDate!.Value))
                .Distinct()
                .ToHashSet();

            var activePlanIds = plans.Where(x => x.IsActive).Select(x => x.Id).ToHashSet();
            var hasPlanForToday = plans.Any(x => x.IsActive && x.StartDate == todayDate)
                || planItems.Any(x => activePlanIds.Contains(x.MealPlanId) && x.PlannedDate == todayDate);
            if (hasPlanForToday)
            {
                trackedDates.Add(todayDate);
            }

            var orderedTrackedDates = trackedDates.OrderBy(x => x).ToList();

            int currentStreak = 0;
            int bestStreak = 0;

            if (orderedTrackedDates.Any())
            {
                // Calculate current streak
                var yesterday = todayDate.AddDays(-1);

                if (orderedTrackedDates.Last() == todayDate || orderedTrackedDates.Last() == yesterday)
                {
                    currentStreak = 1;
                    for (int i = orderedTrackedDates.Count - 2; i >= 0; i--)
                    {
                        if (orderedTrackedDates[i + 1].DayNumber - orderedTrackedDates[i].DayNumber == 1)
                        {
                            currentStreak++;
                        }
                        else
                        {
                            break;
                        }
                    }
                }

                // Calculate best streak
                int currentRunning = 0;
                DateOnly? prevDate = null;

                foreach (var date in orderedTrackedDates)
                {
                    if (prevDate == null)
                    {
                        currentRunning = 1;
                    }
                    else
                    {
                        var diff = date.DayNumber - prevDate.Value.DayNumber;
                        if (diff == 1)
                        {
                            currentRunning++;
                        }
                        else if (diff > 1)
                        {
                            if (currentRunning > bestStreak)
                            {
                                bestStreak = currentRunning;
                            }
                            currentRunning = 1;
                        }
                    }
                    prevDate = date;
                }

                if (currentRunning > bestStreak)
                {
                    bestStreak = currentRunning;
                }
            }

            // Calculate weekly adherence rate
            var sevenDaysAgo = todayDate.AddDays(-6);
            var recentPlanItems = planItems
                .Where(x => x.PlannedDate >= sevenDaysAgo && x.PlannedDate <= todayDate)
                .ToList();

            var totalItems = recentPlanItems.Count;
            var completedItems = recentPlanItems.Count(x => x.IsCompleted);

            decimal weeklyAdherenceRate = 0;
            if (totalItems > 0)
            {
                weeklyAdherenceRate = Math.Round((decimal)completedItems / totalItems * 100, 2);
            }
            else
            {
                // Fallback to daily planning/logging consistency.
                var trackedDaysLast7 = orderedTrackedDates
                    .Count(x => x >= sevenDaysAgo && x <= todayDate);
                weeklyAdherenceRate = Math.Round((decimal)trackedDaysLast7 / 7 * 100, 2);
            }

            return new MealPlanStreakResponse
            {
                CurrentStreakDays = currentStreak,
                BestStreakDays = bestStreak,
                LastTrackedDate = orderedTrackedDates.Count > 0 ? orderedTrackedDates[^1] : null,
                TotalTrackedDays = orderedTrackedDates.Count,
                WeeklyAdherenceRate = weeklyAdherenceRate
            };
        }

        private static decimal CalculateRatio(int actual, int planned)
        {
            return planned <= 0 ? 0 : Math.Round((decimal)actual / planned, 4);
        }

        private static DateOnly ToVietnamDate(DateTime utcDateTime)
        {
            var normalizedUtc = utcDateTime.Kind == DateTimeKind.Utc
                ? utcDateTime
                : DateTime.SpecifyKind(utcDateTime, DateTimeKind.Utc);
            return DateOnly.FromDateTime(normalizedUtc.AddHours(VietnamUtcOffsetHours));
        }

        private async Task ReplaceItemsAsync(Guid mealPlanId, IEnumerable<MealPlanItemUpsertRequest> items, DateOnly? defaultDate)
        {
            foreach (var item in items)
            {
                await _unitOfWork.MealPlanItems.AddAsync(new MealPlanItem
                {
                    Id = Guid.NewGuid(),
                    MealPlanId = mealPlanId,
                    MealType = item.MealType,
                    FoodId = item.FoodId,
                    RecipeId = item.RecipeId,
                    PlannedDate = item.PlannedDate ?? defaultDate,
                    ScheduledTime = item.ScheduledTime,
                    TargetCalories = item.TargetCalories,
                    IsCompleted = item.IsCompleted,
                    CreatedAt = DateTime.UtcNow
                });
            }

            await _unitOfWork.CompleteAsync();
        }

        private async Task<MealPlanHeader> GetMealPlanAsync(Guid id, Guid? userId = null)
        {
            var entity = await _unitOfWork.MealPlanHeaders.GetByIdAsync(id);
            if (entity == null) throw new Exception("Meal plan not found.");
            if (userId.HasValue && userId.Value != Guid.Empty && entity.UserId != userId.Value)
            {
                throw new Exception("Forbidden.");
            }
            return entity;
        }

        private async Task<MealPlanItem> GetPlanItemAsync(Guid planId, Guid itemId, Guid? userId = null)
        {
            _ = await GetMealPlanAsync(planId, userId);
            var item = await _unitOfWork.MealPlanItems.GetByIdAsync(itemId);
            if (item == null || item.MealPlanId != planId) throw new Exception("Meal plan item not found.");
            return item;
        }

        private void ValidateItems(IEnumerable<MealPlanItemUpsertRequest> items)
        {
            if (items == null) throw new Exception("Meal plan items cannot be null.");
            foreach (var item in items) ValidateItem(item);
        }

        private static void ValidateItem(MealPlanItemUpsertRequest item)
        {
            if (item.FoodId == null && item.RecipeId == null && string.IsNullOrWhiteSpace(item.CustomName))
            {
                throw new Exception("Each meal plan item must have either FoodId, RecipeId, or CustomName.");
            }
        }

        private async Task<MealPlanResponse> MapAsync(MealPlanHeader entity)
        {
            var items = await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == entity.Id);
            var itemsList = items.ToList();
            
            // Batch fetch all Foods and Recipes to avoid N+1 queries
            var foodIds = itemsList.Where(x => x.FoodId.HasValue).Select(x => x.FoodId!.Value).Distinct().ToList();
            var recipeIds = itemsList.Where(x => x.RecipeId.HasValue).Select(x => x.RecipeId!.Value).Distinct().ToList();
            
            // A scoped UnitOfWork shares one DbContext, so its queries must not
            // run concurrently. Batch each data set and await it sequentially.
            var foods = await _unitOfWork.Foods.FindAsync(f => foodIds.Contains(f.Id));
            var recipes = await _unitOfWork.Recipes.FindAsync(r => recipeIds.Contains(r.Id));
            var foodDict = foods.GroupBy(f => f.Id).ToDictionary(g => g.Key, g => g.First());
            var recipeDict = recipes.GroupBy(r => r.Id).ToDictionary(g => g.Key, g => g.First());
            var recipeMacrosDict = await GetRecipeMacrosBatchAsync(recipeIds);
            
            var responseItems = new List<MealPlanItemResponse>();
            decimal totalProtein = 0;
            decimal totalCarbs = 0;
            decimal totalFat = 0;
            decimal totalCalories = 0;

            foreach (var item in itemsList)
            {
                var mappedItem = await MapItemWithCacheAsync(item, foodDict, recipeDict);
                responseItems.Add(mappedItem);

                if (item.IsCompleted)
                {
                    var macros = GetItemMacrosFromCache(item, foodDict, recipeMacrosDict);
                    totalProtein += macros.protein;
                    totalCarbs += macros.carbs;
                    totalFat += macros.fat;
                    totalCalories += macros.calories;
                }
            }

            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == entity.UserId);
            var healthProfile = healthProfiles.FirstOrDefault();

            var durationDays = 1;
            if (entity.StartDate.HasValue && entity.EndDate.HasValue)
            {
                durationDays = entity.EndDate.Value.DayNumber - entity.StartDate.Value.DayNumber + 1;
            }

            var targetProtein = healthProfile != null ? (healthProfile.TargetProteinG ?? 120) * durationDays : 120 * durationDays;
            var targetCarbs = healthProfile != null ? (healthProfile.TargetCarbsG ?? 250) * durationDays : 250 * durationDays;
            var targetFat = healthProfile != null ? (healthProfile.TargetFatG ?? 60) * durationDays : 60 * durationDays;

            return new MealPlanResponse
            {
                Id = entity.Id,
                Title = entity.Title ?? string.Empty,
                PlanType = entity.PlanType,
                StartDate = entity.StartDate,
                EndDate = entity.EndDate,
                TargetCalories = entity.TargetCalories,
                GeneratedBy = entity.GeneratedBy,
                Status = entity.Status,
                ApprovedAt = entity.ApprovedAt,
                IsActive = entity.IsActive,
                TotalCalories = (int)Math.Round(totalCalories),
                TotalProteinG = (int)Math.Round(totalProtein),
                TotalCarbsG = (int)Math.Round(totalCarbs),
                TotalFatG = (int)Math.Round(totalFat),
                TargetProteinG = targetProtein,
                TargetCarbsG = targetCarbs,
                TargetFatG = targetFat,
                Items = responseItems
            };
        }

        private async Task<Dictionary<Guid, (decimal protein, decimal carbs, decimal fat, decimal calories)>>
            GetRecipeMacrosBatchAsync(IEnumerable<Guid> recipeIds)
        {
            var ids = recipeIds.Distinct().ToList();
            var macrosByRecipe = ids.ToDictionary(
                id => id,
                _ => (protein: 0m, carbs: 0m, fat: 0m, calories: 0m));
            if (ids.Count == 0) return macrosByRecipe;

            var recipes = (await _unitOfWork.Recipes.FindAsync(r => ids.Contains(r.Id))).GroupBy(r => r.Id).ToDictionary(g => g.Key, g => g.First());
            var recipeIngredients = await _unitOfWork.RecipeIngredients.FindAsync(
                item => ids.Contains(item.RecipeId));
            var ingredientIds = recipeIngredients
                .Select(item => item.IngredientId)
                .Distinct()
                .ToList();

            var ingredientsById = ingredientIds.Count > 0
                ? (await _unitOfWork.Ingredients.FindAsync(item => ingredientIds.Contains(item.Id))).ToDictionary(item => item.Id)
                : new Dictionary<Guid, Ingredient>();

            foreach (var recipeIngredient in recipeIngredients)
            {
                if (!macrosByRecipe.TryGetValue(recipeIngredient.RecipeId, out var current)
                    || !ingredientsById.TryGetValue(recipeIngredient.IngredientId, out var ingredient))
                {
                    continue;
                }

                var quantity = recipeIngredient.Quantity ?? 1;
                var scale = global::MenuGreen.BusinessLogicLayer.Helpers.NutritionMath
                    .IngredientNutritionRatio(quantity, recipeIngredient.Unit ?? ingredient.UnitDefault);

                macrosByRecipe[recipeIngredient.RecipeId] = (
                    current.protein + (ingredient.ProteinG ?? 0) * scale,
                    current.carbs + (ingredient.CarbsG ?? 0) * scale,
                    current.fat + (ingredient.FatG ?? 0) * scale,
                    current.calories + (ingredient.CaloriesKcal ?? 0) * scale);
            }

            foreach (var id in ids)
            {
                var m = macrosByRecipe[id];
                if (recipes.TryGetValue(id, out var recipe))
                {
                    var servings = Math.Max(1, recipe.Servings ?? 1);
                    m = (
                        m.protein / servings,
                        m.carbs / servings,
                        m.fat / servings,
                        m.calories / servings);

                    if (m.calories == 0 && recipe.FoodId.HasValue)
                    {
                        var food = await _unitOfWork.Foods.GetByIdAsync(recipe.FoodId.Value);
                        if (food != null)
                        {
                            m = (
                                food.ProteinG ?? 0,
                                food.CarbsG ?? 0,
                                food.FatG ?? 0,
                                food.CaloriesKcal ?? 0);
                        }
                    }

                    macrosByRecipe[id] = m;
                }
            }

            return macrosByRecipe;
        }
        
        private async Task<MealPlanItemResponse> MapItemWithCacheAsync(
            MealPlanItem x, 
            Dictionary<Guid, Food> foodDict, 
            Dictionary<Guid, Recipe> recipeDict)
        {
            Food? food = x.FoodId.HasValue && foodDict.TryGetValue(x.FoodId.Value, out var f) ? f : null;
            Recipe? recipe = x.RecipeId.HasValue && recipeDict.TryGetValue(x.RecipeId.Value, out var r) ? r : null;

            var price = food?.EstimatedPriceVnd
                ?? (recipe == null ? null : RecipeServingPrice(recipe));
            
            var macros = await GetItemMacrosAsync(x);

            var displayCalories = (food?.CaloriesKcal.HasValue == true && food.CaloriesKcal.Value > 0)
                ? (int)Math.Round(food.CaloriesKcal.Value)
                : (x.TargetCalories.HasValue && x.TargetCalories.Value > 0 ? x.TargetCalories.Value : (int)Math.Round(macros.calories));

            if (displayCalories == 0 && recipe != null && recipe.FoodId.HasValue)
            {
                var linkedFood = await _unitOfWork.Foods.GetByIdAsync(recipe.FoodId.Value);
                if (linkedFood?.CaloriesKcal.HasValue == true && linkedFood.CaloriesKcal.Value > 0)
                {
                    displayCalories = (int)Math.Round(linkedFood.CaloriesKcal.Value);
                }
            }

            return new MealPlanItemResponse
            {
                Id = x.Id,
                MealPlanId = x.MealPlanId,
                MealType = x.MealType,
                FoodId = x.FoodId,
                RecipeId = x.RecipeId,
                PlannedDate = x.PlannedDate,
                ScheduledTime = x.ScheduledTime,
                TargetCalories = displayCalories > 0 ? displayCalories : null,
                QuantityG = x.QuantityG,
                ProteinG = (int)Math.Round(x.ProteinG.HasValue && x.ProteinG.Value > 0 ? x.ProteinG.Value : macros.protein),
                CarbsG = (int)Math.Round(x.CarbsG.HasValue && x.CarbsG.Value > 0 ? x.CarbsG.Value : macros.carbs),
                FatG = (int)Math.Round(x.FatG.HasValue && x.FatG.Value > 0 ? x.FatG.Value : macros.fat),
                CustomName = x.CustomName,
                FoodName = food?.NameVi ?? recipe?.Title ?? x.CustomName ?? "Unknown",
                SourceEntityType = x.SourceType ?? (x.FoodId.HasValue ? "Food" : x.RecipeId.HasValue ? "Recipe" : null),
                EstimatedPriceVnd = price,
                Origin = x.Origin
            };
        }
        
        private (decimal protein, decimal carbs, decimal fat, decimal calories) GetItemMacrosFromCache(
            MealPlanItem item,
            Dictionary<Guid, Food> foodDict,
            Dictionary<Guid, (decimal protein, decimal carbs, decimal fat, decimal calories)> recipeMacrosDict)
        {
            if (item.FoodId.HasValue && foodDict.TryGetValue(item.FoodId.Value, out var food))
            {
                return (
                    food.ProteinG ?? 0,
                    food.CarbsG ?? 0,
                    food.FatG ?? 0,
                    food.CaloriesKcal ?? 0
                );
            }
            else if (item.RecipeId.HasValue && recipeMacrosDict.TryGetValue(item.RecipeId.Value, out var macros))
            {
                return macros;
            }

            return (0, 0, 0, 0);
        }

        private async Task<(decimal protein, decimal carbs, decimal fat, decimal calories)> GetItemMacrosAsync(MealPlanItem item)
        {
            if (item.FoodId.HasValue)
            {
                var food = await _unitOfWork.Foods.GetByIdAsync(item.FoodId.Value);
                if (food != null)
                {
                    return (
                        food.ProteinG ?? 0,
                        food.CarbsG ?? 0,
                        food.FatG ?? 0,
                        food.CaloriesKcal ?? 0
                    );
                }
            }

            if (item.RecipeId.HasValue)
            {
                var recipe = await _unitOfWork.Recipes.GetByIdAsync(item.RecipeId.Value);
                var recipeIngredients = await _unitOfWork.RecipeIngredients.FindAsync(
                    ri => ri.RecipeId == item.RecipeId.Value);

                if (recipeIngredients != null && recipeIngredients.Any())
                {
                    decimal totalProtein = 0;
                    decimal totalCarbs = 0;
                    decimal totalFat = 0;
                    decimal totalCalories = 0;

                    foreach (var ri in recipeIngredients)
                    {
                        var ingredient = await _unitOfWork.Ingredients.GetByIdAsync(ri.IngredientId);
                        if (ingredient != null)
                        {
                            var quantity = ri.Quantity ?? 1;
                            var scale = global::MenuGreen.BusinessLogicLayer.Helpers.NutritionMath
                                .IngredientNutritionRatio(quantity, ri.Unit ?? ingredient.UnitDefault);

                            totalProtein += (ingredient.ProteinG ?? 0) * scale;
                            totalCarbs += (ingredient.CarbsG ?? 0) * scale;
                            totalFat += (ingredient.FatG ?? 0) * scale;
                            totalCalories += (ingredient.CaloriesKcal ?? 0) * scale;
                        }
                    }

                    var servings = recipe?.Servings > 0 ? recipe.Servings.Value : 1;
                    return (
                        totalProtein / servings,
                        totalCarbs / servings,
                        totalFat / servings,
                        totalCalories / servings
                    );
                }

                if (recipe?.FoodId != null)
                {
                    var linkedFood = await _unitOfWork.Foods.GetByIdAsync(recipe.FoodId.Value);
                    if (linkedFood != null)
                    {
                        return (
                            linkedFood.ProteinG ?? 0,
                            linkedFood.CarbsG ?? 0,
                            linkedFood.FatG ?? 0,
                            linkedFood.CaloriesKcal ?? 0
                        );
                    }
                }
            }

            return (0, 0, 0, 0);
        }

        private async Task<MealPlanItemResponse> MapItemAsync(MealPlanItem x)
        {
            Food? food = null;
            Recipe? recipe = null;

            if (x.FoodId.HasValue)
            {
                food = await _unitOfWork.Foods.GetByIdAsync(x.FoodId.Value);
            }
            if (x.RecipeId.HasValue)
            {
                recipe = await _unitOfWork.Recipes.GetByIdAsync(x.RecipeId.Value);
            }

            var price = food?.EstimatedPriceVnd ?? recipe?.EstimatedPriceVnd;
            var macros = await GetItemMacrosAsync(x);

            var cal = (x.TargetCalories.HasValue && x.TargetCalories.Value > 0)
                ? x.TargetCalories.Value
                : (int)Math.Round(macros.calories);

            if (cal == 0 && recipe?.FoodId != null)
            {
                var linkedFood = await _unitOfWork.Foods.GetByIdAsync(recipe.FoodId.Value);
                if (linkedFood?.CaloriesKcal.HasValue == true && linkedFood.CaloriesKcal.Value > 0)
                {
                    cal = (int)Math.Round(linkedFood.CaloriesKcal.Value);
                }
            }

            return new MealPlanItemResponse
            {
                Id = x.Id,
                MealPlanId = x.MealPlanId,
                MealType = x.MealType,
                FoodId = x.FoodId,
                RecipeId = x.RecipeId,
                PlannedDate = x.PlannedDate,
                ScheduledTime = x.ScheduledTime,
                TargetCalories = cal > 0 ? cal : null,
                IsCompleted = x.IsCompleted,
                CustomName = x.CustomName,
                FoodName = food?.NameVi ?? recipe?.Title ?? x.CustomName,
                RecipeName = recipe?.Title,
                SourceEntityType = x.SourceType ?? (x.FoodId.HasValue ? "Food" : x.RecipeId.HasValue ? "Recipe" : null),
                Status = x.IsCompleted ? "done" : "planned",
                EstimatedPriceVnd = price,
                ProteinG = (int)Math.Round(x.ProteinG.HasValue && x.ProteinG.Value > 0 ? x.ProteinG.Value : macros.protein),
                CarbsG = (int)Math.Round(x.CarbsG.HasValue && x.CarbsG.Value > 0 ? x.CarbsG.Value : macros.carbs),
                FatG = (int)Math.Round(x.FatG.HasValue && x.FatG.Value > 0 ? x.FatG.Value : macros.fat),
                Origin = x.Origin
            };
        }

        private static MealLogResponse MapLog(MealLog x)
        {
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
                MealPlanItemId = x.MealPlanItemId,
                IsFromMealPlan = x.IsFromMealPlan
            };
        }

        public async Task<MealPlanResponse> GenerateByBudgetAsync(Guid userId)
        {
            var budgets = await _unitOfWork.BudgetRequests.FindAsync(x => x.UserId == userId);
            var latestBudget = budgets.OrderByDescending(b => b.CreatedAt).FirstOrDefault();
            if (latestBudget == null)
            {
                throw new Exception("Please set up a budget (Budget Request) before automatically generating a plan.");
            }

            var weeklyBudget = latestBudget.BudgetVnd ?? 1500000;
            if (weeklyBudget <= 0)
            {
                throw new Exception("Ngân sách tuần phải lớn hơn 0.");
            }

            var isOfficeUser = string.Equals((await _unitOfWork.UserAiProfiles.FindAsync(x => x.UserId == userId))
                .FirstOrDefault()?.EatingPattern?.Trim().Trim('"'), "office", StringComparison.OrdinalIgnoreCase);

            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId);
            var healthProfile = healthProfiles.FirstOrDefault();
            var targetCalories = healthProfile?.TargetCalories ?? 2000;

            var today = DateOnly.FromDateTime(DateTime.UtcNow.AddHours(VietnamUtcOffsetHours));
            var startDate = today.AddDays(1);
            var endDate = startDate.AddDays(6);

            // A rebuild for the same week should be a meaningful alternative,
            // not a newly-created copy of the exact same roadmap.
            var generatedPlansForWeek = await _unitOfWork.MealPlanHeaders.FindAsync(x =>
                x.UserId == userId &&
                x.GeneratedBy == "AI_BUDGET_AWARE" &&
                x.StartDate == startDate &&
                x.EndDate == endDate);
            var previousPlanIds = generatedPlansForWeek.Select(x => x.Id).ToList();
            var previousItems = previousPlanIds.Any()
                ? await _unitOfWork.MealPlanItems.FindAsync(x => previousPlanIds.Contains(x.MealPlanId))
                : Enumerable.Empty<MealPlanItem>();
            var previousRecipeIds = previousItems
                .Where(x => x.RecipeId.HasValue)
                .Select(x => x.RecipeId!.Value)
                .ToHashSet();
            var previousFoodIds = previousItems
                .Where(x => x.FoodId.HasValue)
                .Select(x => x.FoodId!.Value)
                .ToHashSet();
            var rebuildSequence = generatedPlansForWeek.Count();

            var allFoods = (await _unitOfWork.Foods.GetAllAsync()).Where(f => f.IsActive == true || f.IsActive == null).ToList();
            var allRecipes = (await _unitOfWork.Recipes.GetAllAsync()).Where(r => r.IsActive == true || r.IsActive == null).ToList();

            var userAllergies = await _unitOfWork.UserAllergies.FindAsync(ua => ua.UserId == userId);
            var allergyIds = userAllergies.Select(ua => ua.AllergyId).ToList();
            if (allergyIds.Any())
            {
                var foodAllergies = await _unitOfWork.FoodAllergies.FindAsync(fa => allergyIds.Contains(fa.AllergyId));
                var forbiddenFoodIds = foodAllergies.Select(fa => fa.FoodId).ToHashSet();
                allFoods = allFoods.Where(f => !forbiddenFoodIds.Contains(f.Id)).ToList();
                allRecipes = allRecipes.Where(r => !r.FoodId.HasValue || !forbiddenFoodIds.Contains(r.FoodId.Value)).ToList();
            }

            // The budget is applied while selecting meals, not merely displayed after generation.
            // A recipe is selected once per week whenever the catalog has enough candidates.
            var usedRecipeIds = new HashSet<Guid>();
            var usedFoodIds = new HashSet<Guid>();
            var recipeUseCounts = new Dictionary<Guid, int>();
            var foodUseCounts = new Dictionary<Guid, int>();
            var generatedItems = new List<MealPlanItem>();
            var remainingWeeklyBudget = weeklyBudget;
            var weeklyRemainder = weeklyBudget % 7;
            var maxCookingMinutes = latestBudget.TimeLimitMin ?? 45;
            var mealSlots = new[]
            {
                (Type: "breakfast", CalorieRatio: 0.25m, BudgetRatio: 0.25m, Time: new TimeOnly(7, 30)),
                (Type: "lunch", CalorieRatio: 0.35m, BudgetRatio: 0.40m, Time: new TimeOnly(12, 0)),
                (Type: "dinner", CalorieRatio: 0.30m, BudgetRatio: 0.35m, Time: new TimeOnly(18, 30))
            };

            for (var d = 0; d < 7; d++)
            {
                var currentDate = startDate.AddDays(d);
                var remainingDailyBudget = weeklyBudget / 7 + (d < weeklyRemainder ? 1 : 0);

                foreach (var slot in mealSlots)
                {
                    var targetCaloriesForMeal = (int)Math.Round(targetCalories * slot.CalorieRatio);
                    var targetBudgetForMeal = Math.Max(1, (int)Math.Round((weeklyBudget / 7m) * slot.BudgetRatio));
                    // Keep each meal within its allocated share. Unused money remains
                    // in the weekly budget rather than allowing breakfast to consume lunch's budget.
                    var allowedBudget = Math.Min(targetBudgetForMeal, Math.Min(remainingDailyBudget, remainingWeeklyBudget));

                    var recipeCandidates = allRecipes
                        .Where(r => r.MealType != null && r.MealType.Contains(slot.Type, StringComparison.OrdinalIgnoreCase))
                        .Where(r => (r.TotalTimeMin ?? r.CookTimeMin ?? 30) <= maxCookingMinutes)
                        .Where(r => RecipeServingPrice(r) <= allowedBudget)
                        .ToList();
                    var unusedRecipeCandidates = recipeCandidates
                        .Where(r => !usedRecipeIds.Contains(r.Id))
                        .ToList();
                    var recipePool = unusedRecipeCandidates.Any() ? unusedRecipeCandidates : recipeCandidates;
                    // Prefer dishes not used by an earlier version of this
                    // week's plan. When the catalog is too small, rotate the
                    // eligible candidates so a rebuild still varies the menu.
                    var newRecipePool = recipePool
                        .Where(r => !previousRecipeIds.Contains(r.Id))
                        .ToList();
                    if (newRecipePool.Any()) recipePool = newRecipePool;
                    var orderedRecipePool = recipePool
                        .OrderBy(r => recipeUseCounts.GetValueOrDefault(r.Id))
                        .ThenBy(r => Math.Abs(RecipeServingPrice(r) - targetBudgetForMeal))
                        .ThenBy(r => Math.Abs((r.TotalTimeMin ?? r.CookTimeMin ?? 30) - maxCookingMinutes))
                        .ThenBy(r => r.Title)
                        .ToList();
                    var selectedRecipe = orderedRecipePool.Count == 0
                        ? null
                        : orderedRecipePool[(rebuildSequence + d) % orderedRecipePool.Count];

                    Guid? recipeId = selectedRecipe?.Id;
                    Guid? foodId = null;
                    var selectedPrice = 0;
                    var selectedCalories = targetCaloriesForMeal;

                    if (selectedRecipe != null)
                    {
                        selectedPrice = RecipeServingPrice(selectedRecipe);
                        selectedCalories = await GetRecipeCaloriesAsync(selectedRecipe.Id);
                        usedRecipeIds.Add(selectedRecipe.Id);
                        recipeUseCounts[selectedRecipe.Id] = recipeUseCounts.GetValueOrDefault(selectedRecipe.Id) + 1;
                    }
                    else
                    {
                        var foodCandidates = allFoods
                            .Where(f => f.CaloriesKcal.HasValue)
                            .Where(f => (f.EstimatedPriceVnd ?? 0) <= allowedBudget)
                            .ToList();
                        var unusedFoodCandidates = foodCandidates.Where(f => !usedFoodIds.Contains(f.Id)).ToList();
                        var foodPool = unusedFoodCandidates.Any() ? unusedFoodCandidates : foodCandidates;
                        var newFoodPool = foodPool.Where(f => !previousFoodIds.Contains(f.Id)).ToList();
                        if (newFoodPool.Any()) foodPool = newFoodPool;
                        var orderedFoodPool = foodPool
                            .OrderBy(f => foodUseCounts.GetValueOrDefault(f.Id))
                            .ThenBy(f => Math.Abs((f.EstimatedPriceVnd ?? 0) - targetBudgetForMeal))
                            .ThenBy(f => Math.Abs((int)(f.CaloriesKcal ?? 0) - targetCaloriesForMeal))
                            .ThenBy(f => f.NameVi)
                            .ToList();
                        var selectedFood = orderedFoodPool.Count == 0
                            ? null
                            : orderedFoodPool[(rebuildSequence + d) % orderedFoodPool.Count];

                        if (selectedFood != null)
                        {
                            foodId = selectedFood.Id;
                            selectedPrice = selectedFood.EstimatedPriceVnd ?? 0;
                            selectedCalories = (int)(selectedFood.CaloriesKcal ?? 0);
                            usedFoodIds.Add(selectedFood.Id);
                            foodUseCounts[selectedFood.Id] = foodUseCounts.GetValueOrDefault(selectedFood.Id) + 1;
                        }
                    }

                    if (recipeId == null && foodId == null)
                    {
                        throw new Exception($"Không tìm thấy món {slot.Type} phù hợp với ngân sách còn lại và thời gian nấu đã đặt.");
                    }

                    generatedItems.Add(new MealPlanItem
                    {
                        Id = Guid.NewGuid(),
                        MealType = slot.Type,
                        FoodId = foodId,
                        RecipeId = recipeId,
                        PlannedDate = currentDate,
                        ScheduledTime = slot.Time,
                        TargetCalories = selectedCalories,
                        IsCompleted = false,
                        CreatedAt = DateTime.UtcNow,
                        Origin = "budget_ai"
                    });

                    remainingDailyBudget -= selectedPrice;
                    remainingWeeklyBudget -= selectedPrice;
                }
            }

            // Regenerating the same week replaces the old generated plan instead of
            // accumulating several active Office plans for the same date range.
            foreach (var existingPlan in generatedPlansForWeek.Where(x => x.IsActive))
            {
                existingPlan.IsActive = false;
                existingPlan.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.MealPlanHeaders.Update(existingPlan);
            }

            var mealPlanHeader = new MealPlanHeader
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = isOfficeUser
                    ? $"Cơm hộp văn phòng ({startDate:dd/MM} - {endDate:dd/MM})"
                    : $"Cơm hộp theo ngân sách ({startDate:dd/MM} - {endDate:dd/MM})",
                PlanType = "weekly",
                StartDate = startDate,
                EndDate = endDate,
                TargetCalories = targetCalories,
                GeneratedBy = "AI_BUDGET_AWARE",
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MealPlanHeaders.AddAsync(mealPlanHeader);
            foreach (var item in generatedItems)
            {
                item.MealPlanId = mealPlanHeader.Id;
                await _unitOfWork.MealPlanItems.AddAsync(item);
            }
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(mealPlanHeader.Id);
        }

        public async Task<GroceryListResponse> GetGroceryListAsync(Guid planId, Guid userId)
        {
            var plan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(planId)
                ?? throw new Exception("Meal plan not found.");
            if (plan.UserId != userId) throw new Exception("Forbidden.");

            var planItems = (await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == planId)).ToList();
            var recipeIds = planItems
                .Where(x => x.RecipeId.HasValue).Select(x => x.RecipeId!.Value).Distinct().ToList();
            var ingredients = await _unitOfWork.RecipeIngredients.FindAsync(x => recipeIds.Contains(x.RecipeId));
            var ingredientsList = ingredients.ToList();
            // Batch load all recipes for servings (fix N+1 query)
            var recipesById = new Dictionary<Guid, Recipe>();
            if (recipeIds.Any())
            {
                var recipes = await _unitOfWork.Recipes.FindAsync(r => recipeIds.Contains(r.Id));
                foreach (var recipe in recipes)
                {
                    if (recipe != null) recipesById[recipe.Id] = recipe;
                }
            }
            var catalog = await _unitOfWork.Ingredients.GetAllAsync();
            var catalogById = catalog.ToDictionary(x => x.Id);
            var items = ingredientsList.GroupBy(x => new { x.IngredientId, Unit = x.Unit ?? "unit" })
                .Select(group =>
                {
                    catalogById.TryGetValue(group.Key.IngredientId, out var ingredient);
                    return new GroceryListItemResponse
                    {
                        IngredientId = group.Key.IngredientId,
                        Name = ingredient?.NameVi ?? "Nguyên liệu",
                        Quantity = group.Sum(x => x.Quantity ?? 0), Unit = group.Key.Unit,
                        EstimatedPriceVnd = ingredient?.EstimatedPriceVnd ?? 0
                    };
                }).OrderBy(x => x.Name).ToList();

            // Phase 1: group ingredients by PlannedDate so the UI can show a
            // separate shopping card per day instead of one flat weekly list.
            var days = await _groceryListBuilder.BuildDaysAsync(
                planId,
                planItems,
                ingredientsList,
                recipesById,
                catalogById);

            // Phase 2: roll the per-day view into chợ visits. Stock items
            // (rice/spices/...) go to an InitialTrip dated the day before the
            // plan starts; other items follow PlannedDate - 1.
            var shoppingTrips = await _shoppingTripBuilder.BuildShoppingTripsAsync(
                planItems,
                days,
                catalogById);

            return new GroceryListResponse
            {
                MealPlanId = planId,
                Items = items,
                Days = days,
                ShoppingTrips = shoppingTrips,
                EstimatedTotalVnd = items.Sum(x => x.EstimatedPriceVnd),
            };
        }

        public async Task<BudgetStatusResponse> GetBudgetStatusAsync(Guid planId, Guid userId)
        {
            var plan = await GetMealPlanAsync(planId, userId);
            var planItems = await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == planId);

            // Batch load all foods and recipes to fix N+1 queries
            var foodIds = planItems.Where(x => x.FoodId.HasValue).Select(x => x.FoodId!.Value).ToList();
            var recipeIds = planItems.Where(x => x.RecipeId.HasValue).Select(x => x.RecipeId!.Value).ToList();

            var foods = (await _unitOfWork.Foods.FindAsync(f => foodIds.Contains(f.Id)))
                .ToDictionary(f => f.Id);
            var recipes = (await _unitOfWork.Recipes.FindAsync(r => recipeIds.Contains(r.Id)))
                .ToDictionary(r => r.Id);

            var totalPlannedCost = 0;
            foreach (var item in planItems)
            {
                if (item.FoodId.HasValue && foods.TryGetValue(item.FoodId.Value, out var food))
                {
                    totalPlannedCost += food?.EstimatedPriceVnd ?? 0;
                }
                else if (item.RecipeId.HasValue && recipes.TryGetValue(item.RecipeId.Value, out var recipe))
                {
                    totalPlannedCost += recipe == null ? 0 : RecipeServingPrice(recipe);
                }
            }

            var budgets = await _unitOfWork.BudgetRequests.FindAsync(x => x.UserId == userId);
            var latestBudget = budgets.OrderByDescending(b => b.CreatedAt).FirstOrDefault();
            var budgetLimit = latestBudget?.BudgetVnd ?? 1500000;

            var status = totalPlannedCost <= budgetLimit ? "WithinBudget" : "ExceededBudget";
            var exceededAmount = Math.Max(0, totalPlannedCost - budgetLimit);

            return new BudgetStatusResponse
            {
                MealPlanId = planId,
                BudgetLimit = budgetLimit,
                PlannedCost = totalPlannedCost,
                Status = status,
                ExceededAmount = exceededAmount
            };
        }

        public async Task<IEnumerable<MealPlanItemResponse>> GetAlternativesAsync(Guid planId, Guid itemId, Guid userId)
        {
            var currentItem = await GetPlanItemAsync(planId, itemId, userId);
            var currentCal = currentItem.TargetCalories ?? 500;
            var currentPrice = 0;

            if (currentItem.FoodId.HasValue)
            {
                var food = await _unitOfWork.Foods.GetByIdAsync(currentItem.FoodId.Value);
                currentPrice = food?.EstimatedPriceVnd ?? 50000;
            }
            else if (currentItem.RecipeId.HasValue)
            {
                var recipe = await _unitOfWork.Recipes.GetByIdAsync(currentItem.RecipeId.Value);
                currentPrice = recipe == null ? 0 : RecipeServingPrice(recipe);
            }

            var result = new List<MealPlanItemResponse>();
            var planItems = (await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == planId)).ToList();
            var normalizedMealType = (currentItem.MealType ?? "lunch").ToLowerInvariant();
            var sameDayRecipeIds = planItems
                .Where(x => x.Id != itemId &&
                            x.PlannedDate == currentItem.PlannedDate &&
                            x.RecipeId.HasValue)
                .Select(x => x.RecipeId!.Value)
                .ToHashSet();
            var recipeUseCounts = planItems
                .Where(x => x.Id != itemId && x.RecipeId.HasValue)
                .GroupBy(x => x.RecipeId!.Value)
                .ToDictionary(group => group.Key, group => group.Count());
            var budgets = await _unitOfWork.BudgetRequests.FindAsync(x => x.UserId == userId);
            var latestBudget = budgets.OrderByDescending(x => x.CreatedAt).FirstOrDefault();
            var budgetLimit = latestBudget?.BudgetVnd ?? int.MaxValue;
            var maxCookingMinutes = latestBudget?.TimeLimitMin ?? int.MaxValue;

            // Batch load all recipes to fix N+1 query
            var recipeIdsInPlan = planItems.Where(x => x.RecipeId.HasValue).Select(x => x.RecipeId!.Value).ToHashSet();
            var allRecipes = (await _unitOfWork.Recipes.FindAsync(r => recipeIdsInPlan.Contains(r.Id)))
                .ToDictionary(r => r.Id);
            var currentPlanCost = 0;
            foreach (var planItem in planItems.Where(x => x.RecipeId.HasValue))
            {
                if (allRecipes.TryGetValue(planItem.RecipeId!.Value, out var recipe))
                {
                    currentPlanCost += recipe == null ? 0 : RecipeServingPrice(recipe);
                }
            }
            var maximumReplacementPrice = Math.Max(0, budgetLimit - (currentPlanCost - currentPrice));

            if (currentItem.RecipeId.HasValue)
            {
                var recipes = await _unitOfWork.Recipes.FindAsync(r => 
                    r.MealType != null && r.MealType.ToLower() == normalizedMealType &&
                    r.Id != currentItem.RecipeId &&
                    (r.TotalTimeMin ?? r.CookTimeMin ?? 30) <= maxCookingMinutes &&
                    (r.IsActive == true || r.IsActive == null));

                var recipesForDifferentDay = recipes
                    .Where(r => !sameDayRecipeIds.Contains(r.Id))
                    .ToList();
                var alternativeRecipes = (recipesForDifferentDay.Any()
                        ? recipesForDifferentDay
                        : recipes.ToList())
                    .OrderBy(r => recipeUseCounts.GetValueOrDefault(r.Id))
                    .ThenBy(r => Math.Abs(RecipeServingPrice(r) - currentPrice))
                    .ThenBy(r => RecipeServingPrice(r))
                    .ThenBy(r => r.Title)
                    .Take(5);
                foreach (var r in alternativeRecipes)
                {
                    result.Add(new MealPlanItemResponse
                    {
                        Id = Guid.Empty,
                        MealPlanId = planId,
                        MealType = currentItem.MealType,
                        RecipeId = r.Id,
                        RecipeName = r.Title,
                        SourceEntityType = "Recipe",
                        TargetCalories = currentCal,
                        EstimatedPriceVnd = RecipeServingPrice(r),
                        Status = "alternative"
                    });
                }
            }
            else if (currentItem.FoodId.HasValue)
            {
                var foods = await _unitOfWork.Foods.FindAsync(f => 
                    f.Id != currentItem.FoodId &&
                    f.EstimatedPriceVnd.HasValue &&
                    (f.IsActive == true || f.IsActive == null));

                var alternativeFoods = foods
                    .OrderBy(f => Math.Abs((f.EstimatedPriceVnd ?? 0) - currentPrice))
                    .ThenBy(f => f.EstimatedPriceVnd)
                    .ThenBy(f => f.NameVi)
                    .Take(5);
                foreach (var f in alternativeFoods)
                {
                    result.Add(new MealPlanItemResponse
                    {
                        Id = Guid.Empty,
                        MealPlanId = planId,
                        MealType = currentItem.MealType,
                        FoodId = f.Id,
                        FoodName = f.NameVi,
                        SourceEntityType = "Food",
                        TargetCalories = currentCal,
                        EstimatedPriceVnd = f.EstimatedPriceVnd,
                        Status = "alternative"
                    });
                }
            }

            return result;
        }

        public async Task<ExpenseCompareResponse> CompareExpensesAsync(DateOnly from, DateOnly to, Guid userId)
        {
            var budgets = await _unitOfWork.BudgetRequests.FindAsync(x => x.UserId == userId);
            var latestBudget = budgets.OrderByDescending(b => b.CreatedAt).FirstOrDefault();
            var weeklyBudget = latestBudget?.BudgetVnd ?? 1500000;
            
            var totalDays = Math.Max(1, (to.ToDateTime(TimeOnly.MinValue) - from.ToDateTime(TimeOnly.MinValue)).Days + 1);
            var budgetLimit = (weeklyBudget / 7) * totalDays;

            var planItems = await _unitOfWork.MealPlanItems.FindAsync(x => 
                x.PlannedDate >= from && x.PlannedDate <= to &&
                x.MealPlanHeader != null && x.MealPlanHeader.UserId == userId);
            
            var plannedCost = 0;
            var actualExpense = 0;

            foreach (var item in planItems)
            {
                var price = 0;
                if (item.FoodId.HasValue)
                {
                    var food = await _unitOfWork.Foods.GetByIdAsync(item.FoodId.Value);
                    price = food?.EstimatedPriceVnd ?? 0;
                }
                else if (item.RecipeId.HasValue)
                {
                    var recipe = await _unitOfWork.Recipes.GetByIdAsync(item.RecipeId.Value);
                    price = recipe?.EstimatedPriceVnd ?? 0;
                }

                plannedCost += price;
                if (item.IsCompleted)
                {
                    actualExpense += price;
                }
            }

            return new ExpenseCompareResponse
            {
                From = from,
                To = to,
                BudgetLimit = budgetLimit,
                PlannedCost = plannedCost,
                ActualExpense = actualExpense
            };
        }

        public async Task<ExpenseBreakdownResponse> GetExpenseBreakdownAsync(Guid userId)
        {
            var plans = await _unitOfWork.MealPlanHeaders.FindAsync(x => x.UserId == userId && x.IsActive);
            var activePlan = plans.OrderByDescending(x => x.CreatedAt).FirstOrDefault();
            
            var breakdownDict = new Dictionary<string, int>();
            
            if (activePlan != null)
            {
                var items = await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == activePlan.Id);

                // Batch load all foods and recipes to fix N+1 queries
                var foodIds = items.Where(x => x.FoodId.HasValue).Select(x => x.FoodId!.Value).ToList();
                var recipeIds = items.Where(x => x.RecipeId.HasValue).Select(x => x.RecipeId!.Value).ToList();

                var foods = (await _unitOfWork.Foods.FindAsync(f => foodIds.Contains(f.Id)))
                    .ToDictionary(f => f.Id);
                var recipes = (await _unitOfWork.Recipes.FindAsync(r => recipeIds.Contains(r.Id)))
                    .ToDictionary(r => r.Id);

                foreach (var item in items)
                {
                    var price = 0;
                    var category = "Other";

                    if (item.FoodId.HasValue && foods.TryGetValue(item.FoodId.Value, out var food))
                    {
                        price = food?.EstimatedPriceVnd ?? 0;
                        category = "Fresh ingredients";
                    }
                    else if (item.RecipeId.HasValue && recipes.TryGetValue(item.RecipeId.Value, out var recipe))
                    {
                        price = recipe?.EstimatedPriceVnd ?? 0;
                        category = recipe?.MealType ?? "Main dishes";
                    }

                    if (price > 0)
                    {
                        if (breakdownDict.ContainsKey(category))
                            breakdownDict[category] += price;
                        else
                            breakdownDict[category] = price;
                    }
                }
            }

            var total = breakdownDict.Values.Sum();
            var categories = breakdownDict.Select(kvp => new ExpenseCategoryBreakdownDto
            {
                Category = kvp.Key,
                Amount = kvp.Value,
                Percentage = total == 0 ? 0 : Math.Round((double)kvp.Value / total * 100, 2)
            }).ToList();

            var savingTips = new List<string>
            {
                "Prioritize seasonal produce to save up to 15% on total food expenses.",
                "Replace meat-heavy meals with plant-based protein sources like tofu or soybeans.",
                "Use the alternatives feature for any over-budget items to optimize spending."
            };

            return new ExpenseBreakdownResponse
            {
                Categories = categories,
                SavingTips = savingTips
            };
        }

        public async Task<BudgetAdherenceResponse> GetAdherenceScoresAsync(Guid userId)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var fromDate = today.AddDays(-30);

            var budgets = await _unitOfWork.BudgetRequests.FindAsync(x => x.UserId == userId);
            var latestBudget = budgets.OrderByDescending(b => b.CreatedAt).FirstOrDefault();
            var weeklyBudget = latestBudget?.BudgetVnd ?? 1500000;
            var dailyBudgetLimit = weeklyBudget / 7;

            var completedItems = await _unitOfWork.MealPlanItems.FindAsync(x =>
                x.PlannedDate >= fromDate && x.PlannedDate <= today &&
                x.MealPlanHeader != null && x.MealPlanHeader.UserId == userId &&
                x.IsCompleted);

            // Batch load all foods and recipes to fix N+1 queries
            var foodIds = completedItems.Where(x => x.FoodId.HasValue).Select(x => x.FoodId!.Value).ToList();
            var recipeIds = completedItems.Where(x => x.RecipeId.HasValue).Select(x => x.RecipeId!.Value).ToList();

            var foods = (await _unitOfWork.Foods.FindAsync(f => foodIds.Contains(f.Id)))
                .ToDictionary(f => f.Id);
            var recipes = (await _unitOfWork.Recipes.FindAsync(r => recipeIds.Contains(r.Id)))
                .ToDictionary(r => r.Id);

            var dailySpent = new Dictionary<DateOnly, int>();
            foreach (var item in completedItems)
            {
                if (!item.PlannedDate.HasValue) continue;

                var price = 0;
                if (item.FoodId.HasValue && foods.TryGetValue(item.FoodId.Value, out var food))
                {
                    price = food?.EstimatedPriceVnd ?? 0;
                }
                else if (item.RecipeId.HasValue && recipes.TryGetValue(item.RecipeId.Value, out var recipe))
                {
                    price = recipe?.EstimatedPriceVnd ?? 0;
                }

                if (dailySpent.ContainsKey(item.PlannedDate.Value))
                    dailySpent[item.PlannedDate.Value] += price;
                else
                    dailySpent[item.PlannedDate.Value] = price;
            }

            var withinBudgetDays = 0;
            var totalEvaluatedDays = dailySpent.Count;

            foreach (var kvp in dailySpent)
            {
                if (kvp.Value <= dailyBudgetLimit)
                {
                    withinBudgetDays++;
                }
            }

            var adherenceScore = totalEvaluatedDays == 0 ? 100 : (withinBudgetDays * 100 / totalEvaluatedDays);
            var feedback = adherenceScore >= 80 
                ? "Excellent! You are sticking to your budget very well." 
                : (adherenceScore >= 50 ? "Good progress! Consider substituting expensive items to save more." : "Warning: You have exceeded your budget for many days.");

            return new BudgetAdherenceResponse
            {
                AdherenceScore = adherenceScore,
                WithinBudgetDays = withinBudgetDays,
                TotalEvaluatedDays = totalEvaluatedDays,
                FeedbackMessage = feedback
            };
        }

        // ==================== Daily Meal Plan Implementations ====================

        public async Task<MealPlanResponse?> GetByDateAsync(Guid userId, DateOnly date)
        {
            var cacheKey = CacheKeys.MealPlanByDate(userId, date);
            var cached = await _cache.GetAsync<MealPlanResponse>(cacheKey);
            if (cached != null)
            {
                return cached;
            }

            var plan = await FindDailyPlanAsync(userId, date);
            if (plan == null) return null;
            var response = await MapAsync(plan);
            if (response.Items != null)
            {
                response.Items = response.Items.Where(x => x.PlannedDate == null || x.PlannedDate == date).ToList();
            }

            await _cache.SetAsync(cacheKey, response, MealPlanTtl);
            return response;
        }

        public async Task<MealPlanAdherenceResponse> GetAdherenceAsync(Guid userId, DateOnly date)
        {
            var plan = await FindDailyPlanAsync(userId, date);
            if (plan == null)
            {
                return new MealPlanAdherenceResponse
                {
                    Date = date,
                    PlannedKcal = 0,
                    ActualKcal = 0,
                    DeviationPercent = null,
                    CompletedCount = 0,
                    TotalCount = 0
                };
            }

            var items = (await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == plan.Id && (x.PlannedDate == null || x.PlannedDate == date))).ToList();
            var itemIds = items.Select(x => x.Id).ToList();

            var logs = new List<MealLog>();
            if (itemIds.Count > 0)
            {
                logs = (await _unitOfWork.MealLogs.FindAsync(
                    x => x.UserId == userId
                        && x.MealPlanItemId.HasValue
                        && itemIds.Contains(x.MealPlanItemId.Value))).ToList();
            }

            var plannedKcal = items.Sum(x => x.TargetCalories ?? 0);
            var actualKcal = (decimal)logs.Sum(x => x.CaloriesKcal ?? 0);
            decimal? deviation = plannedKcal > 0
                ? Math.Round((actualKcal - (decimal)plannedKcal) / (decimal)plannedKcal * 100m, 2)
                : null;

            return new MealPlanAdherenceResponse
            {
                Date = date,
                PlannedKcal = plannedKcal,
                ActualKcal = actualKcal,
                DeviationPercent = deviation,
                CompletedCount = items.Count(x => x.IsCompleted),
                TotalCount = items.Count
            };
        }

        public async Task<MealPlanResponse> CreateOrUpdateDailyAsync(Guid userId, UserMealPlanUpsertRequest request)
        {
            ValidateItems(request.Items);
            // Mutations must only reuse an exact DAILY plan. The read helper
            // may fall back to a weekly/monthly plan covering the date; using
            // that fallback here would convert an older approved range into a
            // daily plan and incorrectly preserve its approval state.
            var plan = await FindExactDailyPlanAsync(userId, request.PlannedDate);
            if (plan == null)
            {
                plan = new MealPlanHeader
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Title = request.Title ?? $"Daily plan {request.PlannedDate:yyyy-MM-dd}",
                    PlanType = "DAILY",
                    StartDate = request.PlannedDate,
                    EndDate = request.PlannedDate,
                    TargetCalories = request.TargetCalories,
                    GeneratedBy = "USER",
                    Status = "Active",
                    ApprovedAt = null,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.MealPlanHeaders.AddAsync(plan);
                await _unitOfWork.CompleteAsync();
            }
            else
            {
                plan.Title = request.Title ?? plan.Title;
                plan.PlanType = "DAILY";
                plan.StartDate = request.PlannedDate;
                plan.EndDate = request.PlannedDate;
                plan.TargetCalories = request.TargetCalories ?? plan.TargetCalories;
                // Any Gymer-side change creates a new revision that must be
                // reviewed again. Do not keep the approval of an older version.
                plan.GeneratedBy = "USER";
                plan.Status = "Active";
                plan.ApprovedAt = null;
                plan.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.MealPlanHeaders.Update(plan);
                await _unitOfWork.CompleteAsync();

                var existingItems = await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == plan.Id);
                _unitOfWork.MealPlanItems.RemoveRange(existingItems);
                await _unitOfWork.CompleteAsync();
            }

            await AddDailyItemsAsync(plan.Id, request.PlannedDate, request.Items);
            return (await GetByDateAsync(userId, request.PlannedDate))!;
        }

        public async Task<MealPlanResponse> CreateFromDailyMenuAsync(Guid userId, CreateMealPlanFromDailyMenuRequest request)
        {
            var items = request.Items.Select(x => new MealPlanItemUpsertRequest
            {
                MealType = NormalizeMealType(x.MealType),
                FoodId = x.FoodId,
                RecipeId = x.RecipeId,
                PlannedDate = request.PlannedDate,
                ScheduledTime = x.ScheduledTime,
                TargetCalories = x.TargetCalories,
                IsCompleted = false,
                Origin = x.Origin
            }).ToList();

            return await CreateOrUpdateDailyAsync(userId, new UserMealPlanUpsertRequest
            {
                PlannedDate = request.PlannedDate,
                TargetCalories = request.TargetCalories,
                Title = $"Daily plan {request.PlannedDate:yyyy-MM-dd}",
                Items = items
            });
        }

        public async Task<CompleteMealPlanItemResponse> CompleteItemAsync(
            Guid userId,
            Guid itemId,
            CompleteMealPlanItemRequest request)
        {
            var item = await _unitOfWork.MealPlanItems.GetByIdAsync(itemId)
                ?? throw new Exception("Meal plan item not found.");

            var plan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(item.MealPlanId)
                ?? throw new Exception("Meal plan not found.");

            if (plan.UserId != userId) throw new Exception("Forbidden.");

            var existingLogs = await _unitOfWork.MealLogs.FindAsync(
                x => x.MealPlanItemId == itemId && x.UserId == userId);
            var existingLog = existingLogs
                .OrderByDescending(x => x.LoggedAt)
                .FirstOrDefault();
            if (existingLog != null)
            {
                item.IsCompleted = true;
                _unitOfWork.MealPlanItems.Update(item);
                await _unitOfWork.CompleteAsync();
                return new CompleteMealPlanItemResponse
                {
                    Item = await MapItemAsync(item, existingLog.Id),
                    MealLog = await _nutritionTracking.GetMealLogAsync(userId, existingLog.Id)
                };
            }

            if (!item.FoodId.HasValue && !item.RecipeId.HasValue)
            {
                throw new Exception("Meal plan item must have FoodId or RecipeId.");
            }

            var quantity = request.QuantityG ?? 100m;
            var mealLogRequest = new MealLogUpsertRequest
            {
                FoodId = item.FoodId,
                RecipeId = item.RecipeId,
                MealType = item.MealType ?? "snack",
                QuantityG = quantity,
                Notes = "Logged from meal plan.",
                LoggedAt = ResolveMealLogUtc(item),
                MealPlanItemId = item.Id
            };

            var mealLog = await _nutritionTracking.CreateMealLogAsync(userId, mealLogRequest);
            item.IsCompleted = true;
            _unitOfWork.MealPlanItems.Update(item);
            await _unitOfWork.CompleteAsync();

            return new CompleteMealPlanItemResponse
            {
                Item = await MapItemAsync(item, mealLog.Id),
                MealLog = mealLog
            };
        }

        private async Task AddDailyItemsAsync(Guid mealPlanId, DateOnly plannedDate, IEnumerable<MealPlanItemUpsertRequest> items)
        {
            foreach (var item in items)
            {
                if (item.FoodId.HasValue)
                {
                    var food = await _unitOfWork.Foods.GetByIdAsync(item.FoodId.Value);
                    if (food == null)
                    {
                        var dummyFood = new Food
                        {
                            Id = item.FoodId.Value,
                            NameVi = "Món ăn gợi ý (AI)",
                            CaloriesKcal = item.TargetCalories,
                            IsActive = true,
                            CreatedAt = DateTime.UtcNow
                        };
                        await _unitOfWork.Foods.AddAsync(dummyFood);
                        await _unitOfWork.CompleteAsync();
                    }
                }

                if (item.RecipeId.HasValue)
                {
                    var recipe = await _unitOfWork.Recipes.GetByIdAsync(item.RecipeId.Value);
                    if (recipe == null)
                    {
                        var dummyRecipe = new Recipe
                        {
                            Id = item.RecipeId.Value,
                            Title = "Công thức gợi ý (AI)",
                            IsActive = true,
                            CreatedAt = DateTime.UtcNow
                        };
                        await _unitOfWork.Recipes.AddAsync(dummyRecipe);
                        await _unitOfWork.CompleteAsync();
                    }
                }

                var planItem = new MealPlanItem
                {
                    Id = Guid.NewGuid(),
                    MealPlanId = mealPlanId,
                    MealType = NormalizeMealType(item.MealType),
                    FoodId = item.FoodId,
                    RecipeId = item.RecipeId,
                    PlannedDate = item.PlannedDate ?? plannedDate,
                    ScheduledTime = item.ScheduledTime,
                    TargetCalories = item.TargetCalories,
                    IsCompleted = item.IsCompleted,
                    Origin = item.Origin,
                    CreatedAt = DateTime.UtcNow
                };
                await _unitOfWork.MealPlanItems.AddAsync(planItem);
            }

            await _unitOfWork.CompleteAsync();
        }

        private async Task<MealPlanHeader?> FindDailyPlanAsync(Guid userId, DateOnly date)
        {
            var plans = await _unitOfWork.MealPlanHeaders.FindAsync(x =>
                x.UserId == userId
                && x.IsActive
                && x.Status != "Draft"
                && x.Status != "PendingAcceptance"
                && x.Status != "Rejected"
                && ((x.PlanType == null || x.PlanType.ToUpper() == "DAILY")
                    ? x.StartDate == date
                    : (x.StartDate <= date && x.EndDate >= date)));

            return plans.OrderByDescending(x => (x.PlanType == null || x.PlanType.ToUpper() == "DAILY") ? 1 : 0)
                        .ThenByDescending(x => x.UpdatedAt ?? x.CreatedAt)
                        .FirstOrDefault();
        }

        private async Task<MealPlanHeader?> FindExactDailyPlanAsync(
            Guid userId,
            DateOnly date)
        {
            var plans = await _unitOfWork.MealPlanHeaders.FindAsync(x =>
                x.UserId == userId
                && x.IsActive
                && x.Status != "Draft"
                && (x.PlanType == null || x.PlanType.ToUpper() == "DAILY")
                && x.StartDate == date);

            return plans
                .OrderByDescending(x => x.UpdatedAt ?? x.CreatedAt)
                .FirstOrDefault();
        }

        private async Task<int> GetRecipeCaloriesAsync(Guid recipeId)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(recipeId);
            if (recipe == null) return 0;

            var recipeIngredients = await _unitOfWork.RecipeIngredients.FindAsync(ri => ri.RecipeId == recipeId);
            if (!recipeIngredients.Any())
            {
                if (!recipe.FoodId.HasValue) return 0;
                var linkedFood = await _unitOfWork.Foods.GetByIdAsync(recipe.FoodId.Value);
                return linkedFood?.CaloriesKcal is > 0
                    ? (int)Math.Round(linkedFood.CaloriesKcal.Value)
                    : 0;
            }

            // Batch load all ingredients in one query to avoid N+1 problem
            var ingredientIds = recipeIngredients.Select(ri => ri.IngredientId).ToList();
            var ingredientsQuery = await _unitOfWork.Ingredients.FindAsync(i => ingredientIds.Contains(i.Id));
            var ingredients = ingredientsQuery.ToList();
            var ingredientDict = ingredients.ToDictionary(i => i.Id);

            decimal totalCalories = 0;

            foreach (var ri in recipeIngredients)
            {
                if (ingredientDict.TryGetValue(ri.IngredientId, out var ingredient))
                {
                    var quantity = ri.Quantity ?? 1;
                    var scale = global::MenuGreen.BusinessLogicLayer.Helpers.NutritionMath
                        .IngredientNutritionRatio(quantity, ri.Unit ?? ingredient.UnitDefault);
                    totalCalories += (ingredient.CaloriesKcal ?? 0) * scale;
                }
            }

            if (totalCalories <= 0 && recipe.FoodId.HasValue)
            {
                var linkedFood = await _unitOfWork.Foods.GetByIdAsync(recipe.FoodId.Value);
                if (linkedFood?.CaloriesKcal is > 0)
                {
                    return (int)Math.Round(linkedFood.CaloriesKcal.Value);
                }
            }

            return (int)Math.Round(totalCalories / Math.Max(1, recipe.Servings ?? 1));
        }

        private static int RecipeServingPrice(Recipe recipe)
        {
            if (recipe.EstimatedPriceVnd.HasValue && recipe.EstimatedPriceVnd.Value > 0)
            {
                var servings = Math.Max(1, recipe.Servings ?? 1);
                return (int)Math.Round((double)recipe.EstimatedPriceVnd.Value / servings);
            }
            return 0;
        }

        private static string NormalizeMealType(string mealType)
        {
            var normalized = (mealType ?? string.Empty).Trim().ToLowerInvariant();
            return normalized switch
            {
                "breakfast" or "lunch" or "dinner" or "snack" => normalized,
                "bữa sáng" or "bua sang" => "breakfast",
                "bữa trưa" or "bua trua" => "lunch",
                "bữa tối" or "bua toi" => "dinner",
                "bữa phụ" or "bua phu" => "snack",
                _ => normalized.Length > 0 ? normalized : "snack"
            };
        }

        private static DateTime ResolveMealLogUtc(MealPlanItem item)
        {
            var nowUtc = DateTime.UtcNow;
            if (!item.PlannedDate.HasValue)
            {
                return nowUtc;
            }

            var todayInVietnam = DateOnly.FromDateTime(nowUtc.AddHours(VietnamUtcOffsetHours));
            var plannedDate = item.PlannedDate.Value;
            if (plannedDate > todayInVietnam)
            {
                throw new InvalidOperationException("A future meal cannot be marked as eaten.");
            }

            if (plannedDate == todayInVietnam)
            {
                return nowUtc;
            }

            // Use noon in Vietnam for a historical correction. This keeps the
            // log unambiguously inside the intended local calendar date.
            return plannedDate
                .ToDateTime(new TimeOnly(12, 0), DateTimeKind.Utc)
                .AddHours(-VietnamUtcOffsetHours);
        }

        public async Task<CompleteMealPlanItemResponse> ToggleItemAsync(Guid userId, Guid itemId, bool isCompleted)
        {
            var item = await _unitOfWork.MealPlanItems.GetByIdAsync(itemId)
                ?? throw new Exception("Meal plan item not found.");

            var plan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(item.MealPlanId)
                ?? throw new Exception("Meal plan not found.");

            if (plan.UserId != userId) throw new Exception("Forbidden.");

            var existingLogs = (await _unitOfWork.MealLogs.FindAsync(
                    x => x.MealPlanItemId == itemId && x.UserId == userId))
                .OrderByDescending(x => x.LoggedAt)
                .ToList();
            var existingLog = existingLogs.FirstOrDefault();

            if (isCompleted)
            {
                item.IsCompleted = true;
                _unitOfWork.MealPlanItems.Update(item);

                Guid? mealLogId = null;
                MealLogResponse? mealLogRes = null;

                if (existingLog == null)
                {
                    if (!item.FoodId.HasValue && !item.RecipeId.HasValue)
                    {
                        throw new Exception("Meal plan item must have FoodId or RecipeId.");
                    }

                    var mealLogRequest = new MealLogUpsertRequest
                    {
                        FoodId = item.FoodId,
                        RecipeId = item.RecipeId,
                        MealType = item.MealType ?? "snack",
                        QuantityG = 100m,
                        Notes = "Logged from meal plan.",
                        LoggedAt = ResolveMealLogUtc(item),
                        MealPlanItemId = item.Id
                    };
                    mealLogRes = await _nutritionTracking.CreateMealLogAsync(userId, mealLogRequest);
                    mealLogId = mealLogRes.Id;
                }
                else
                {
                    mealLogId = existingLog.Id;
                    mealLogRes = await _nutritionTracking.GetMealLogAsync(userId, existingLog.Id);
                }

                await _unitOfWork.CompleteAsync();
                return new CompleteMealPlanItemResponse
                {
                    Item = await MapItemAsync(item, mealLogId),
                    MealLog = mealLogRes
                };
            }
            else
            {
                item.IsCompleted = false;
                _unitOfWork.MealPlanItems.Update(item);

                foreach (var log in existingLogs)
                {
                    await _nutritionTracking.DeleteMealLogAsync(userId, log.Id);
                }

                await _unitOfWork.CompleteAsync();
                return new CompleteMealPlanItemResponse
                {
                    Item = await MapItemAsync(item, null),
                    MealLog = null
                };
            }
        }

        private async Task<MealPlanItemResponse> MapItemAsync(MealPlanItem item, Guid? mealLogId)
        {
            Food? food = null;
            Recipe? recipe = null;
            if (item.FoodId.HasValue) food = await _unitOfWork.Foods.GetByIdAsync(item.FoodId.Value);
            if (item.RecipeId.HasValue) recipe = await _unitOfWork.Recipes.GetByIdAsync(item.RecipeId.Value);

            if (!mealLogId.HasValue)
            {
                var logs = await _unitOfWork.MealLogs.FindAsync(x => x.MealPlanItemId == item.Id);
                mealLogId = logs.FirstOrDefault()?.Id;
            }

            var price = food?.EstimatedPriceVnd ?? recipe?.EstimatedPriceVnd;
            var macros = await GetItemMacrosAsync(item);

            return new MealPlanItemResponse
            {
                Id = item.Id,
                MealPlanId = item.MealPlanId,
                MealType = item.MealType,
                FoodId = item.FoodId,
                RecipeId = item.RecipeId,
                PlannedDate = item.PlannedDate,
                ScheduledTime = item.ScheduledTime,
                TargetCalories = item.TargetCalories ?? (int)Math.Round(macros.calories),
                IsCompleted = item.IsCompleted,
                MealLogId = mealLogId,
                FoodName = food?.NameVi,
                RecipeName = recipe?.Title,
                SourceEntityType = item.FoodId.HasValue ? "Food" : item.RecipeId.HasValue ? "Recipe" : null,
                Status = item.IsCompleted ? "done" : "planned",
                EstimatedPriceVnd = price,
                ProteinG = (int)Math.Round(macros.protein),
                CarbsG = (int)Math.Round(macros.carbs),
                FatG = (int)Math.Round(macros.fat),
                Origin = item.Origin
            };
        }

        public async Task<OfficeScanMealResponse> SaveOfficeScanMealAsync(Guid planId, OfficeScanMealRequest request, Guid userId)
        {
            var plan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(planId);
            if (plan == null || plan.UserId != userId)
                throw new UnauthorizedAccessException("Meal plan not found or access denied.");

            var mealLog = new MealLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                MealType = request.MealType,
                LoggedAt = request.LoggedAt ?? DateTime.UtcNow,
                QuantityG = request.QuantityG,
                CaloriesKcal = request.CaloriesKcal,
                ProteinG = request.ProteinG,
                CarbsG = request.CarbsG,
                FatG = request.FatG,
                CustomName = request.CustomName,
                SourceType = "office_scan"
            };

            var item = new MealPlanItem
            {
                Id = Guid.NewGuid(),
                MealPlanId = planId,
                FoodId = null,
                RecipeId = null,
                MealType = request.MealType,
                PlannedDate = request.PlannedDate,
                ScheduledTime = request.ScheduledTime,
                TargetCalories = (int)request.CaloriesKcal,
                IsCompleted = true,
                CustomName = request.CustomName,
                Origin = "office_scan"
            };

            await _unitOfWork.MealLogs.AddAsync(mealLog);
            await _unitOfWork.MealPlanItems.AddAsync(item);
            await _unitOfWork.CompleteAsync();

            return new OfficeScanMealResponse
            {
                MealPlanId = planId,
                MealPlanItemId = item.Id,
                MealLogId = mealLog.Id,
                ReplacedExisting = false,
                DisplayName = request.CustomName
            };
        }

        public async Task<MealPlanItemResponse> SaveOfficeScanPlanItemAsync(
            Guid planId,
            OfficeScanMealRequest request,
            Guid userId,
            bool isPriorityLunch)
        {
            if (isPriorityLunch && !string.Equals(request.MealType, "lunch", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Món ưu tiên chỉ áp dụng cho bữa trưa.");

            var plan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(planId);
            if (plan == null || plan.UserId != userId)
                throw new UnauthorizedAccessException("Meal plan not found or access denied.");

            var origin = isPriorityLunch ? "office_priority" : "office_scan";
            var existing = (await _unitOfWork.MealPlanItems.FindAsync(x =>
                    x.MealPlanId == planId &&
                    x.PlannedDate == request.PlannedDate &&
                    x.MealType != null &&
                    x.MealType.ToLower() == request.MealType.ToLower() &&
                    x.Origin == origin))
                .FirstOrDefault();

            if (existing != null && !request.ReplaceExisting)
                throw new InvalidOperationException("Ngày này đã có món được chọn. Hãy xác nhận thay món hiện tại.");

            var snapshot = System.Text.Json.JsonSerializer.Serialize(request.Ingredients);
            var item = existing ?? new MealPlanItem
            {
                Id = Guid.NewGuid(),
                MealPlanId = planId,
                CreatedAt = DateTime.UtcNow,
                Origin = origin
            };

            item.MealType = request.MealType.ToLowerInvariant();
            item.PlannedDate = request.PlannedDate;
            item.ScheduledTime = request.ScheduledTime ?? new TimeOnly(12, 0);
            item.TargetCalories = (int)Math.Round(request.CaloriesKcal);
            item.QuantityG = request.QuantityG;
            item.ProteinG = request.ProteinG;
            item.CarbsG = request.CarbsG;
            item.FatG = request.FatG;
            item.CustomName = request.CustomName.Trim();
            item.SourceType = "AiScan";
            item.IngredientSnapshotJson = snapshot;
            item.IsCompleted = false;

            if (existing == null)
                await _unitOfWork.MealPlanItems.AddAsync(item);
            else
                _unitOfWork.MealPlanItems.Update(item);

            await _unitOfWork.CompleteAsync();
            return await MapItemAsync(item);
        }

        public async Task LinkMealLogToDailyPlanAsync(Guid userId, Guid mealLogId)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow.AddHours(VietnamUtcOffsetHours));
            var dailyPlan = await GetOrCreateTodayDailyPlanAsync(userId);

            var mealLog = await _unitOfWork.MealLogs.GetByIdAsync(mealLogId);
            if (mealLog == null || mealLog.UserId != userId)
                throw new Exception("Meal log not found.");

            var item = new MealPlanItem
            {
                Id = Guid.NewGuid(),
                MealPlanId = dailyPlan.Id,
                MealType = mealLog.MealType,
                PlannedDate = today,
                IsCompleted = true,
                TargetCalories = (int)(mealLog.CaloriesKcal ?? 0),
                CustomName = mealLog.CustomName,
                Origin = "user",
                SourceType = "meal_log"
            };

            await _unitOfWork.MealPlanItems.AddAsync(item);
            await _unitOfWork.CompleteAsync();
        }

        private async Task<MealPlanHeader> GetOrCreateTodayDailyPlanAsync(Guid userId)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow.AddHours(VietnamUtcOffsetHours));
            var plans = await _unitOfWork.MealPlanHeaders
                .FindAsync(x => x.UserId == userId && x.PlanType == "DAILY" && x.StartDate == today);

            var existing = plans.FirstOrDefault();
            if (existing != null)
                return existing;

            var plan = new MealPlanHeader
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = $"Thực đơn ngày {today:dd/MM/yyyy}",
                PlanType = "DAILY",
                StartDate = today,
                EndDate = today,
                IsActive = true,
                GeneratedBy = "SYSTEM"
            };

            await _unitOfWork.MealPlanHeaders.AddAsync(plan);
            await _unitOfWork.CompleteAsync();
            return plan;
        }

        private async Task InvalidateMealPlanCacheAsync(Guid? userId)
        {
            if (!userId.HasValue || userId.Value == Guid.Empty) return;
            // Invalidate today and next 7 days
            var today = DateOnly.FromDateTime(DateTime.UtcNow.AddHours(VietnamUtcOffsetHours));
            for (int i = 0; i < 7; i++)
            {
                var date = today.AddDays(i);
                await _cache.RemoveAsync(CacheKeys.MealPlanByDate(userId.Value, date));
            }
        }
    }
}
