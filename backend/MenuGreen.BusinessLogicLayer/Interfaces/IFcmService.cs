using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IFcmService
    {
        Task<DeviceTokenResponse> RegisterTokenAsync(Guid userId, DeviceTokenRegisterRequest request);
        Task<bool> RemoveTokenAsync(Guid userId, string token);
        Task<IEnumerable<DeviceTokenResponse>> GetUserTokensAsync(Guid userId);
        Task<FcmSendResponse> SendToUserAsync(Guid userId, string title, string body, string? data = null);
        Task<FcmSendResponse> SendToUsersAsync(IEnumerable<Guid> userIds, string title, string body, string? data = null);
        Task<int> SendTestNotificationAsync();
    }
}
