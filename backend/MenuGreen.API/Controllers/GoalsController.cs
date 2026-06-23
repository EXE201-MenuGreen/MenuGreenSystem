using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Controller for Goal Drift Alert management.
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
        /// Get all goal drift alerts for user.
        /// </summary>
        [HttpGet("drift-alerts")]
        public async Task<IActionResult> GetAlerts()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetAlertsAsync(userId));
        }

        /// <summary>
        /// Get current goal drift alert (unconfirmed and unhidden).
        /// </summary>
        [HttpGet("drift-alerts/current")]
        public async Task<IActionResult> GetCurrentAlert()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var alert = await _service.GetCurrentAlertAsync(userId);
            if (alert == null) return NotFound(new { Message = "No current goal drift alert." });
            return Ok(alert);
        }

        /// <summary>
        /// Analyze 7-day nutrition history and recalculate goal drift alerts.
        /// </summary>
        [HttpPost("drift-alerts/recalculate")]
        public async Task<IActionResult> RecalculateDrift()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var alert = await _service.RecalculateDriftAsync(userId);
            if (alert == null) return Ok(new { Message = "Your nutrition data is stable, no goal drift detected." });
            return Ok(alert);
        }

        /// <summary>
        /// Get summary report of 7-day nutrition drift situation for user.
        /// </summary>
        [HttpGet("drift-alerts/summary")]
        public async Task<IActionResult> GetSummary()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetSummaryAsync(userId));
        }

        /// <summary>
        /// Dismiss goal drift alert by ID.
        /// </summary>
        [HttpPost("drift-alerts/{id:guid}/dismiss")]
        public async Task<IActionResult> DismissAlert(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.DismissAlertAsync(userId, id);
                return Ok(new { Message = "Alert dismissed successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Acknowledge reading/understanding goal drift alert by ID.
        /// </summary>
        [HttpPost("drift-alerts/{id:guid}/acknowledge")]
        public async Task<IActionResult> AcknowledgeAlert(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.AcknowledgeAlertAsync(userId, id);
                return Ok(new { Message = "Alert acknowledged successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Send in-app reminder notification from goal drift alert by ID.
        /// </summary>
        [HttpPost("drift-alerts/{id:guid}/create-nudge")]
        public async Task<IActionResult> CreateNudge(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.CreateNudgeAsync(userId, id);
                return Ok(new { Message = "Reminder notification sent successfully." });
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
