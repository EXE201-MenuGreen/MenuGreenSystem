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
        /// Ghi nhận user đã mở thông báo.
        /// </summary>
        [HttpPatch("{id:guid}/open")]
        public async Task<IActionResult> Open(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.MarkAsReadAsync(userId, id));
        }

        /// <summary>
        /// Ghi nhận user đã bỏ qua thông báo.
        /// </summary>
        [HttpPatch("{id:guid}/dismiss")]
        public async Task<IActionResult> Dismiss(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.DismissAsync(userId, id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
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
        /// API này phục vụ workflow meal plan để nhắc trước giờ cooking.
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

        /// <summary>
        /// Lấy danh sách kênh thông báo mà hệ thống hỗ trợ.
        /// </summary>
        [HttpGet("channels")]
        public async Task<IActionResult> GetChannels()
        {
            return Ok(await _service.GetChannelsAsync());
        }

        /// <summary>
        /// Reset cấu hình thông báo của user về mặc định.
        /// </summary>
        [HttpPost("settings/reset")]
        public async Task<IActionResult> ResetSettings()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.ResetSettingsAsync(userId);
            return Ok();
        }

        /// <summary>
        /// Gửi một notification cụ thể tới user.
        /// </summary>
        [HttpPost("send")]
        public async Task<IActionResult> Send([FromBody] MenuGreen.BusinessLogicLayer.DTOs.Requests.NotificationSendRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try
            {
                return Ok(await _service.SendAsync(request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Ghi nhận notification được mở.
        /// </summary>
        [HttpPost("{notificationId:guid}/track/open")]
        public async Task<IActionResult> TrackOpen(Guid notificationId, [FromBody] MenuGreen.BusinessLogicLayer.DTOs.Requests.NotificationTrackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.TrackOpenAsync(userId, notificationId, request);
            return Ok();
        }

        /// <summary>
        /// Ghi nhận user click vào CTA của notification.
        /// </summary>
        [HttpPost("{notificationId:guid}/track/click")]
        public async Task<IActionResult> TrackClick(Guid notificationId, [FromBody] MenuGreen.BusinessLogicLayer.DTOs.Requests.NotificationTrackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.TrackClickAsync(userId, notificationId, request);
            return Ok();
        }

        /// <summary>
        /// Ghi nhận user hoàn thành hành động sau khi click notification.
        /// </summary>
        [HttpPost("{notificationId:guid}/track/action-complete")]
        public async Task<IActionResult> TrackActionComplete(Guid notificationId, [FromBody] MenuGreen.BusinessLogicLayer.DTOs.Requests.NotificationTrackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.TrackActionCompleteAsync(userId, notificationId, request);
            return Ok();
        }

        /// <summary>
        /// Trả về thống kê tổng hợp open/click của notification.
        /// </summary>
        [HttpGet("analytics")]
        public async Task<IActionResult> GetAnalytics()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetAnalyticsAsync(userId));
        }

        /// <summary>
        /// Gửi thông báo hàng loạt đến danh sách User IDs.
        /// </summary>
        [HttpPost("send/bulk")]
        public async Task<IActionResult> SendBulk([FromBody] NotificationSendBulkRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.SendBulkNotificationAsync(request));
        }

        /// <summary>
        /// Gửi thông báo tự động dựa theo sự kiện và ngữ cảnh cụ thể.
        /// </summary>
        [HttpPost("send/event")]
        public async Task<IActionResult> SendEvent([FromBody] NotificationSendEventRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try
            {
                return Ok(await _service.SendEventNotificationAsync(request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lên lịch gửi thông báo cho một user cụ thể vào thời gian xác định.
        /// </summary>
        [HttpPost("send/schedule")]
        public async Task<IActionResult> Schedule([FromBody] NotificationScheduleRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.ScheduleNotificationAsync(request));
        }

        /// <summary>
        /// Gửi lại các thông báo bị lỗi hoặc chưa được gửi đi.
        /// </summary>
        [HttpPost("send/retry")]
        public async Task<IActionResult> Retry([FromBody] NotificationRetryRequest request)
        {
            var count = await _service.RetryNotificationsAsync(request);
            return Ok(new { Message = $"Retried {count} notifications successfully.", Count = count });
        }

        /// <summary>
        /// Tạo mới chiến dịch re-engagement nhắc nhở người dùng quay lại.
        /// </summary>
        [HttpPost("campaigns")]
        public async Task<IActionResult> CreateCampaign([FromBody] CampaignUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.CreateCampaignAsync(request));
        }

        /// <summary>
        /// Lấy danh sách toàn bộ chiến dịch thông báo trong hệ thống.
        /// </summary>
        [HttpGet("campaigns")]
        public async Task<IActionResult> GetCampaigns()
        {
            return Ok(await _service.GetCampaignsAsync());
        }

        /// <summary>
        /// Lấy thông tin chi tiết một chiến dịch theo Campaign ID.
        /// </summary>
        [HttpGet("campaigns/{id:guid}")]
        public async Task<IActionResult> GetCampaignById(Guid id)
        {
            try
            {
                return Ok(await _service.GetCampaignByIdAsync(id));
            }
            catch (Exception ex)
            {
                return NotFound(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Cập nhật thông tin cấu hình, nội dung hoặc lịch gửi của chiến dịch.
        /// </summary>
        [HttpPut("campaigns/{id:guid}")]
        public async Task<IActionResult> UpdateCampaign(Guid id, [FromBody] CampaignUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try
            {
                return Ok(await _service.UpdateCampaignAsync(id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Kích hoạt chạy chiến dịch và tạo lịch gửi thông báo hàng loạt cho phân khúc mục tiêu.
        /// </summary>
        [HttpPost("campaigns/{id:guid}/run")]
        public async Task<IActionResult> RunCampaign(Guid id)
        {
            try
            {
                return Ok(await _service.RunCampaignAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Tạm dừng chiến dịch và tự động thu hồi các thông báo chưa gửi thuộc chiến dịch này.
        /// </summary>
        [HttpPost("campaigns/{id:guid}/pause")]
        public async Task<IActionResult> PauseCampaign(Guid id)
        {
            try
            {
                return Ok(await _service.PauseCampaignAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Báo cáo hiệu quả chiến dịch Re-engagement (tổng gửi, tỉ lệ mở, click và hoàn thành hành động).
        /// </summary>
        [HttpGet("analytics/re-engagement")]
        public async Task<IActionResult> GetReEngagementAnalytics()
        {
            return Ok(await _service.GetReEngagementAnalyticsAsync());
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
