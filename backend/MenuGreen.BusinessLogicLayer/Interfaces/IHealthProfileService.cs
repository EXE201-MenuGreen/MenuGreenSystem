using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IHealthProfileService
    {
        Task<HealthProfileResponse> GetAsync(Guid userId);
        Task<HealthProfileResponse> UpdateAsync(Guid userId, UpdateHealthProfileRequest request);
    }
}
