using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IUserAiProfileService
    {
        Task<UserAiProfileResponse> GetAsync(Guid userId);
        Task<UserAiProfileResponse> UpsertAsync(Guid userId, UpdateUserAiProfileRequest request);
    }
}
