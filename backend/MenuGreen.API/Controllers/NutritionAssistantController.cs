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
    }
}
