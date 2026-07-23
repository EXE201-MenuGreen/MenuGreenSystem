using System;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "UserOnly")]
    [Authorize(Policy = "AiFeatures")]
    [Microsoft.AspNetCore.RateLimiting.EnableRateLimiting("AiPolicy")]
    public class AiCoachController : ControllerBase
    {
        private readonly INutritionAssistantService _nutritionAssistantService;
        private readonly IAiAssistantService _aiAssistantService;
        private readonly ApplicationDbContext _db;

        public AiCoachController(
            INutritionAssistantService nutritionAssistantService,
            IAiAssistantService aiAssistantService,
            ApplicationDbContext db)
        {
            _nutritionAssistantService = nutritionAssistantService;
            _aiAssistantService = aiAssistantService;
            _db = db;
        }

        [HttpGet("context")]
        public async Task<IActionResult> GetContext([FromQuery] string? date = null)
        {
            var userId = GetUserId();
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            return Ok(await _nutritionAssistantService.GetWorkerContextAsync(userId, date));
        }

        [HttpGet("suggested-prompts")]
        public async Task<IActionResult> GetSuggestedPrompts()
        {
            if (!TryGetUserGuid(out var userId))
            {
                return Unauthorized();
            }

            var prompts = await _aiAssistantService.GetSuggestionsAsync(userId);
            return Ok(new { Items = prompts });
        }

        [HttpPost("sessions")]
        public async Task<IActionResult> CreateSession([FromBody] CreateConversationRequest request)
        {
            if (!TryGetUserGuid(out var userId))
            {
                return Unauthorized();
            }

            return Ok(await _aiAssistantService.CreateConversationAsync(userId, request));
        }

        [HttpPost("sessions/{sessionId:guid}/messages")]
        public async Task<IActionResult> SendSessionMessage(Guid sessionId, [FromBody] SendMessageRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            if (!TryGetUserGuid(out var userId))
            {
                return Unauthorized();
            }

            return Ok(await _aiAssistantService.SendMessageAsync(userId, sessionId, request));
        }

        [HttpGet("sessions/{sessionId:guid}/history")]
        public async Task<IActionResult> GetSessionHistory(Guid sessionId)
        {
            if (!TryGetUserGuid(out var userId))
            {
                return Unauthorized();
            }

            return Ok(await _aiAssistantService.GetMessagesAsync(userId, sessionId));
        }

        [HttpDelete("sessions/{sessionId:guid}")]
        public async Task<IActionResult> DeleteSession(Guid sessionId)
        {
            if (!TryGetUserGuid(out var userId))
            {
                return Unauthorized();
            }

            await _aiAssistantService.DeleteConversationAsync(userId, sessionId);
            return Ok(new { Message = "AI Coach session deleted successfully." });
        }

        [HttpPost("execute-action")]
        public async Task<IActionResult> ExecuteAction([FromBody] AiWorkerActionExecuteRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userId = GetUserId();
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            return Ok(await _nutritionAssistantService.ExecuteWorkerActionAsync(userId, request));
        }

        [HttpPost("sessions/{sessionId:guid}/messages/{messageId:guid}/feedback")]
        public async Task<IActionResult> FeedbackSessionMessage(Guid sessionId, Guid messageId, [FromBody] MessageFeedbackRequest request)
        {
            if (!TryGetUserGuid(out var userId))
            {
                return Unauthorized();
            }

            await _aiAssistantService.FeedbackMessageAsync(userId, sessionId, messageId, request);
            return Ok(new { Message = "Feedback recorded successfully." });
        }

        [HttpPost("messages/{messageId:guid}/feedback")]
        public async Task<IActionResult> FeedbackMessage(Guid messageId, [FromBody] MessageFeedbackRequest request)
        {
            if (!TryGetUserGuid(out var userId))
            {
                return Unauthorized();
            }

            var message = await _db.AiMessages
                .AsNoTracking()
                .Where(x => x.Id == messageId && x.Conversation != null && x.Conversation.UserId == userId)
                .Select(x => new { x.ConversationId })
                .FirstOrDefaultAsync();

            if (message == null)
            {
                return NotFound(new { Message = "Message not found." });
            }

            await _aiAssistantService.FeedbackMessageAsync(userId, message.ConversationId, messageId, request);
            return Ok(new { Message = "Feedback recorded successfully." });
        }

        private string? GetUserId()
        {
            return User.Claims.FirstOrDefault(x => x.Type == ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("sub")?.Value;
        }

        private bool TryGetUserGuid(out Guid userId)
        {
            var raw = GetUserId();
            return Guid.TryParse(raw, out userId);
        }
    }
}
