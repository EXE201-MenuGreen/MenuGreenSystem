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
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class NutritionTrackingController : ControllerBase
    {
        private readonly INutritionTrackingService _service;

        public NutritionTrackingController(INutritionTrackingService service)
        {
            _service = service;
        }

        [HttpPost("meal-logs")]
        public async Task<IActionResult> CreateMealLog([FromBody] MealLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateMealLogAsync(userId, request));
        }

        [HttpPut("meal-logs/{mealLogId:guid}")]
        public async Task<IActionResult> UpdateMealLog(Guid mealLogId, [FromBody] MealLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateMealLogAsync(userId, mealLogId, request));
        }

        [HttpDelete("meal-logs/{mealLogId:guid}")]
        public async Task<IActionResult> DeleteMealLog(Guid mealLogId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.DeleteMealLogAsync(userId, mealLogId);
            return Ok();
        }

        [HttpGet("daily")]
        public async Task<IActionResult> GetDaily([FromQuery] DateOnly date)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetDailySummaryAsync(userId, date));
        }

        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboard([FromQuery] string range = "day", [FromQuery] DateOnly? startDate = null, [FromQuery] DateOnly? endDate = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetDashboardAsync(userId, range, startDate, endDate));
        }

        [HttpPost("weight-logs")]
        public async Task<IActionResult> CreateWeightLog([FromBody] WeightLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateWeightLogAsync(userId, request));
        }

        [HttpPut("weight-logs/{weightLogId:guid}")]
        public async Task<IActionResult> UpdateWeightLog(Guid weightLogId, [FromBody] WeightLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateWeightLogAsync(userId, weightLogId, request));
        }

        [HttpDelete("weight-logs/{weightLogId:guid}")]
        public async Task<IActionResult> DeleteWeightLog(Guid weightLogId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.DeleteWeightLogAsync(userId, weightLogId);
            return Ok();
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
