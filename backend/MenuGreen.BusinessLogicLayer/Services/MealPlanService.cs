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
    public class MealPlanService : IMealPlanService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INutritionTrackingService _nutritionTracking;

        public MealPlanService(IUnitOfWork unitOfWork, INutritionTrackingService nutritionTracking)
        {
            _unitOfWork = unitOfWork;
            _nutritionTracking = nutritionTracking;
        }

        public async Task<IEnumerable<MealPlanResponse>> GetAllAsync(bool? isActive = null)
        {
            var plans = await _unitOfWork.MealPlanHeaders.GetAllAsync();
            if (isActive.HasValue)
            {
                plans = plans.Where(x => x.IsActive == isActive.Value);
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

        public async Task<MealPlanResponse> GetByIdAsync(Guid id)
        {
            var entity = await GetMealPlanAsync(id);
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
            return await GetByIdAsync(entity.Id);
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
            return await GetByIdAsync(entity.Id);
        }

        public async Task<MealPlanResponse> UpdateAsync(Guid id, MealPlanUpsertRequest request, Guid? userId = null)
        {
            var entity = await GetMealPlanAsync(id);

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

            return await GetByIdAsync(entity.Id);
        }

        public async Task DeleteAsync(Guid id, Guid? userId = null)
        {
            var entity = await GetMealPlanAsync(id);
            entity.IsActive = false;
            _unitOfWork.MealPlanHeaders.Update(entity);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<MealPlanResponse> UpdateStatusAsync(Guid id, MealPlanStatusRequest request, Guid? userId = null)
        {
            var entity = await GetMealPlanAsync(id);
            entity.IsActive = request.IsActive;
            entity.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.MealPlanHeaders.Update(entity);
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(id);
        }

        public async Task<MealPlanDistributionResponse> DistributeAsync(Guid id, string targetAudience, string? notes = null, Guid? userId = null)
        {
            var entity = await GetMealPlanAsync(id);
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
            var plan = await GetMealPlanAsync(planId);

            var item = new MealPlanItem
            {
                Id = Guid.NewGuid(),
                MealPlanId = plan.Id,
                MealType = request.MealType,
                FoodId = request.FoodId,
                RecipeId = request.RecipeId,
                PlannedDate = request.PlannedDate ?? plan.StartDate,
                ScheduledTime = request.ScheduledTime,
                TargetCalories = request.TargetCalories,
                IsCompleted = request.IsCompleted,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MealPlanItems.AddAsync(item);
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(planId);
        }

        public async Task<MealPlanResponse> UpdateItemAsync(Guid planId, Guid itemId, MealPlanItemUpsertRequest request, Guid? userId = null)
        {
            ValidateItem(request);
            var item = await GetPlanItemAsync(planId, itemId);
            item.MealType = request.MealType;
            item.FoodId = request.FoodId;
            item.RecipeId = request.RecipeId;
            item.PlannedDate = request.PlannedDate;
            item.ScheduledTime = request.ScheduledTime;
            item.TargetCalories = request.TargetCalories;
            item.IsCompleted = request.IsCompleted;
            _unitOfWork.MealPlanItems.Update(item);
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(planId);
        }

        public async Task DeleteItemAsync(Guid planId, Guid itemId, Guid? userId = null)
        {
            var item = await GetPlanItemAsync(planId, itemId);
            _unitOfWork.MealPlanItems.Remove(item);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<MealPlanResponse> UpdateItemStatusAsync(Guid planId, Guid itemId, MealPlanStatusRequest request, Guid? userId = null)
        {
            var item = await GetPlanItemAsync(planId, itemId);
            item.IsCompleted = request.IsActive;
            _unitOfWork.MealPlanItems.Update(item);
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(planId);
        }

        public async Task<MealLogResponse> ConvertItemToLogAsync(Guid planId, Guid itemId, MealPlanConvertToLogRequest request, Guid? userId = null)
        {
            var item = await GetPlanItemAsync(planId, itemId);

            var mealLogRequest = new MealLogUpsertRequest
            {
                FoodId = item.FoodId,
                RecipeId = item.RecipeId,
                MealType = item.MealType ?? "snack",
                QuantityG = 100,
                Notes = request.Notes ?? "Logged from meal plan.",
                LoggedAt = request.LoggedAt ?? DateTime.UtcNow,
                MealPlanItemId = item.Id
            };

            var mealLog = await _nutritionTracking.CreateMealLogAsync(userId ?? Guid.Empty, mealLogRequest);
            item.IsCompleted = true;
            _unitOfWork.MealPlanItems.Update(item);
            await _unitOfWork.CompleteAsync();

            return mealLog;
        }

        public async Task<MealPlanResponse> CommitAsync(Guid planId, MealPlanCommitRequest request, Guid? userId = null)
        {
            var plan = await GetMealPlanAsync(planId);
            plan.IsActive = false;
            plan.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.MealPlanHeaders.Update(plan);
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(planId);
        }

        public async Task<MealPlanResponse> DuplicateAsync(Guid planId, MealPlanDuplicateRequest request, Guid? userId = null)
        {
            var source = await GetMealPlanAsync(planId);
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
                    CreatedAt = DateTime.UtcNow
                });
            }
            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(newPlan.Id);
        }

        public async Task<MealPlanDashboardResponse> GetDashboardAsync(DateOnly date, Guid? userId = null)
        {
            var planItems = await _unitOfWork.MealPlanItems.FindAsync(x => x.PlannedDate == date);
            var logs = await _unitOfWork.MealLogs.FindAsync(x => x.LoggedAt.HasValue && DateOnly.FromDateTime(x.LoggedAt.Value) == date);
            var itemList = planItems.ToList();
            var logList = logs.ToList();
            var actualByItem = logList
                .Where(x => x.MealPlanItemId.HasValue)
                .ToDictionary(x => x.MealPlanItemId!.Value, x => x.Id);

            foreach (var item in itemList)
            {
                if (actualByItem.ContainsKey(item.Id))
                {
                    item.IsCompleted = true;
                }
            }

            return new MealPlanDashboardResponse
            {
                Date = date,
                TotalPlannedCalories = itemList.Sum(x => x.TargetCalories ?? 0),
                TotalActualCalories = (int)logList.Sum(x => x.CaloriesKcal ?? 0),
                PlannedItemsCount = itemList.Count,
                CompletedItemsCount = itemList.Count(x => x.IsCompleted),
                SkippedItemsCount = itemList.Count(x => !x.IsCompleted && x.PlannedDate.HasValue && x.PlannedDate.Value <= date),
                Items = itemList.Select(MapItem).ToList(),
                ActualLogs = logList.Select(MapLog).ToList()
            };
        }

        public async Task<MealPlanCompareResponse> GetCompareAsync(DateOnly from, DateOnly to, Guid? userId = null)
        {
            var days = new List<MealPlanDashboardResponse>();
            var cursor = from;
            while (cursor <= to)
            {
                days.Add(await GetDashboardAsync(cursor, userId));
                cursor = cursor.AddDays(1);
            }

            var plannedItems = days.Sum(x => x.PlannedItemsCount);
            var completedItems = days.Sum(x => x.CompletedItemsCount);

            return new MealPlanCompareResponse
            {
                From = from,
                To = to,
                PlannedCalories = days.Sum(x => x.TotalPlannedCalories),
                ActualCalories = days.Sum(x => x.TotalActualCalories),
                PlannedItemsCount = plannedItems,
                ActualLogsCount = days.Sum(x => x.ActualLogs.Count),
                CompletionRate = plannedItems == 0 ? 0 : Math.Round((decimal)completedItems / plannedItems * 100m, 2),
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

            var mealLogs = await _unitOfWork.MealLogs.FindAsync(x => x.UserId == userId.Value);
            var loggedDates = mealLogs
                .Where(x => x.LoggedAt.HasValue)
                .Select(x => DateOnly.FromDateTime(x.LoggedAt!.Value))
                .Distinct()
                .OrderBy(x => x)
                .ToList();

            int currentStreak = 0;
            int bestStreak = 0;

            if (loggedDates.Any())
            {
                // Calculate current streak
                var today = DateOnly.FromDateTime(DateTime.UtcNow);
                var yesterday = today.AddDays(-1);

                if (loggedDates.Last() == today || loggedDates.Last() == yesterday)
                {
                    currentStreak = 1;
                    for (int i = loggedDates.Count - 2; i >= 0; i--)
                    {
                        if (loggedDates[i + 1].DayNumber - loggedDates[i].DayNumber == 1)
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

                foreach (var date in loggedDates)
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
            var sevenDaysAgo = DateOnly.FromDateTime(DateTime.UtcNow).AddDays(-6);
            var todayDate = DateOnly.FromDateTime(DateTime.UtcNow);

            var plans = await _unitOfWork.MealPlanHeaders.FindAsync(x => x.UserId == userId.Value && x.IsActive);
            var planIds = plans.Select(x => x.Id).ToList();
            var planItems = await _unitOfWork.MealPlanItems.FindAsync(x => planIds.Contains(x.MealPlanId) && x.PlannedDate >= sevenDaysAgo && x.PlannedDate <= todayDate);

            var totalItems = planItems.Count();
            var completedItems = planItems.Count(x => x.IsCompleted);

            decimal weeklyAdherenceRate = 0;
            if (totalItems > 0)
            {
                weeklyAdherenceRate = Math.Round((decimal)completedItems / totalItems * 100, 2);
            }
            else
            {
                // Fallback to meal logging consistency
                var loggedDaysLast7 = loggedDates
                    .Count(x => x >= sevenDaysAgo && x <= todayDate);
                weeklyAdherenceRate = Math.Round((decimal)loggedDaysLast7 / 7 * 100, 2);
            }

            return new MealPlanStreakResponse
            {
                CurrentStreakDays = currentStreak,
                BestStreakDays = bestStreak,
                WeeklyAdherenceRate = weeklyAdherenceRate
            };
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

        private async Task<MealPlanHeader> GetMealPlanAsync(Guid id)
        {
            var entity = await _unitOfWork.MealPlanHeaders.GetByIdAsync(id);
            if (entity == null) throw new Exception("Meal plan not found.");
            return entity;
        }

        private async Task<MealPlanItem> GetPlanItemAsync(Guid planId, Guid itemId)
        {
            var item = await _unitOfWork.MealPlanItems.GetByIdAsync(itemId);
            if (item == null || item.MealPlanId != planId) throw new Exception("Meal plan item not found.");
            return item;
        }

        private void ValidateItems(IEnumerable<MealPlanItemUpsertRequest> items)
        {
            if (items == null || !items.Any()) throw new Exception("Meal plan must contain at least one item.");
            foreach (var item in items) ValidateItem(item);
        }

        private static void ValidateItem(MealPlanItemUpsertRequest item)
        {
            if (item.FoodId == null && item.RecipeId == null) throw new Exception("Each meal plan item must have either FoodId or RecipeId.");
        }

        private async Task<MealPlanResponse> MapAsync(MealPlanHeader entity)
        {
            var items = await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == entity.Id);
            var responseItems = new List<MealPlanItemResponse>();
            decimal totalProtein = 0;
            decimal totalCarbs = 0;
            decimal totalFat = 0;
            decimal totalCalories = 0;

            foreach (var item in items)
            {
                var mappedItem = await MapItemAsync(item);
                responseItems.Add(mappedItem);

                var macros = await GetItemMacrosAsync(item);
                totalProtein += macros.protein;
                totalCarbs += macros.carbs;
                totalFat += macros.fat;
                totalCalories += macros.calories;
            }

            return new MealPlanResponse
            {
                Id = entity.Id,
                Title = entity.Title ?? string.Empty,
                PlanType = entity.PlanType,
                StartDate = entity.StartDate,
                EndDate = entity.EndDate,
                TargetCalories = entity.TargetCalories,
                GeneratedBy = entity.GeneratedBy,
                IsActive = entity.IsActive,
                TotalCalories = (int)Math.Round(totalCalories),
                TotalProteinG = (int)Math.Round(totalProtein),
                TotalCarbsG = (int)Math.Round(totalCarbs),
                TotalFatG = (int)Math.Round(totalFat),
                Items = responseItems
            };
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
            else if (item.RecipeId.HasValue)
            {
                var recipeIngredients = await _unitOfWork.RecipeIngredients.FindAsync(
                    ri => ri.RecipeId == item.RecipeId.Value);

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
                        totalProtein += (ingredient.ProteinG ?? 0) * quantity;
                        totalCarbs += (ingredient.CarbsG ?? 0) * quantity;
                        totalFat += (ingredient.FatG ?? 0) * quantity;
                        totalCalories += (ingredient.CaloriesKcal ?? 0) * quantity;
                    }
                }

                return (totalProtein, totalCarbs, totalFat, totalCalories);
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

            return new MealPlanItemResponse
            {
                Id = x.Id,
                MealPlanId = x.MealPlanId,
                MealType = x.MealType,
                FoodId = x.FoodId,
                RecipeId = x.RecipeId,
                PlannedDate = x.PlannedDate,
                ScheduledTime = x.ScheduledTime,
                TargetCalories = x.TargetCalories,
                IsCompleted = x.IsCompleted,
                FoodName = food?.NameVi,
                RecipeName = recipe?.Title,
                SourceEntityType = x.FoodId.HasValue ? "Food" : x.RecipeId.HasValue ? "Recipe" : null,
                Status = x.IsCompleted ? "done" : "planned",
                EstimatedPriceVnd = price
            };
        }

        private static MealPlanItemResponse MapItem(MealPlanItem x)
        {
            return new MealPlanItemResponse
            {
                Id = x.Id,
                MealPlanId = x.MealPlanId,
                MealType = x.MealType,
                FoodId = x.FoodId,
                RecipeId = x.RecipeId,
                PlannedDate = x.PlannedDate,
                ScheduledTime = x.ScheduledTime,
                TargetCalories = x.TargetCalories,
                IsCompleted = x.IsCompleted,
                FoodName = x.Food?.NameVi,
                RecipeName = x.Recipe?.Title,
                SourceEntityType = x.FoodId.HasValue ? "Food" : x.RecipeId.HasValue ? "Recipe" : null,
                Status = x.IsCompleted ? "done" : "planned"
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

            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId);
            var healthProfile = healthProfiles.FirstOrDefault();
            var targetCalories = healthProfile?.TargetCalories ?? 2000;

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var startDate = today.AddDays(1);
            var endDate = startDate.AddDays(6);

            var mealPlanHeader = new MealPlanHeader
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = $"Budget-friendly meal plan ({startDate:dd/MM} - {endDate:dd/MM})",
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
            await _unitOfWork.CompleteAsync();

            var allFoods = (await _unitOfWork.Foods.GetAllAsync()).Where(f => f.IsActive == true || f.IsActive == null).ToList();
            var allRecipes = (await _unitOfWork.Recipes.GetAllAsync()).Where(r => r.IsActive == true || r.IsActive == null).ToList();

            var userAllergies = await _unitOfWork.UserAllergies.FindAsync(ua => ua.UserId == userId);
            var allergyIds = userAllergies.Select(ua => ua.AllergyId).ToList();
            if (allergyIds.Any())
            {
                var foodAllergies = await _unitOfWork.FoodAllergies.FindAsync(fa => allergyIds.Contains(fa.AllergyId));
                var forbiddenFoodIds = foodAllergies.Select(fa => fa.FoodId).ToHashSet();
                allFoods = allFoods.Where(f => !forbiddenFoodIds.Contains(f.Id)).ToList();
            }

            for (var d = 0; d < 7; d++)
            {
                var currentDate = startDate.AddDays(d);
                var mealTypes = new[] { "breakfast", "lunch", "dinner" };

                var breakfastCal = targetCalories * 0.25;
                var lunchCal = targetCalories * 0.35;
                var dinnerCal = targetCalories * 0.30;

                foreach (var mealType in mealTypes)
                {
                    var targetCal = mealType == "breakfast" ? breakfastCal : (mealType == "lunch" ? lunchCal : dinnerCal);
                    
                    var candidateRecipes = allRecipes
                        .Where(r => r.MealType != null && r.MealType.Contains(mealType, StringComparison.OrdinalIgnoreCase))
                        .OrderBy(r => Math.Abs((r.CookTimeMin ?? 30) - (latestBudget.TimeLimitMin ?? 45)))
                        .ThenBy(r => r.EstimatedPriceVnd ?? 100000)
                        .ToList();

                    Guid? recipeId = null;
                    Guid? foodId = null;
                    int selectedCalories = (int)targetCal;

                    if (candidateRecipes.Any())
                    {
                        var selectedRecipe = candidateRecipes.First();
                        recipeId = selectedRecipe.Id;
                        selectedCalories = await GetRecipeCaloriesAsync(selectedRecipe.Id);
                    }
                    else
                    {
                        var candidateFoods = allFoods
                            .Where(f => f.CaloriesKcal.HasValue)
                            .OrderBy(f => f.EstimatedPriceVnd ?? 50000)
                            .ToList();

                        if (candidateFoods.Any())
                        {
                            var selectedFood = candidateFoods.First();
                            foodId = selectedFood.Id;
                            selectedCalories = (int)(selectedFood.CaloriesKcal ?? 0);
                        }
                    }

                    var item = new MealPlanItem
                    {
                        Id = Guid.NewGuid(),
                        MealPlanId = mealPlanHeader.Id,
                        MealType = mealType,
                        FoodId = foodId,
                        RecipeId = recipeId,
                        PlannedDate = currentDate,
                        ScheduledTime = mealType == "breakfast" ? new TimeOnly(7, 30) : (mealType == "lunch" ? new TimeOnly(12, 0) : new TimeOnly(18, 30)),
                        TargetCalories = selectedCalories,
                        IsCompleted = false,
                        CreatedAt = DateTime.UtcNow
                    };

                    await _unitOfWork.MealPlanItems.AddAsync(item);
                }
            }

            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(mealPlanHeader.Id);
        }

        public async Task<BudgetStatusResponse> GetBudgetStatusAsync(Guid planId, Guid userId)
        {
            var plan = await GetMealPlanAsync(planId);
            var planItems = await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == planId);
            
            var totalPlannedCost = 0;
            foreach (var item in planItems)
            {
                if (item.FoodId.HasValue)
                {
                    var food = await _unitOfWork.Foods.GetByIdAsync(item.FoodId.Value);
                    totalPlannedCost += food?.EstimatedPriceVnd ?? 0;
                }
                else if (item.RecipeId.HasValue)
                {
                    var recipe = await _unitOfWork.Recipes.GetByIdAsync(item.RecipeId.Value);
                    totalPlannedCost += recipe?.EstimatedPriceVnd ?? 0;
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
            var currentItem = await GetPlanItemAsync(planId, itemId);
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
                currentPrice = recipe?.EstimatedPriceVnd ?? 100000;
            }

            var result = new List<MealPlanItemResponse>();

            if (currentItem.RecipeId.HasValue)
            {
                var recipes = await _unitOfWork.Recipes.FindAsync(r => 
                    r.MealType != null && r.MealType.Contains(currentItem.MealType ?? "lunch") &&
                    r.Id != currentItem.RecipeId &&
                    r.EstimatedPriceVnd.HasValue && r.EstimatedPriceVnd.Value < currentPrice);

                var alternativeRecipes = recipes.OrderBy(r => r.EstimatedPriceVnd).Take(5);
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
                        EstimatedPriceVnd = r.EstimatedPriceVnd,
                        Status = "alternative"
                    });
                }
            }
            else if (currentItem.FoodId.HasValue)
            {
                var foods = await _unitOfWork.Foods.FindAsync(f => 
                    f.Id != currentItem.FoodId &&
                    f.EstimatedPriceVnd.HasValue && f.EstimatedPriceVnd.Value < currentPrice);

                var alternativeFoods = foods.OrderBy(f => f.EstimatedPriceVnd).Take(5);
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
                foreach (var item in items)
                {
                    var price = 0;
                    var category = "Other";

                    if (item.FoodId.HasValue)
                    {
                        var food = await _unitOfWork.Foods.GetByIdAsync(item.FoodId.Value);
                        price = food?.EstimatedPriceVnd ?? 0;
                        category = "Fresh ingredients";
                    }
                    else if (item.RecipeId.HasValue)
                    {
                        var recipe = await _unitOfWork.Recipes.GetByIdAsync(item.RecipeId.Value);
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

            var dailySpent = new Dictionary<DateOnly, int>();
            foreach (var item in completedItems)
            {
                if (!item.PlannedDate.HasValue) continue;
                
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
            var plan = await FindDailyPlanAsync(userId, date);
            if (plan == null) return null;
            return await MapAsync(plan);
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

            var items = (await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == plan.Id)).ToList();
            var itemIds = items.Select(x => x.Id).ToHashSet();
            var logs = (await _unitOfWork.MealLogs.FindAsync(
                x => x.UserId == userId
                    && x.MealPlanItemId.HasValue
                    && itemIds.Contains(x.MealPlanItemId.Value))).ToList();

            var plannedKcal = items.Sum(x => x.TargetCalories ?? 0);
            var actualKcal = logs.Sum(x => x.CaloriesKcal ?? 0);
            decimal? deviation = plannedKcal > 0
                ? Math.Round((actualKcal - plannedKcal) / plannedKcal * 100m, 2)
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
            var plan = await FindDailyPlanAsync(userId, request.PlannedDate);
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
                plan.TargetCalories = request.TargetCalories ?? plan.TargetCalories;
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
                IsCompleted = false
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

            var existingLogs = await _unitOfWork.MealLogs.FindAsync(x => x.MealPlanItemId == itemId);
            var existingLog = existingLogs.FirstOrDefault();
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
                LoggedAt = DateTime.UtcNow,
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
                && x.PlanType == "DAILY"
                && x.StartDate == date
                && x.IsActive);

            return plans.OrderByDescending(x => x.UpdatedAt ?? x.CreatedAt).FirstOrDefault();
        }

        private async Task<int> GetRecipeCaloriesAsync(Guid recipeId)
        {
            var recipeIngredients = await _unitOfWork.RecipeIngredients.FindAsync(ri => ri.RecipeId == recipeId);
            decimal totalCalories = 0;

            foreach (var ri in recipeIngredients)
            {
                var ingredient = await _unitOfWork.Ingredients.GetByIdAsync(ri.IngredientId);
                if (ingredient != null && ingredient.CaloriesKcal.HasValue)
                {
                    var quantity = ri.Quantity ?? 1;
                    totalCalories += ingredient.CaloriesKcal.Value * quantity;
                }
            }

            return (int)Math.Round(totalCalories);
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

            return new MealPlanItemResponse
            {
                Id = item.Id,
                MealPlanId = item.MealPlanId,
                MealType = item.MealType,
                FoodId = item.FoodId,
                RecipeId = item.RecipeId,
                PlannedDate = item.PlannedDate,
                ScheduledTime = item.ScheduledTime,
                TargetCalories = item.TargetCalories,
                IsCompleted = item.IsCompleted,
                MealLogId = mealLogId,
                FoodName = food?.NameVi,
                RecipeName = recipe?.Title,
                SourceEntityType = item.FoodId.HasValue ? "Food" : item.RecipeId.HasValue ? "Recipe" : null,
                Status = item.IsCompleted ? "done" : "planned",
                EstimatedPriceVnd = price
            };
        }
    }
}
