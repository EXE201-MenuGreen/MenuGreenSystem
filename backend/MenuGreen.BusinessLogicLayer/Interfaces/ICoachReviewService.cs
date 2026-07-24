using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface ICoachReviewService
    {
        /// <summary>
        /// List weekly report summaries across all Gymers currently
        /// <c>Connected</c> with <paramref name="coachId"/>. Supports
        /// optional filters: <paramref name="weekStart"/>, <paramref name="month"/>
        /// ('YYYY-MM'), <paramref name="status"/>, and <paramref name="clientId"/>
        /// (when scoped to a single Gymer).
        /// </summary>
        Task<IEnumerable<CoachReportSummary>> ListReportsAsync(
            Guid coachId,
            DateTime? weekStart,
            string? month,
            string? status,
            Guid? clientId);

        /// <summary>
        /// Full weekly report detail (including the ReportData snapshot) for a
        /// single report. Throws <see cref="UnauthorizedAccessException"/> if
        /// the report's owner is not currently connected with
        /// <paramref name="coachId"/>.
        /// </summary>
        Task<CoachReportDetailResponse> GetReportDetailAsync(
            Guid coachId,
            Guid reportId);

        /// <summary>
        /// Coach submits feedback + optional inline meal-plan adjustments.
        /// On success the report moves to <c>Reviewed</c>; the inline adjustments
        /// are applied immediately to the Gymer's meal plan (same semantics as
        /// the Gymer pressing "Apply" on the shared-token flow).
        /// </summary>
        /// <returns>The updated <see cref="CoachReportDetailResponse"/>.</returns>
        Task<CoachReportDetailResponse> SubmitReviewAsync(
            Guid coachId,
            Guid reportId,
            PtSubmitCoachReviewRequest request);
    }
}
