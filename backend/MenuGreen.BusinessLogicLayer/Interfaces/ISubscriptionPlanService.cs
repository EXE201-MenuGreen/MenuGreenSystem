using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface ISubscriptionPlanService
    {
        Task<IEnumerable<SubscriptionPlanResponse>> GetAllAsync(bool? isActive = null);
        Task<IEnumerable<SubscriptionPlanResponse>> GetActiveAsync();
        Task<SubscriptionPlanResponse> GetByIdAsync(Guid id);
        Task<SubscriptionPlanFeaturesResponse> GetPlanFeaturesAsync(Guid id);
        Task<SubscriptionPlanStatusResponse> GetPlanStatusAsync(Guid id);
        Task<SubscriptionPlanResponse> CreateAsync(SubscriptionPlanUpsertRequest request);
        Task<SubscriptionPlanResponse> UpdateAsync(Guid id, SubscriptionPlanUpsertRequest request);
        Task DeleteAsync(Guid id);
        Task<SubscriptionPlanResponse> UpdateStatusAsync(Guid id, SubscriptionPlanStatusRequest request);
    }
}
