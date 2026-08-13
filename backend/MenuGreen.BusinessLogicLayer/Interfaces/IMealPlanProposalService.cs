using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IMealPlanProposalService
    {
        Task<MealPlanProposalResponse> CreateDraftAsync(Guid coachId, Guid reviewRequestId);
        Task<MealPlanProposalResponse> UpdateDraftAsync(Guid coachId, Guid proposalId, UpdateMealPlanProposalRequest request);
        Task<MealPlanProposalItemResponse> UpdateItemPortionAsync(
            Guid coachId,
            Guid proposalId,
            Guid itemId,
            UpdateMealPlanProposalItemPortionRequest request);
        Task<MealPlanProposalResponse> SubmitAsync(Guid coachId, Guid proposalId);
        Task<MealPlanProposalResponse> GetAsync(Guid actorId, Guid proposalId);
        Task<IEnumerable<MealPlanProposalResponse>> GetMineAsync(Guid userId, string? status = null);
        Task<MealPlanProposalResponse> ApplyAsync(Guid userId, Guid proposalId);
        Task<MealPlanProposalResponse> RejectAsync(Guid userId, Guid proposalId);
        Task ProcessDeadlineNotificationsAsync(DateTime utcNow);
        Task ExpireOverdueAsync(DateTime utcNow);
    }
}
