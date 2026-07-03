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
    [Authorize(Policy = "UserOnly")]
    public class AiAssistantController : ControllerBase
    {
        private readonly IAiAssistantService _service;

        public AiAssistantController(IAiAssistantService service)
        {
            _service = service;
        }

        private bool TryGetUserId(out Guid userId)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }

        // ==========================================
        // A. Conversation Lifecycle
        // ==========================================

        /// <summary>
        /// Create a new chat session with AI assistant.
        /// </summary>
        [HttpPost("conversations")]
        public async Task<IActionResult> CreateConversation([FromBody] CreateConversationRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateConversationAsync(userId, request));
        }

        /// <summary>
        /// Get all conversations of current user.
        /// </summary>
        [HttpGet("conversations")]
        public async Task<IActionResult> GetConversations()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetConversationsAsync(userId));
        }

        /// <summary>
        /// Get details of a conversation by Id.
        /// </summary>
        [HttpGet("conversations/{id:guid}")]
        public async Task<IActionResult> GetConversationById(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetConversationByIdAsync(userId, id));
            }
            catch (Exception ex)
            {
                return NotFound(new { ex.Message });
            }
        }

        /// <summary>
        /// Delete a chat conversation by Id.
        /// </summary>
        [HttpDelete("conversations/{id:guid}")]
        public async Task<IActionResult> DeleteConversation(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.DeleteConversationAsync(userId, id);
            return Ok(new { Message = "Conversation deleted successfully." });
        }

        /// <summary>
        /// Update/rename chat conversation title.
        /// </summary>
        [HttpPatch("conversations/{id:guid}/title")]
        [HttpPost("conversations/{id:guid}/title")]
        public async Task<IActionResult> UpdateConversationTitle(Guid id, [FromBody] TitleUpdateRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateConversationTitleAsync(userId, id, request.Title));
            }
            catch (Exception ex)
            {
                return NotFound(new { ex.Message });
            }
        }

        // ==========================================
        // B. Message Workflow
        // ==========================================

        /// <summary>
        /// Send a new message to a conversation and receive AI response.
        /// </summary>
        [HttpPost("conversations/{id:guid}/messages")]
        public async Task<IActionResult> SendMessage(Guid id, [FromBody] SendMessageRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.SendMessageAsync(userId, id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { ex.Message });
            }
        }

        /// <summary>
        /// Get all messages in a specific conversation.
        /// </summary>
        [HttpGet("conversations/{id:guid}/messages")]
        public async Task<IActionResult> GetMessages(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetMessagesAsync(userId, id));
            }
            catch (Exception ex)
            {
                return NotFound(new { ex.Message });
            }
        }

        /// <summary>
        /// Request AI to regenerate alternative response for specified assistant message.
        /// </summary>
        [HttpPost("conversations/{id:guid}/messages/{msgId:guid}/regenerate")]
        public async Task<IActionResult> RegenerateMessage(Guid id, Guid msgId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.RegenerateMessageAsync(userId, id, msgId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { ex.Message });
            }
        }

        /// <summary>
        /// Submit feedback (like/dislike) for specific AI message.
        /// </summary>
        [HttpPatch("conversations/{id:guid}/messages/{msgId:guid}/feedback")]
        [HttpPost("conversations/{id:guid}/messages/{msgId:guid}/feedback")]
        public async Task<IActionResult> FeedbackMessage(Guid id, Guid msgId, [FromBody] MessageFeedbackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.FeedbackMessageAsync(userId, id, msgId, request);
                return Ok(new { Message = "Feedback recorded successfully." });
            }
            catch (Exception ex)
            {
                return NotFound(new { ex.Message });
            }
        }
        /// <summary>
        /// Get full current user health and nutrition context.
        /// </summary>
        [HttpGet("context")]
        public async Task<IActionResult> GetContext()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetContextAsync(userId));
        }

        /// <summary>
        /// Update user preference/priority context.
        /// </summary>
        [HttpPut("context")]
        public async Task<IActionResult> UpdateContext([FromBody] UpdateAiProfileRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateProfileAsync(userId, request));
        }

        /// Get user AI profile information (Preferences, DislikedFoods, EatingPattern).
        /// </summary>
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetProfileAsync(userId));
        }

        /// <summary>
        /// Update user AI profile.
        /// </summary>
        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateAiProfileRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateProfileAsync(userId, request));
        }

        // ==========================================
        // D. Action Suggestions
        // ==========================================

        /// <summary>
        /// Get list of suggested next action questions based on nutrition profile.
        /// </summary>
        [HttpGet("suggestions")]
        public async Task<IActionResult> GetSuggestions()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetSuggestionsAsync(userId));
        }

        /// <summary>
        /// AI analyzes and suggests creating Meal Plan from text prompt.
        /// </summary>
        [HttpPost("actions/meal-plan")]
        public async Task<IActionResult> GenerateMealPlan([FromBody] PromptRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GenerateMealPlanFromAiAsync(userId, request.Prompt));
        }

        /// <summary>
        /// AI suggests healthy food/ingredient replacements based on specific reason.
        /// </summary>
        [HttpPost("actions/replace-food")]
        public async Task<IActionResult> ReplaceFood([FromBody] ReplaceFoodRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.SuggestFoodReplacementAsync(userId, request.FoodId, request.Reason));
        }

        /// <summary>
        /// AI suggests optimal food budget optimization.
        /// </summary>
        [HttpPost("actions/budget-optimize")]
        public async Task<IActionResult> BudgetOptimize()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.OptimizeBudgetAsync(userId));
        }

        // ==========================================
        // E. History & Analytics
        // ==========================================

        /// <summary>
        /// Get statistics on main discussion topics with AI assistant.
        /// </summary>
        [HttpGet("insights")]
        public async Task<IActionResult> GetInsights()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetInsightsAsync(userId));
        }

        /// <summary>
        /// Get brief summary text of specified conversation.
        /// </summary>
        [HttpGet("conversations/{id:guid}/summary")]
        public async Task<IActionResult> SummarizeConversation(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                var summary = await _service.SummarizeConversationAsync(userId, id);
                return Ok(new { Summary = summary });
            }
            catch (Exception ex)
            {
                return NotFound(new { ex.Message });
            }
        }

        /// <summary>
        /// Usage metrics statistics by time for user.
        /// </summary>
        [HttpGet("usage")]
        public async Task<IActionResult> GetUsageMetrics()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetUsageMetricsAsync(userId));
        }

        // ==========================================
        // Helper DTOs for Controllers
        // ==========================================

        public class TitleUpdateRequest
        {
            public string Title { get; set; } = string.Empty;
        }

        public class PromptRequest
        {
            public string Prompt { get; set; } = string.Empty;
        }

        public class ReplaceFoodRequest
        {
            public Guid FoodId { get; set; }
            public string Reason { get; set; } = string.Empty;
        }
    }
}
