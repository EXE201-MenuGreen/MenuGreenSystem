using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/PtReview")]
    public class PtReviewController : ControllerBase
    {
        private readonly IPtReviewService _service;

        public PtReviewController(IPtReviewService service)
        {
            _service = service;
        }

        /// <summary>
        /// Student creates weekly report and share link for PT.
        /// </summary>
        [HttpPost("reports")]
        [Authorize]
        public async Task<IActionResult> CreateReport([FromBody] CreatePtReviewReportRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                var result = await _service.CreateReportAsync(userId, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// PT or guest views student weekly report via token (no login required).
        /// </summary>
        [HttpGet("shared-reports/{token}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetSharedReport(string token)
        {
            try
            {
                var result = await _service.GetSharedReportAsync(token);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Student gets list of review requests they have created.
        /// </summary>
        [HttpGet("my-requests")]
        [Authorize]
        public async Task<IActionResult> GetMyRequests()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                var result = await _service.GetMyRequestsAsync(userId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// PT submits review and menu/calorie adjustment suggestions via token (no login required).
        /// </summary>
        [HttpPost("shared-reports/{token}/submit")]
        [AllowAnonymous]
        public async Task<IActionResult> SubmitReview(string token, [FromBody] PtSubmitReviewRequest request)
        {
            try
            {
                await _service.SubmitReviewAsync(token, request);
                return Ok(new { message = "Review submitted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Student views detailed feedback and menu adjustment suggestions from PT.
        /// </summary>
        [HttpGet("requests/{requestId}/result")]
        [Authorize]
        public async Task<IActionResult> GetReviewResult(Guid requestId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                var result = await _service.GetReviewResultAsync(userId, requestId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Student approves and applies PT suggestions to their menu/goals.
        /// </summary>
        [HttpPost("requests/{requestId}/apply")]
        [Authorize]
        public async Task<IActionResult> ApplyReview(Guid requestId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.ApplyReviewAsync(userId, requestId);
                return Ok(new { message = "Suggestions applied successfully. Your nutrition plan and calorie/macro goals have been updated." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Student rejects applying suggestions and closes the review request.
        /// </summary>
        [HttpPost("requests/{requestId}/reject")]
        [Authorize]
        public async Task<IActionResult> RejectReview(Guid requestId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.RejectReviewAsync(userId, requestId);
                return Ok(new { message = "PT suggestions rejected." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
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
