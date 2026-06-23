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
    /// Controller for Micro-learning Cards feature - short nutrition learning and quiz for points.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class MicroLearningController : ControllerBase
    {
        private readonly IMicroLearningService _service;

        public MicroLearningController(IMicroLearningService service)
        {
            _service = service;
        }

        /// <summary>
        /// Get list of recommended short knowledge cards based on user's actual nutrition/health issues.
        /// </summary>
        [HttpGet("cards/recommended")]
        public async Task<IActionResult> GetRecommended()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var result = await _service.GetRecommendedCardsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// View detailed content of a micro-learning card (including title, summary, quick tips, quiz).
        /// </summary>
        [HttpGet("cards/{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                var result = await _service.GetCardByIdAsync(id, userId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return NotFound(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Get catalog of knowledge topic categories (Protein, Sodium, Allergy, Hydration, General).
        /// </summary>
        [HttpGet("categories")]
        public async Task<IActionResult> GetCategories()
        {
            var result = await _service.GetCategoriesAsync();
            return Ok(result);
        }

        /// <summary>
        /// Record user interaction with a card (read, save, unsave, dismiss).
        /// </summary>
        [HttpPost("cards/{id:guid}/action")]
        public async Task<IActionResult> RecordAction(Guid id, [FromBody] CardActionRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _service.RecordCardActionAsync(userId, id, request.Action);
                return Ok(new { success = result, message = $"Action '{request.Action}' recorded successfully." });
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return NotFound(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Get list of all saved knowledge cards for user.
        /// </summary>
        [HttpGet("cards/saved")]
        public async Task<IActionResult> GetSavedCards()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var result = await _service.GetSavedCardsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Submit quiz answer on card to receive feedback and earn bonus points.
        /// </summary>
        [HttpPost("cards/{id:guid}/quiz/submit")]
        public async Task<IActionResult> SubmitQuiz(Guid id, [FromBody] QuizSubmitRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _service.SubmitQuizAnswerAsync(userId, id, request.SelectedOptionIndex);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
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
