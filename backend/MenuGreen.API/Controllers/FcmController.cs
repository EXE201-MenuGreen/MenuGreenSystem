using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class FcmController : ControllerBase
    {
        private readonly IFcmService _fcmService;
        private readonly ILogger<FcmController> _logger;

        public FcmController(IFcmService fcmService, ILogger<FcmController> logger)
        {
            _fcmService = fcmService;
            _logger = logger;
        }

        /// <summary>
        /// Register a device token for push notifications.
        /// </summary>
        [HttpPost("register")]
        public async Task<IActionResult> RegisterToken([FromBody] DeviceTokenRegisterRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Token))
            {
                return BadRequest(new { Message = "Token is required." });
            }

            if (!TryGetUserId(out var userId))
            {
                return Unauthorized();
            }

            try
            {
                var result = await _fcmService.RegisterTokenAsync(userId, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to register FCM token.");
                return StatusCode(500, new { Message = "Internal server error." });
            }
        }

        /// <summary>
        /// Remove a device token.
        /// </summary>
        [HttpDelete("remove")]
        public async Task<IActionResult> RemoveToken([FromBody] RemoveTokenRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Token))
            {
                return BadRequest(new { Message = "Token is required." });
            }

            if (!TryGetUserId(out var userId))
            {
                return Unauthorized();
            }

            var success = await _fcmService.RemoveTokenAsync(userId, request.Token);
            if (!success)
            {
                return NotFound(new { Message = "Token not found." });
            }

            return Ok(new { Message = "Token removed successfully." });
        }

        /// <summary>
        /// Get all device tokens for the current user.
        /// </summary>
        [HttpGet("tokens")]
        public async Task<IActionResult> GetUserTokens()
        {
            if (!TryGetUserId(out var userId))
            {
                return Unauthorized();
            }

            var tokens = await _fcmService.GetUserTokensAsync(userId);
            return Ok(tokens);
        }

        /// <summary>
        /// Send a push notification to the current user.
        /// </summary>
        [HttpPost("send")]
        public async Task<IActionResult> SendToUser([FromBody] SendPushRequest request)
        {
            if (!TryGetUserId(out var userId))
            {
                return Unauthorized();
            }

            try
            {
                var result = await _fcmService.SendToUserAsync(userId, request.Title, request.Body, request.Data);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send push notification.");
                return StatusCode(500, new { Message = "Internal server error." });
            }
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }

    public class RemoveTokenRequest
    {
        public string Token { get; set; } = string.Empty;
    }

    public class SendPushRequest
    {
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public string? Data { get; set; }
    }
}
