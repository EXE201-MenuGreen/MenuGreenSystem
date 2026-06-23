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
    /// Controller for Notification management - notifications and reminders.
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
        /// Get current user reminder settings.
        /// </summary>
        [HttpGet("settings")]
        public async Task<IActionResult> GetSettings()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetSettingsAsync(userId));
        }

        /// <summary>
        /// Update user reminder settings.
        /// </summary>
        [HttpPut("settings")]
        public async Task<IActionResult> UpdateSettings([FromBody] NotificationSettingUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateSettingsAsync(userId, request));
        }

        /// <summary>
        /// Get user notifications (can filter by unread).
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetNotifications([FromQuery] bool? unreadOnly = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetNotificationsAsync(userId, unreadOnly));
        }

        /// <summary>
        /// Get details of a specific notification by ID.
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
        /// Count unread notifications for badge display.
        /// </summary>
        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(new { Count = await _service.GetUnreadCountAsync(userId) });
        }

        /// <summary>
        /// Mark a specific notification as read.
        /// </summary>
        [HttpPatch("{notificationId:guid}/read")]
        public async Task<IActionResult> MarkAsRead(Guid notificationId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.MarkAsReadAsync(userId, notificationId));
        }

        /// <summary>
        /// Record when user opens a notification.
        /// </summary>
        [HttpPatch("{id:guid}/open")]
        public async Task<IActionResult> Open(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.MarkAsReadAsync(userId, id));
        }

        /// <summary>
        /// Record when user dismisses a notification.
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
        /// Mark all user notifications as read.
        /// </summary>
        [HttpPatch("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.MarkAllAsReadAsync(userId);
            return Ok();
        }

        /// <summary>
        /// Delete a notification.
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
        /// Delete multiple notifications at once by list of IDs.
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
        /// Delete notifications within a date range.
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
        /// Create meal time reminder notification before planned meal time.
        /// This API serves meal plan workflow to remind for each planned meal.
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
        /// Create ingredient prep reminder notification before cooking time.
        /// This API serves meal plan workflow to remind before cooking time.
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
        /// Get list of notification channels supported by the system.
        /// </summary>
        [HttpGet("channels")]
        public async Task<IActionResult> GetChannels()
        {
            return Ok(await _service.GetChannelsAsync());
        }

        /// <summary>
        /// Reset user notification settings to default.
        /// </summary>
        [HttpPost("settings/reset")]
        public async Task<IActionResult> ResetSettings()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.ResetSettingsAsync(userId);
            return Ok();
        }

        /// <summary>
        /// Send a specific notification to a user.
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
        /// Record when a notification is opened.
        /// </summary>
        [HttpPost("{notificationId:guid}/track/open")]
        public async Task<IActionResult> TrackOpen(Guid notificationId, [FromBody] MenuGreen.BusinessLogicLayer.DTOs.Requests.NotificationTrackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.TrackOpenAsync(userId, notificationId, request);
            return Ok();
        }

        /// <summary>
        /// Record when user clicks on notification CTA.
        /// </summary>
        [HttpPost("{notificationId:guid}/track/click")]
        public async Task<IActionResult> TrackClick(Guid notificationId, [FromBody] MenuGreen.BusinessLogicLayer.DTOs.Requests.NotificationTrackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.TrackClickAsync(userId, notificationId, request);
            return Ok();
        }

        /// <summary>
        /// Record when user completes action after clicking notification.
        /// </summary>
        [HttpPost("{notificationId:guid}/track/action-complete")]
        public async Task<IActionResult> TrackActionComplete(Guid notificationId, [FromBody] MenuGreen.BusinessLogicLayer.DTOs.Requests.NotificationTrackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.TrackActionCompleteAsync(userId, notificationId, request);
            return Ok();
        }

        /// <summary>
        /// Return aggregated open/click notification statistics.
        /// </summary>
        [HttpGet("analytics")]
        public async Task<IActionResult> GetAnalytics()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetAnalyticsAsync(userId));
        }

        /// <summary>
        /// Send bulk notifications to a list of User IDs.
        /// </summary>
        [HttpPost("send/bulk")]
        public async Task<IActionResult> SendBulk([FromBody] NotificationSendBulkRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.SendBulkNotificationAsync(request));
        }

        /// <summary>
        /// Send automatic notifications based on specific events and context.
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
        /// Schedule a notification for a specific user at a specified time.
        /// </summary>
        [HttpPost("send/schedule")]
        public async Task<IActionResult> Schedule([FromBody] NotificationScheduleRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.ScheduleNotificationAsync(request));
        }

        /// <summary>
        /// Retry sending failed or pending notifications.
        /// </summary>
        [HttpPost("send/retry")]
        public async Task<IActionResult> Retry([FromBody] NotificationRetryRequest request)
        {
            var count = await _service.RetryNotificationsAsync(request);
            return Ok(new { Message = $"Retried {count} notifications successfully.", Count = count });
        }

        /// <summary>
        /// Create new re-engagement campaign to remind users to return.
        /// </summary>
        [HttpPost("campaigns")]
        public async Task<IActionResult> CreateCampaign([FromBody] CampaignUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.CreateCampaignAsync(request));
        }

        /// <summary>
        /// Get list of all notification campaigns in the system.
        /// </summary>
        [HttpGet("campaigns")]
        public async Task<IActionResult> GetCampaigns()
        {
            return Ok(await _service.GetCampaignsAsync());
        }

        /// <summary>
        /// Get detailed information of a campaign by Campaign ID.
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
        /// Update campaign settings, content, or sending schedule.
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
        /// Activate and run campaign, creating bulk notification schedule for target segment.
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
        /// Pause campaign and automatically withdraw unsent notifications for this campaign.
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
        /// Report re-engagement campaign effectiveness (total sent, open rate, click rate, and action completion rate).
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
