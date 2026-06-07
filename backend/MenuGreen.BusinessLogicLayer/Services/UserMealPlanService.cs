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
    public class UserMealPlanService : IUserMealPlanService
    {
        private const string DailyPlanType = "DAILY";
        private const string GeneratedByUser = "USER";
        private const decimal DefaultQuantityG = 100m;

        private readonly IUnitOfWork _unitOfWork;
        private readonly INutritionTrackingService _nutritionTracking;

        public UserMealPlanService(IUnitOfWork unitOfWork, INutritionTrackingService nutritionTracking)
        {
            _unitOfWork = unitOfWork;
            _nutritionTracking = nutritionTracking;
        }

        public async Task<MealPlanResponse?> GetByDateAsync(Guid userId, DateOnly date)
        {
            var plan = await FindDailyPlanAsync(userId, date);
            if (plan == null) return null;
            return await MapPlanAsync(plan);
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
                    PlanType = DailyPlanType,
                    StartDate = request.PlannedDate,
                    EndDate = request.PlannedDate,
                    TargetCalories = request.TargetCalories,
                    GeneratedBy = GeneratedByUser,
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

            await AddItemsAsync(plan.Id, request.PlannedDate, request.Items);
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

        public async Task DeleteAsync(Guid userId, Guid mealPlanId)
        {
            var plan = await GetOwnedPlanAsync(userId, mealPlanId);
            _unitOfWork.MealPlanHeaders.Remove(plan);
            await _unitOfWork.CompleteAsync();
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

            var quantity = request.QuantityG ?? DefaultQuantityG;
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

        private async Task<MealPlanHeader?> FindDailyPlanAsync(Guid userId, DateOnly date)
        {
            var plans = await _unitOfWork.MealPlanHeaders.FindAsync(x =>
                x.UserId == userId
                && x.PlanType == DailyPlanType
                && x.StartDate == date
                && x.IsActive);

            return plans.OrderByDescending(x => x.UpdatedAt ?? x.CreatedAt).FirstOrDefault();
        }

        private async Task<MealPlanHeader> GetOwnedPlanAsync(Guid userId, Guid mealPlanId)
        {
            var plan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(mealPlanId)
                ?? throw new Exception("Meal plan not found.");
            if (plan.UserId != userId) throw new Exception("Forbidden.");
            return plan;
        }

        private async Task AddItemsAsync(Guid mealPlanId, DateOnly plannedDate, IEnumerable<MealPlanItemUpsertRequest> items)
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

        private static void ValidateItems(IEnumerable<MealPlanItemUpsertRequest> items)
        {
            var list = items?.ToList() ?? new List<MealPlanItemUpsertRequest>();
            if (list.Count == 0) throw new Exception("Meal plan must contain at least one item.");

            foreach (var item in list)
            {
                if (item.FoodId == null && item.RecipeId == null)
                {
                    throw new Exception("Each meal plan item must have either FoodId or RecipeId.");
                }
            }
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

        private async Task<MealPlanResponse> MapPlanAsync(MealPlanHeader plan)
        {
            var items = (await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == plan.Id)).ToList();
            var itemIds = items.Select(x => x.Id).ToList();
            var logs = itemIds.Count == 0
                ? new List<MealLog>()
                : (await _unitOfWork.MealLogs.FindAsync(x => x.MealPlanItemId.HasValue && itemIds.Contains(x.MealPlanItemId.Value))).ToList();
            var logByItem = logs.Where(x => x.MealPlanItemId.HasValue).ToDictionary(x => x.MealPlanItemId!.Value);

            var mappedItems = new List<MealPlanItemResponse>();
            foreach (var item in items.OrderBy(x => x.MealType))
            {
                logByItem.TryGetValue(item.Id, out var log);
                mappedItems.Add(await MapItemAsync(item, log?.Id));
            }

            return new MealPlanResponse
            {
                Id = plan.Id,
                Title = plan.Title ?? string.Empty,
                PlanType = plan.PlanType,
                StartDate = plan.StartDate,
                EndDate = plan.EndDate,
                TargetCalories = plan.TargetCalories,
                GeneratedBy = plan.GeneratedBy,
                IsActive = plan.IsActive,
                TotalCalories = mappedItems.Sum(x => x.TargetCalories ?? 0),
                Items = mappedItems
            };
        }

        private async Task<MealPlanItemResponse> MapItemAsync(MealPlanItem item, Guid? mealLogId = null)
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
                SourceEntityType = item.FoodId.HasValue ? "Food" : item.RecipeId.HasValue ? "Recipe" : null
            };
        }

    }
}
