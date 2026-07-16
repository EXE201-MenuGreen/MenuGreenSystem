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
    /// Controller for Adaptive Reminder habit management.
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
        /// Get current user optimal meal time configuration.
        /// </summary>
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetProfileAsync(userId));
        }

        /// <summary>
        /// Auto-analyze meal log history to recalculate optimal meal time windows.
        /// </summary>
        [HttpPost("profile/recalculate")]
        public async Task<IActionResult> RecalculateProfile()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.RecalculateProfileAsync(userId));
        }

        /// <summary>
        /// Manually update optimal meal time windows in user reminder profile.
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
        /// Get list of scheduled reminders not yet sent.
        /// </summary>
        [HttpGet("scheduled")]
        public async Task<IActionResult> GetScheduledReminders()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetScheduledRemindersAsync(userId));
        }

        /// <summary>
        /// Create a new custom reminder scheduled to be sent at specified time.
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
        /// Update scheduled reminder information, time, or enabled/disabled status.
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
        /// Permanently delete a scheduled reminder by ID.
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
        /// Snooze reminder notification for specified minutes (default 15 minutes).
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
