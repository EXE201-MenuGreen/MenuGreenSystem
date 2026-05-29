using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IMealPlanService
    {
        Task<IEnumerable<MealPlanResponse>> GetAllAsync(bool? isActive = null);
        Task<MealPlanResponse> GetByIdAsync(Guid id);
        Task<MealPlanResponse> CreateAsync(MealPlanUpsertRequest request);
        Task<MealPlanResponse> UpdateAsync(Guid id, MealPlanUpsertRequest request);
        Task DeleteAsync(Guid id);
        Task<MealPlanResponse> UpdateStatusAsync(Guid id, MealPlanStatusRequest request);
        Task<MealPlanDistributionResponse> DistributeAsync(Guid id, string targetAudience, string? notes = null);
    }
}
