using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Controller quản lý cảnh báo trôi lệch mục tiêu (Goal Drift Alert) của người dùng.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class GoalsController : ControllerBase
    {
        private readonly IGoalDriftService _service;

        public GoalsController(IGoalDriftService service)
        {
            _service = service;
        }

        /// <summary>
        /// Lấy danh sách tất cả cảnh báo trôi lệch mục tiêu của người dùng.
        /// </summary>
        [HttpGet("drift-alerts")]
        public async Task<IActionResult> GetAlerts()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetAlertsAsync(userId));
        }

        /// <summary>
        /// Lấy cảnh báo trôi lệch mục tiêu hiện tại (chưa xác nhận và chưa ẩn).
        /// </summary>
        [HttpGet("drift-alerts/current")]
        public async Task<IActionResult> GetCurrentAlert()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var alert = await _service.GetCurrentAlertAsync(userId);
            if (alert == null) return NotFound(new { Message = "Không có cảnh báo trôi lệch mục tiêu nào hiện tại." });
            return Ok(alert);
        }

        /// <summary>
        /// Phân tích lịch sử dinh dưỡng 7 ngày qua và tính toán lại cảnh báo trôi lệch mục tiêu.
        /// </summary>
        [HttpPost("drift-alerts/recalculate")]
        public async Task<IActionResult> RecalculateDrift()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var alert = await _service.RecalculateDriftAsync(userId);
            if (alert == null) return Ok(new { Message = "Dữ liệu dinh dưỡng của bạn ổn định, không phát hiện trôi lệch mục tiêu." });
            return Ok(alert);
        }

        /// <summary>
        /// Lấy báo cáo tóm tắt tình hình trôi lệch dinh dưỡng 7 ngày qua của người dùng.
        /// </summary>
        [HttpGet("drift-alerts/summary")]
        public async Task<IActionResult> GetSummary()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetSummaryAsync(userId));
        }

        /// <summary>
        /// Ẩn cảnh báo trôi lệch mục tiêu theo ID.
        /// </summary>
        [HttpPost("drift-alerts/{id:guid}/dismiss")]
        public async Task<IActionResult> DismissAlert(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.DismissAlertAsync(userId, id);
                return Ok(new { Message = "Cảnh báo đã được ẩn thành công." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Xác nhận đã đọc/hiểu cảnh báo trôi lệch mục tiêu theo ID.
        /// </summary>
        [HttpPost("drift-alerts/{id:guid}/acknowledge")]
        public async Task<IActionResult> AcknowledgeAlert(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.AcknowledgeAlertAsync(userId, id);
                return Ok(new { Message = "Cảnh báo đã được xác nhận thành công." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Gửi thông báo nhắc nhở in-app động từ cảnh báo trôi lệch mục tiêu theo ID.
        /// </summary>
        [HttpPost("drift-alerts/{id:guid}/create-nudge")]
        public async Task<IActionResult> CreateNudge(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.CreateNudgeAsync(userId, id);
                return Ok(new { Message = "Thông báo nhắc nhở đã được gửi thành công." });
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
