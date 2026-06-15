using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Controller quản lý thói quen nhắc nhở thích ứng (Adaptive Reminder) của người dùng.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class ReminderController : ControllerBase
    {
        private readonly IReminderService _service;

        public ReminderController(IReminderService service)
        {
            _service = service;
        }

        /// <summary>
        /// Lấy cấu hình thời gian ăn uống tối ưu hiện tại của người dùng.
        /// </summary>
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetProfileAsync(userId));
        }

        /// <summary>
        /// Tự động phân tích lịch sử ăn uống (MealLog) để tính toán lại các khung giờ ăn tối ưu.
        /// </summary>
        [HttpPost("profile/recalculate")]
        public async Task<IActionResult> RecalculateProfile()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.RecalculateProfileAsync(userId));
        }

        /// <summary>
        /// Cập nhật thủ công các khung giờ ăn uống tối ưu trong hồ sơ nhắc nhở của người dùng.
        /// </summary>
        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] ReminderProfileUpdateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateProfileAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy danh sách các thông báo nhắc nhở đã lên lịch trong tương lai chưa được gửi.
        /// </summary>
        [HttpGet("scheduled")]
        public async Task<IActionResult> GetScheduledReminders()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetScheduledRemindersAsync(userId));
        }

        /// <summary>
        /// Tạo mới một nhắc nhở tùy chỉnh được lên lịch gửi vào thời điểm xác định.
        /// </summary>
        [HttpPost("scheduled")]
        public async Task<IActionResult> CreateReminder([FromBody] ScheduledReminderCreateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.CreateReminderAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Cập nhật thông tin, thời gian hoặc trạng thái bật/tắt của một nhắc nhở đã lên lịch.
        /// </summary>
        [HttpPatch("scheduled/{id:guid}")]
        public async Task<IActionResult> UpdateReminder(Guid id, [FromBody] ScheduledReminderUpdateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateReminderAsync(userId, id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Xóa bỏ hoàn toàn một nhắc nhở đã lên lịch theo ID.
        /// </summary>
        [HttpDelete("scheduled/{id:guid}")]
        public async Task<IActionResult> DeleteReminder(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.DeleteReminderAsync(userId, id);
                return Ok(new { Message = "Reminder deleted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Tạm hoãn thông báo nhắc nhở thêm một số phút nhất định (mặc định hoãn 15 phút).
        /// </summary>
        [HttpPost("scheduled/{id:guid}/snooze")]
        public async Task<IActionResult> SnoozeReminder(Guid id, [FromQuery] int minutes = 15)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.SnoozeReminderAsync(userId, id, minutes));
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
