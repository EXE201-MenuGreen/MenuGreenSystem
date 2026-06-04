using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IUserSubscriptionService
    {
        Task<UserSubscriptionResponse> SubscribeAsync(Guid userId, SubscribeRequest request);
        Task<UserSubscriptionResponse> RenewAsync(Guid userId, RenewSubscriptionRequest request);
        Task<UserSubscriptionResponse> CancelAsync(Guid userId, CancelSubscriptionRequest request);
        Task<UserSubscriptionResponse?> GetCurrentAsync(Guid userId);
        Task<UserSubscriptionResponse> GetByIdAsync(Guid userId, Guid subscriptionId);
        Task<IEnumerable<SubscriptionTransactionResponse>> GetHistoryAsync(Guid userId);
    }
}
