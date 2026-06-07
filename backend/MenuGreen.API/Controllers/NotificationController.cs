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
    /// Controller quản lý Notification - Thông báo và nhắc nhở.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class NotificationController : ControllerBase
    {
        private readonly INotificationService _service;

        public NotificationController(INotificationService service)
        {
            _service = service;
        }

        /// <summary>
        /// Lấy cấu hình nhắc nhở hiện tại của user.
        /// </summary>
        [HttpGet("settings")]
        public async Task<IActionResult> GetSettings()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetSettingsAsync(userId));
        }

        /// <summary>
        /// Cập nhật cấu hình nhắc nhở của user.
        /// </summary>
        [HttpPut("settings")]
        public async Task<IActionResult> UpdateSettings([FromBody] NotificationSettingUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateSettingsAsync(userId, request));
        }

        /// <summary>
        /// Lấy danh sách thông báo của user (có thể lọc chưa đọc).
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetNotifications([FromQuery] bool? unreadOnly = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetNotificationsAsync(userId, unreadOnly));
        }

        /// <summary>
        /// Xem chi tiết một thông báo cụ thể theo ID.
        /// </summary>
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            
            try
            {
                return Ok(await _service.GetByIdAsync(userId, id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Đếm số thông báo chưa đọc để hiển thị badge.
        /// </summary>
        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(new { Count = await _service.GetUnreadCountAsync(userId) });
        }

        /// <summary>
        /// Đánh dấu một thông báo cụ thể là đã đọc.
        /// </summary>
        [HttpPatch("{notificationId:guid}/read")]
        public async Task<IActionResult> MarkAsRead(Guid notificationId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.MarkAsReadAsync(userId, notificationId));
        }

        /// <summary>
        /// Đánh dấu toàn bộ thông báo của user là đã đọc.
        /// </summary>
        [HttpPatch("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.MarkAllAsReadAsync(userId);
            return Ok();
        }

        /// <summary>
        /// Xóa một thông báo.
        /// </summary>
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            
            try
            {
                await _service.DeleteAsync(userId, id);
                return Ok(new { Message = "Notification deleted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Xóa nhiều thông báo cùng lúc theo danh sách IDs.
        /// </summary>
        [HttpDelete("batch")]
        public async Task<IActionResult> DeleteBatch([FromBody] DeleteNotificationBatchRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            
            try
            {
                var deletedCount = await _service.DeleteBatchAsync(userId, request.NotificationIds);
                return Ok(new { Message = $"Deleted {deletedCount} notification(s) successfully.", DeletedCount = deletedCount });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Xóa thông báo trong khoảng thời gian.
        /// </summary>
        [HttpDelete("range")]
        public async Task<IActionResult> DeleteByRange([FromQuery] DateOnly startDate, [FromQuery] DateOnly endDate)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            
            try
            {
                var deletedCount = await _service.DeleteByRangeAsync(userId, startDate, endDate);
                return Ok(new { Message = $"Deleted {deletedCount} notification(s) successfully.", DeletedCount = deletedCount });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Tạo thông báo nhắc giờ ăn trước thời điểm ăn dự kiến.
        /// API này phục vụ workflow meal plan để bấm nhắc cho từng bữa đã lên kế hoạch.
        /// </summary>
        [HttpPost("meal-plan-remind")]
        public async Task<IActionResult> MealPlanRemind([FromBody] ScheduleMealReminderRequest request)
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

        /// <summary>
        /// Tạo thông báo nhắc chuẩn bị nguyên liệu trước khi nấu.
        /// </summary>
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
