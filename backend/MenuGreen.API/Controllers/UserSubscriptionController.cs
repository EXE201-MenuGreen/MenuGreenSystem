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
    /// Controller for User Subscription management.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class UserSubscriptionController : ControllerBase
    {
        private readonly IUserSubscriptionService _service;
        private readonly ISubscriptionPlanService _planService;

        public UserSubscriptionController(
            IUserSubscriptionService service,
            ISubscriptionPlanService planService)
        {
            _service = service;
            _planService = planService;
        }

        /// <summary>
        /// Get list of active subscription plans for user selection.
        /// </summary>
        [HttpGet("plans")]
        public async Task<IActionResult> GetAvailablePlans()
        {
            return Ok(await _planService.GetAllAsync(isActive: true));
        }

        /// <summary>
        /// Subscribe to a new plan for current user.
        /// </summary>
        [HttpPost("subscribe")]
        public async Task<IActionResult> Subscribe([FromBody] SubscribeRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                return Ok(await _service.SubscribeAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Renew current subscription.
        /// </summary>
        [HttpPost("renew")]
        public async Task<IActionResult> Renew([FromBody] RenewSubscriptionRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                return Ok(await _service.RenewAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Cancel subscription before expiration.
        /// </summary>
        [HttpPost("cancel")]
        public async Task<IActionResult> Cancel([FromBody] CancelSubscriptionRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                return Ok(await _service.CancelAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Get current user subscription.
        /// </summary>
        [HttpGet("me")]
        public async Task<IActionResult> GetCurrent()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetCurrentAsync(userId));
        }

        /// <summary>
        /// View details of a specific subscription by ID.
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
        /// Get full subscription/renew/cancel transaction history for user.
        /// </summary>
        [HttpGet("me/history")]
        public async Task<IActionResult> GetHistory()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetHistoryAsync(userId));
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
