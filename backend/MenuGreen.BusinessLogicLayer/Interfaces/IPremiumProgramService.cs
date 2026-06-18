using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IPremiumProgramService
    {
        Task<IEnumerable<PremiumProgramResponse>> GetActiveProgramsAsync();
        Task<PremiumProgramResponse> GetProgramByIdAsync(Guid id);
        Task<SepayOrderResponse> PurchaseProgramAsync(Guid userId, Guid programId);
        Task<UserPremiumProgramResponse> ActivateProgramAsync(Guid userId, Guid userProgramId, ProgramActivationRequest request);
        Task<UserPremiumProgramResponse?> GetMyActiveProgramAsync(Guid userId);
        Task<IEnumerable<UserPremiumProgramResponse>> GetMyProgramsAsync(Guid userId);
        Task<IEnumerable<UserProgramMilestoneResponse>> GetMyActiveMilestonesAsync(Guid userId);
        Task<UserPremiumProgramResponse> CheckInWeekAsync(Guid userId, int weekNumber, ProgramCheckInRequest request);
        Task<List<MilestoneWeightProgress>> GetMyActiveProgressTrendAsync(Guid userId);
        Task<UserPremiumProgramResponse> GraduateActiveProgramAsync(Guid userId);
        Task<ProgramReportResponse> GetMyProgramReportAsync(Guid userId, Guid userProgramId);
    }
}
