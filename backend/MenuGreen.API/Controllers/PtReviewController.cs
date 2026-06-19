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
        /// Học viên tạo báo cáo tuần tĩnh và link chia sẻ cho PT.
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
        /// PT hoặc khách xem chi tiết báo cáo tuần của học viên thông qua token (không cần login).
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
        /// Học viên lấy danh sách các yêu cầu review đã tạo.
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
        /// PT gửi nhận xét và các đề xuất điều chỉnh thực đơn/calo thông qua token (không cần login).
        /// </summary>
        [HttpPost("shared-reports/{token}/submit")]
        [AllowAnonymous]
        public async Task<IActionResult> SubmitReview(string token, [FromBody] PtSubmitReviewRequest request)
        {
            try
            {
                await _service.SubmitReviewAsync(token, request);
                return Ok(new { message = "Gửi nhận xét thành công." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Học viên xem chi tiết phản hồi và các đề xuất chỉnh sửa thực đơn từ PT.
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
        /// Học viên phê duyệt và áp dụng các đề xuất của PT vào thực đơn/mục tiêu của mình.
        /// </summary>
        [HttpPost("requests/{requestId}/apply")]
        [Authorize]
        public async Task<IActionResult> ApplyReview(Guid requestId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.ApplyReviewAsync(userId, requestId);
                return Ok(new { message = "Áp dụng đề xuất thành công. Kế hoạch dinh dưỡng và mục tiêu calo/macro của bạn đã được cập nhật." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Học viên từ chối áp dụng các đề xuất và đóng yêu cầu review.
        /// </summary>
        [HttpPost("requests/{requestId}/reject")]
        [Authorize]
        public async Task<IActionResult> RejectReview(Guid requestId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.RejectReviewAsync(userId, requestId);
                return Ok(new { message = "Đã từ chối áp dụng đề xuất của PT." });
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
