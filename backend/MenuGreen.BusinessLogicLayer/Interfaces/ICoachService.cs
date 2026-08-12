using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface ICoachService
    {
        Task<IEnumerable<CoachProfileResponse>> GetCoachesAsync(string? specialty, int? minPrice, int? maxPrice);
        Task<CoachProfileResponse> GetCoachByIdAsync(Guid coachId);
        Task<CoachProfileResponse> RegisterCoachAsync(Guid userId, CoachRegisterRequest request);
        Task<CoachApplicationResponse> GetMyApplicationAsync(Guid userId);
        Task<CoachApplicationResponse> SaveApplicationDraftAsync(Guid userId, CoachApplicationUpsertRequest request);
        Task<CoachApplicationResponse> SubmitApplicationAsync(Guid userId, CoachApplicationUpsertRequest request);
        Task<IEnumerable<CoachApplicationResponse>> GetApplicationsForAdminAsync(string? status);
        Task<CoachApplicationResponse> GetApplicationForAdminAsync(Guid applicationId);
        Task<CoachApplicationResponse> ReviewApplicationAsync(Guid adminUserId, Guid applicationId, CoachApplicationReviewRequest request);
        Task<bool> ConnectCoachAsync(Guid clientId, Guid coachId);
        Task<bool> ApproveConnectionAsync(Guid coachId, Guid clientId, bool approve);
        Task<IEnumerable<CoachClientSummaryResponse>> GetMyClientsAsync(Guid coachId);
        Task<IEnumerable<MyCoachResponse>> GetMyCoachesAsync(Guid clientId);
        Task<bool> GrantAccessAsync(Guid clientId, Guid coachId);
        Task<bool> RevokeAccessAsync(Guid clientId, Guid coachId);
        Task<bool> DisconnectCoachAsync(Guid clientId, Guid coachId);
        Task<object> GetClientProfileAsync(Guid coachId, Guid clientId);
        Task<IEnumerable<ClientNutritionSummaryResponse>> GetClientNutritionSummaryAsync(
            Guid coachId,
            Guid clientId,
            int days,
            DateOnly? from = null,
            DateOnly? to = null);
        Task<IEnumerable<ClientWeightTrendResponse>> GetClientWeightTrendAsync(Guid coachId, Guid clientId);
        Task<CoachFeedbackResponse> AddFeedbackAsync(Guid coachId, Guid clientId, CoachFeedbackCreateRequest request);
        Task<IEnumerable<CoachFeedbackResponse>> GetFeedbacksAsync(Guid userId);
        Task<MealPlanResponse> AdjustClientMealPlanAsync(Guid coachId, Guid clientId, Guid planId, MealPlanUpsertRequest request);
        Task<HealthProfileResponse> AdjustClientHealthTargetsAsync(Guid coachId, Guid clientId, ClientHealthTargetsAdjustRequest request);

        // New client queries
        Task<IEnumerable<MealPlanResponse>> GetClientMealPlansAsync(Guid coachId, Guid clientId, DateOnly? from, DateOnly? to, string? planType);
        Task<MealPlanResponse> GetClientMealPlanDetailAsync(Guid coachId, Guid clientId, Guid planId);
        Task<MealPlanResponse> CreateClientMealPlanAsync(Guid coachId, Guid clientId, MealPlanUpsertRequest request);
        Task<MealPlanResponse> SubmitClientMealPlanAsync(Guid coachId, Guid clientId, Guid planId, CoachSubmitMealPlanRequest? request);
        Task DeleteClientMealPlanAsync(Guid coachId, Guid clientId, Guid planId);
        Task<MealPlanResponse?> GetClientMealPlanAsync(Guid coachId, Guid clientId, DateOnly date);
        Task<object> GetClientGymConfigurationAsync(Guid coachId, Guid clientId, DateOnly? date);
        Task<object> GetClientSuggestionsAsync(
            Guid coachId,
            Guid clientId,
            DateOnly? date,
            int targetCalories = 0,
            int? minCalories = null,
            int? maxCalories = null,
            decimal? minProteinG = null,
            decimal? maxProteinG = null,
            int top = 10);
        Task<IEnumerable<object>> GetClientReviewRequestsAsync(Guid coachId, Guid clientId);
    }
}
