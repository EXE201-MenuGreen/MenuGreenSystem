using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Admin controller for managing Micro-learning Cards — Create, Read, Update, Delete.
    /// </summary>
    [ApiController]
    [Route("api/admin/micro-learning")]
    [Authorize(Policy = "AdminOnly")]
    public class AdminMicroLearningController : ControllerBase
    {
        private readonly IMicroLearningService _service;

        public AdminMicroLearningController(IMicroLearningService service)
        {
            _service = service;
        }

        /// <summary>
        /// Get paginated list of all micro-learning cards for admin management.
        /// </summary>
        /// <param name="page">Page number (default: 1)</param>
        /// <param name="pageSize">Items per page (default: 20, max: 100)</param>
        [HttpGet("cards")]
        public async Task<IActionResult> GetAllCards([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;
            if (pageSize > 100) pageSize = 100;

            var result = await _service.GetAllCardsAsync(page, pageSize);
            return Ok(result);
        }

        /// <summary>
        /// Get a single micro-learning card by its ID.
        /// </summary>
        [HttpGet("cards/{id:guid}")]
        public async Task<IActionResult> GetCardById(Guid id)
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
        /// Create a new micro-learning card.
        /// </summary>
        [HttpPost("cards")]
        public async Task<IActionResult> CreateCard([FromBody] MicroLearningCardUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try
            {
                var result = await _service.CreateCardAsync(request);
                return CreatedAtAction(nameof(GetCardById), new { id = result.Id }, result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Update an existing micro-learning card.
        /// </summary>
        [HttpPut("cards/{id:guid}")]
        public async Task<IActionResult> UpdateCard(Guid id, [FromBody] MicroLearningCardUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try
            {
                var result = await _service.UpdateCardAsync(id, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return NotFound(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Delete a micro-learning card permanently.
        /// </summary>
        [HttpDelete("cards/{id:guid}")]
        public async Task<IActionResult> DeleteCard(Guid id)
        {
            try
            {
                var success = await _service.DeleteCardAsync(id);
                if (!success) return NotFound(new { message = "Micro-learning card not found." });
                return NoContent();
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Get all available categories for filtering.
        /// </summary>
        [HttpGet("categories")]
        public async Task<IActionResult> GetCategories()
        {
            var result = await _service.GetCategoriesAsync();
            return Ok(result);
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
