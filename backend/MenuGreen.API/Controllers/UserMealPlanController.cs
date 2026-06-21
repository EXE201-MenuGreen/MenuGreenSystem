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
    [Route("api/user-meal-plans")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class UserMealPlanController : ControllerBase
    {
        private readonly IMealPlanService _service;

        public UserMealPlanController(IMealPlanService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> GetByDate([FromQuery] DateOnly date)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var plan = await _service.GetByDateAsync(userId, date);
            if (plan == null) return NotFound(new { Message = "Meal plan not found." });
            return Ok(plan);
        }

        [HttpGet("adherence")]
        public async Task<IActionResult> GetAdherence([FromQuery] DateOnly date)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetAdherenceAsync(userId, date));
        }

        [HttpPost]
        public async Task<IActionResult> CreateOrUpdate([FromBody] UserMealPlanUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.CreateOrUpdateDailyAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPost("from-daily-menu")]
        public async Task<IActionResult> CreateFromDailyMenu([FromBody] CreateMealPlanFromDailyMenuRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.CreateFromDailyMenuAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPost("items/{itemId:guid}/complete")]
        public async Task<IActionResult> CompleteItem(Guid itemId, [FromBody] CompleteMealPlanItemRequest? request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.CompleteItemAsync(userId, itemId, request ?? new CompleteMealPlanItemRequest()));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpDelete("{mealPlanId:guid}")]
        public async Task<IActionResult> Delete(Guid mealPlanId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.DeleteAsync(mealPlanId, userId);
                return Ok(new { Message = "Deleted successfully." });
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
