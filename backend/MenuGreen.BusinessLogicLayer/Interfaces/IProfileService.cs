using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IProfileService
    {
        Task<ProfileResponse> GetProfileAsync(Guid userId);
        Task<ProfileResponse> UpdateProfileAsync(Guid userId, UpdateProfileRequest request);
    }
}
