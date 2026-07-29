using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IPtReviewService
    {
        Task<CreatePtReviewReportResponse> CreateReportAsync(Guid userId, CreatePtReviewReportRequest request);
        Task<PtReviewRequestDetailResponse> GetSharedReportAsync(string token);
        Task<IEnumerable<PtReviewRequestDetailResponse>> GetMyRequestsAsync(Guid userId);
        Task SubmitReviewAsync(string token, PtSubmitReviewRequest request);
        Task<PtReviewRequestDetailResponse> GetReviewResultAsync(Guid userId, Guid requestId);
        Task ApplyReviewAsync(Guid userId, Guid requestId);
        Task RejectReviewAsync(Guid userId, Guid requestId);

        // Phase 8: Coach -> Gymer (PersonalProgram direction)
        Task<CreatePersonalProgramResponse> CreatePersonalProgramAsync(Guid coachId, CreatePersonalProgramRequest request);
        Task<PersonalProgramResponse> AcceptPersonalProgramAsync(Guid gymerId, Guid requestId);
        Task<PersonalProgramResponse> RejectPersonalProgramAsync(Guid gymerId, Guid requestId);
        Task<IEnumerable<PersonalProgramResponse>> GetMyPersonalProgramsAsync(Guid gymerId);
        Task<IEnumerable<CoachSentProgramResponse>> GetCoachSentProgramsAsync(Guid coachId, Guid? clientId);
    }
}
