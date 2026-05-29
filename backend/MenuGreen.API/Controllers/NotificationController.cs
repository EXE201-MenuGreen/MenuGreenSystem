using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class NotificationController : ControllerBase
    {
        private readonly INotificationService _service;

        public NotificationController(INotificationService service)
        {
            _service = service;
        }

        // Lấy cấu hình nhắc nhở hiện tại của user.
        [HttpGet("settings")]
        public async Task<IActionResult> GetSettings()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetSettingsAsync(userId));
        }

        // Cập nhật cấu hình nhắc nhở của user: nhắc ăn, nhắc chuẩn bị, in-app, push.
        [HttpPut("settings")]
        public async Task<IActionResult> UpdateSettings([FromBody] NotificationSettingUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateSettingsAsync(userId, request));
        }

        // Lấy danh sách thông báo của user, có thể lọc chỉ thông báo chưa đọc.
        [HttpGet]
        public async Task<IActionResult> GetNotifications([FromQuery] bool? unreadOnly = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetNotificationsAsync(userId, unreadOnly));
        }

        // Đếm số thông báo chưa đọc để hiển thị badge trên UI.
        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(new { Count = await _service.GetUnreadCountAsync(userId) });
        }

        // Đánh dấu một thông báo cụ thể là đã đọc.
        [HttpPatch("{notificationId:guid}/read")]
        public async Task<IActionResult> MarkAsRead(Guid notificationId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.MarkAsReadAsync(userId, notificationId));
        }

        // Đánh dấu toàn bộ thông báo của user là đã đọc.
        [HttpPatch("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.MarkAllAsReadAsync(userId);
            return Ok();
        }

        // Tạo thông báo nhắc giờ ăn trước thời điểm ăn dự kiến.
        [HttpPost("schedule-meal-reminder")]
        public async Task<IActionResult> ScheduleMealReminder([FromBody] ScheduleMealReminderRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.ScheduleMealReminderAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        // Tạo thông báo nhắc chuẩn bị nguyên liệu trước khi nấu.
        [HttpPost("schedule-prep-reminder")]
        public async Task<IActionResult> SchedulePrepReminder([FromBody] SchedulePrepReminderRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.SchedulePrepReminderAsync(userId, request));
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
