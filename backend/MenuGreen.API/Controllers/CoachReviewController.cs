using System;
using System.Globalization;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Coach-side weekly report endpoints. Logged-in Coaches (CoachOnly
    /// policy) see / review weekly reports from their connected Gymers,
    /// scoped by <c>CoachConnection.Status = "Connected"</c>.
    /// </summary>
    [ApiController]
    [Route("api/PtReview/coach")]
    [Authorize(Policy = "CoachOnly")]
    public class CoachReviewController : ControllerBase
    {
        private readonly ICoachReviewService _service;

        public CoachReviewController(ICoachReviewService service)
        {
            _service = service;
        }

        /// <summary>
        /// GET /api/PtReview/coach/reports
        /// List weekly reports across the Coach's connected Gymers.
        /// Optional filters: weekStart (yyyy-MM-dd), month ('YYYY-MM'),
        /// status, clientId (single Gymer scope).
        /// </summary>
        [HttpGet("reports")]
        public async Task<IActionResult> ListReports(
            [FromQuery] string? weekStart,
            [FromQuery] string? month,
            [FromQuery] string? status,
            [FromQuery] Guid? clientId)
        {
            if (!TryGetUserId(out var coachId)) return Unauthorized();

            try
            {
                DateTime? parsedWeek = null;
                if (!string.IsNullOrWhiteSpace(weekStart))
                {
                    if (!DateTime.TryParseExact(weekStart, "yyyy-MM-dd",
                            CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal,
                            out var ws))
                    {
                        return BadRequest(new { Message = "weekStart must be yyyy-MM-dd." });
                    }
                    parsedWeek = ws;
                }

                var result = await _service.ListReportsAsync(
                    coachId, parsedWeek, month, status, clientId);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// GET /api/PtReview/coach/reports/{reportId}
        /// Full report payload (ReportData + suggested changes + PT comment)
        /// for a single weekly report. Rejects access if the Coach is not
        /// connected to the report's owner.
        /// </summary>
        [HttpGet("reports/{reportId:guid}")]
        public async Task<IActionResult> GetReportDetail(Guid reportId)
        {
            if (!TryGetUserId(out var coachId)) return Unauthorized();

            try
            {
                var result = await _service.GetReportDetailAsync(coachId, reportId);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return NotFound(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// POST /api/PtReview/coach/reports/{reportId}/review
        /// Coach submits feedback + optional inline meal-plan adjustments.
        /// On success the report moves to <c>Reviewed</c> and any inline
        /// adjustments are pushed to the Gymer's actual meal plan immediately.
        /// </summary>
        [HttpPost("reports/{reportId:guid}/review")]
        public async Task<IActionResult> SubmitReview(
            Guid reportId,
            [FromBody] PtSubmitCoachReviewRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var coachId)) return Unauthorized();

            try
            {
                var result = await _service.SubmitReviewAsync(coachId, reportId, request);
                return Ok(new
                {
                    Message = "Review submitted. Student has been notified.",
                    Report = result
                });
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
