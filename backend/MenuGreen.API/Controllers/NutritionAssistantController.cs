using System;
using System.Collections.Generic;
using System.Linq;
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
    [Authorize(Policy = "AiFeatures")]
    [Microsoft.AspNetCore.RateLimiting.EnableRateLimiting("AiPolicy")]
    public class NutritionAssistantController : ControllerBase
    {
        private readonly INutritionAssistantService _service;

        public NutritionAssistantController(INutritionAssistantService service)
        {
            _service = service;
        }

        [HttpPost("chat")]
        public async Task<IActionResult> Chat([FromBody] NutritionAssistantChatRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userId = User.Claims.FirstOrDefault(x => x.Type == ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("sub")?.Value;

            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var result = await _service.SendMessageAsync(userId, request);
            return Ok(result);
        }

        [HttpPost("chat/stream")]
        public async Task<IActionResult> ChatStream([FromBody] NutritionAssistantChatRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userId = User.Claims.FirstOrDefault(x => x.Type == ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("sub")?.Value;

            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            Response.ContentType = "text/event-stream";
            Response.Headers["Cache-Control"] = "no-cache";
            await _service.StreamMessageAsync(userId, request, Response.Body, HttpContext.RequestAborted);
            return new EmptyResult();
        }

        [HttpGet("context")]
        public async Task<IActionResult> GetWorkerContext([FromQuery] string? date = null)
        {
            var userId = User.Claims.FirstOrDefault(x => x.Type == ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("sub")?.Value;

            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var result = await _service.GetWorkerContextAsync(userId, date);
            return Ok(result);
        }

        [HttpPost("recommendations/{mode}")]
        public async Task<IActionResult> GenerateWorkerRecommendation(
            string mode,
            [FromBody] AiWorkerRecommendationRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userId = User.Claims.FirstOrDefault(x => x.Type == ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("sub")?.Value;

            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            try
            {
                var result = await _service.GenerateWorkerRecommendationAsync(userId, mode, request);
                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { ex.Message });
            }
        }

        [HttpPost("actions/execute")]
        public async Task<IActionResult> ExecuteWorkerAction([FromBody] AiWorkerActionExecuteRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userId = User.Claims.FirstOrDefault(x => x.Type == ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("sub")?.Value;

            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var result = await _service.ExecuteWorkerActionAsync(userId, request);
            return Ok(result);
        }

        [HttpGet("conversations")]
        public async Task<IActionResult> GetConversations([FromQuery] int take = 20)
        {
            var userId = User.Claims.FirstOrDefault(x => x.Type == ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("sub")?.Value;

            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var result = await _service.GetConversationsAsync(userId, take);
            return Ok(result);
        }

        [HttpGet("conversations/{conversationId:guid}")]
        public async Task<IActionResult> GetConversation(Guid conversationId)
        {
            var userId = User.Claims.FirstOrDefault(x => x.Type == ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("sub")?.Value;

            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            try
            {
                var result = await _service.GetConversationAsync(userId, conversationId);
                return Ok(result);
            }
            catch (KeyNotFoundException)
            {
                return NotFound(new { Message = "Conversation not found." });
            }
        }

        [HttpPost("feedback")]
        public async Task<IActionResult> CreateFeedback([FromBody] NutritionAssistantFeedbackRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userId = User.Claims.FirstOrDefault(x => x.Type == ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("sub")?.Value;

            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            try
            {
                var result = await _service.CreateFeedbackAsync(userId, request);
                return StatusCode(201, result);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { ex.Message });
            }
        }

        [HttpPost("meal-plans/7d")]
        public async Task<IActionResult> GenerateMealPlan7d([FromBody] NutritionAssistantMealPlan7dRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userId = User.Claims.FirstOrDefault(x => x.Type == ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("sub")?.Value;

            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            try
            {
                var result = await _service.GenerateMealPlan7dAsync(userId, request);
                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { ex.Message });
            }
        }
    }
}
