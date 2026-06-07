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

        public MealPlanService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<IEnumerable<MealPlanResponse>> GetAllAsync(bool? isActive = null)
        {
            var plans = await _unitOfWork.MealPlanHeaders.GetAllAsync();
            if (isActive.HasValue)
            {
                plans = plans.Where(x => x.IsActive == isActive.Value);
            }

            return await Task.WhenAll(plans.Select(MapAsync));
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

            await ReplaceItemsAsync(entity.Id, request.Items);
            return await GetByIdAsync(entity.Id);
        }

        public async Task<MealPlanResponse> UpdateAsync(Guid id, MealPlanUpsertRequest request, Guid? userId = null)
        {
            var entity = await GetMealPlanAsync(id);
            ValidateItems(request.Items);

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

            var existingItems = await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == entity.Id);
            _unitOfWork.MealPlanItems.RemoveRange(existingItems);
            await _unitOfWork.CompleteAsync();

            await ReplaceItemsAsync(entity.Id, request.Items);
            return await GetByIdAsync(entity.Id);
        }

        public async Task DeleteAsync(Guid id, Guid? userId = null)
        {
            var entity = await GetMealPlanAsync(id);
            _unitOfWork.MealPlanHeaders.Remove(entity);
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
                PlannedDate = request.PlannedDate,
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
            var mealLog = new MealLog
            {
                Id = Guid.NewGuid(),
                UserId = userId ?? Guid.Empty,
                FoodId = item.FoodId,
                RecipeId = item.RecipeId,
                MealType = item.MealType,
                QuantityG = 100,
                CaloriesKcal = item.TargetCalories,
                ProteinG = 0,
                CarbsG = 0,
                FatG = 0,
                SourceType = "MEAL_PLAN",
                Notes = request.Notes,
                LoggedAt = request.LoggedAt ?? DateTime.UtcNow,
                MealPlanItemId = item.Id,
                IsFromMealPlan = true
            };

            await _unitOfWork.MealLogs.AddAsync(mealLog);
            item.IsCompleted = true;
            _unitOfWork.MealPlanItems.Update(item);
            await _unitOfWork.CompleteAsync();

            return new MealLogResponse
            {
                Id = mealLog.Id,
                UserId = mealLog.UserId,
                FoodId = mealLog.FoodId,
                RecipeId = mealLog.RecipeId,
                MealType = mealLog.MealType,
                QuantityG = mealLog.QuantityG,
                CaloriesKcal = mealLog.CaloriesKcal,
                ProteinG = mealLog.ProteinG,
                CarbsG = mealLog.CarbsG,
                FatG = mealLog.FatG,
                SourceType = mealLog.SourceType,
                Notes = mealLog.Notes,
                LoggedAt = mealLog.LoggedAt,
                MealPlanItemId = mealLog.MealPlanItemId,
                IsFromMealPlan = mealLog.IsFromMealPlan
            };
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

        public Task<MealPlanStreakResponse> GetStreaksAsync(Guid? userId = null)
        {
            return Task.FromResult(new MealPlanStreakResponse
            {
                CurrentStreakDays = 0,
                BestStreakDays = 0,
                WeeklyAdherenceRate = 0
            });
        }

        private async Task ReplaceItemsAsync(Guid mealPlanId, IEnumerable<MealPlanItemUpsertRequest> items)
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
                    PlannedDate = item.PlannedDate,
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
            var responseItems = items.Select(MapItem).ToList();
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
                TotalCalories = responseItems.Sum(x => x.TargetCalories ?? 0),
                TotalProteinG = 0,
                TotalCarbsG = 0,
                TotalFatG = 0,
                Items = responseItems
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


    }
}
