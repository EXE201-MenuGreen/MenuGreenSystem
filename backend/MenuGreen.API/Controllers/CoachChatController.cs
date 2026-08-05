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
    [Route("api/coach-chat")]
    [Authorize]
    public class CoachChatController : ControllerBase
    {
        private readonly ICoachChatService _chatService;

        public CoachChatController(ICoachChatService chatService)
        {
            _chatService = chatService;
        }

        [HttpGet("partners")]
        public async Task<IActionResult> GetPartners([FromQuery] string? scope = null)
        {
            return TryGetUserId(out var userId)
                ? Ok(await _chatService.GetPartnersAsync(userId, scope))
                : Unauthorized();
        }

        [HttpGet("{partnerId:guid}/messages")]
        public async Task<IActionResult> GetMessages(
            Guid partnerId,
            [FromQuery] DateTimeOffset? before,
            [FromQuery] int take = 50)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _chatService.GetMessagesAsync(
                    userId, partnerId, before, take));
            }
            catch (UnauthorizedAccessException exception)
            {
                return StatusCode(403, new { Message = exception.Message });
            }
        }

        [HttpPost("{partnerId:guid}/messages")]
        public async Task<IActionResult> SendMessage(
            Guid partnerId,
            [FromBody] SendCoachChatMessageRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _chatService.SendMessageAsync(
                    userId, partnerId, request.Content));
            }
            catch (UnauthorizedAccessException exception)
            {
                return StatusCode(403, new { Message = exception.Message });
            }
            catch (ArgumentException exception)
            {
                return BadRequest(new { Message = exception.Message });
            }
        }

        [HttpPost("{partnerId:guid}/read")]
        public async Task<IActionResult> MarkRead(Guid partnerId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                var marked = await _chatService.MarkConversationReadAsync(
                    userId, partnerId);
                return Ok(new { Marked = marked });
            }
            catch (UnauthorizedAccessException exception)
            {
                return StatusCode(403, new { Message = exception.Message });
            }
        }

        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount(
            [FromQuery] string? scope = null)
        {
            return TryGetUserId(out var userId)
                ? Ok(new
                {
                    Count = await _chatService.GetUnreadCountAsync(userId, scope)
                })
                : Unauthorized();
        }

        private bool TryGetUserId(out Guid userId)
        {
            var raw = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue("sub");
            return Guid.TryParse(raw, out userId);
        }
    }
}
