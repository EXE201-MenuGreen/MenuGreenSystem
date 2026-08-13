using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IMealPlanService
    {
        Task<IEnumerable<MealPlanResponse>> GetAllAsync(bool? isActive = null, Guid? userId = null);
        Task<MealPlanResponse> GetByIdAsync(Guid id, Guid? userId = null);
        Task<MealPlanResponse> CreateAsync(MealPlanUpsertRequest request, Guid? userId = null);
        Task<MealPlanResponse> UpdateAsync(Guid id, MealPlanUpsertRequest request, Guid? userId = null);
        Task<MealPlanResponse> CreateEmptyAsync(CreateEmptyPlanRequest request, Guid? userId = null);
        Task DeleteAsync(Guid id, Guid? userId = null);
        Task<MealPlanResponse> UpdateStatusAsync(Guid id, MealPlanStatusRequest request, Guid? userId = null);
        Task<MealPlanDistributionResponse> DistributeAsync(Guid id, string targetAudience, string? notes = null, Guid? userId = null);
        Task<MealPlanResponse> AddItemAsync(Guid planId, MealPlanItemUpsertRequest request, Guid? userId = null);
        Task<MealPlanResponse> UpdateItemAsync(Guid planId, Guid itemId, MealPlanItemUpsertRequest request, Guid? userId = null);
        Task<MealPlanResponse> BalanceDailyCaloriesAsync(Guid planId, BalanceMealPlanCaloriesRequest request, Guid userId);
        Task<MealPlanResponse> ReplaceItemAsync(Guid planId, Guid itemId, MealPlanItemReplaceRequest request, Guid userId);
        Task DeleteItemAsync(Guid planId, Guid itemId, Guid? userId = null);
        Task<MealPlanResponse> UpdateItemStatusAsync(Guid planId, Guid itemId, MealPlanStatusRequest request, Guid? userId = null);
        Task<MealLogResponse> ConvertItemToLogAsync(Guid planId, Guid itemId, MealPlanConvertToLogRequest request, Guid? userId = null);
        Task<OfficeScanMealResponse> SaveOfficeScanMealAsync(Guid planId, OfficeScanMealRequest request, Guid userId);
        Task<MealPlanItemResponse> SaveOfficeScanPlanItemAsync(Guid planId, OfficeScanMealRequest request, Guid userId, bool isPriorityLunch);
        Task<MealPlanResponse> CommitAsync(Guid planId, MealPlanCommitRequest request, Guid? userId = null);
        Task<MealPlanResponse> DuplicateAsync(Guid planId, MealPlanDuplicateRequest request, Guid? userId = null);
        Task<MealPlanDashboardResponse> GetDashboardAsync(DateOnly date, Guid? userId = null);
        Task<MealPlanCompareResponse> GetCompareAsync(DateOnly from, DateOnly to, Guid? userId = null);
        Task<MealPlanStreakResponse> GetStreaksAsync(Guid? userId = null);

        Task<MealPlanResponse> GenerateByBudgetAsync(Guid userId);
        Task<BudgetStatusResponse> GetBudgetStatusAsync(Guid planId, Guid userId);
        Task<IEnumerable<MealPlanItemResponse>> GetAlternativesAsync(Guid planId, Guid itemId, Guid userId);
        Task<ExpenseCompareResponse> CompareExpensesAsync(DateOnly from, DateOnly to, Guid userId);
        Task<ExpenseBreakdownResponse> GetExpenseBreakdownAsync(Guid userId);
        Task<BudgetAdherenceResponse> GetAdherenceScoresAsync(Guid userId);
        Task<GroceryListResponse> GetGroceryListAsync(Guid planId, Guid userId);

        // Daily Meal Plan Methods
        Task<MealPlanResponse?> GetByDateAsync(
            Guid userId,
            DateOnly date,
            bool forceRefresh = false);
        Task<MealPlanResponse> CreateOrUpdateDailyAsync(Guid userId, UserMealPlanUpsertRequest request);
        Task<MealPlanResponse> CreateFromDailyMenuAsync(Guid userId, CreateMealPlanFromDailyMenuRequest request);
        Task LinkMealLogToDailyPlanAsync(Guid userId, Guid mealLogId);
        Task<CompleteMealPlanItemResponse> CompleteItemAsync(Guid userId, Guid itemId, CompleteMealPlanItemRequest request);
        Task<MealPlanAdherenceResponse> GetAdherenceAsync(Guid userId, DateOnly date);
        Task<CompleteMealPlanItemResponse> ToggleItemAsync(Guid userId, Guid itemId, bool isCompleted);
    }
}
