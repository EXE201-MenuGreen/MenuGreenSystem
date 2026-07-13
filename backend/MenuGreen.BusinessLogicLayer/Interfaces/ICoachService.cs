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
        Task<bool> ConnectCoachAsync(Guid clientId, Guid coachId);
        Task<bool> ApproveConnectionAsync(Guid coachId, Guid clientId, bool approve);
        Task<IEnumerable<CoachClientSummaryResponse>> GetMyClientsAsync(Guid coachId);
        Task<IEnumerable<MyCoachResponse>> GetMyCoachesAsync(Guid clientId);
        Task<bool> GrantAccessAsync(Guid clientId, Guid coachId);
        Task<bool> RevokeAccessAsync(Guid clientId, Guid coachId);
        Task<object> GetClientProfileAsync(Guid coachId, Guid clientId);
        Task<IEnumerable<ClientNutritionSummaryResponse>> GetClientNutritionSummaryAsync(Guid coachId, Guid clientId, int days);
        Task<IEnumerable<ClientWeightTrendResponse>> GetClientWeightTrendAsync(Guid coachId, Guid clientId);
        Task<CoachFeedbackResponse> AddFeedbackAsync(Guid coachId, Guid clientId, CoachFeedbackCreateRequest request);
        Task<IEnumerable<CoachFeedbackResponse>> GetFeedbacksAsync(Guid userId);
        Task<MealPlanResponse> AdjustClientMealPlanAsync(Guid coachId, Guid clientId, Guid planId, MealPlanUpsertRequest request);
        Task<HealthProfileResponse> AdjustClientHealthTargetsAsync(Guid coachId, Guid clientId, ClientHealthTargetsAdjustRequest request);
    }
}
