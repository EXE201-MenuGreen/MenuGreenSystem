using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IOnboardingService
    {
        Task<OnboardingCompleteResponse> CompleteAsync(Guid userId, CompleteOnboardingRequest? request = null);
    }
}
