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
    /// Controller for Nutrition Tracking - nutritional and weight monitoring.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class NutritionTrackingController : ControllerBase
    {
        private readonly INutritionTrackingService _service;
        private readonly IMealPlanService _mealPlanService;

        public NutritionTrackingController(
            INutritionTrackingService service,
            IMealPlanService mealPlanService)
        {
            _service = service;
            _mealPlanService = mealPlanService;
        }

        /// <summary>
        /// Get paginated list of user meal logs.
        /// </summary>
        [HttpGet("meal-logs")]
        public async Task<IActionResult> GetMealLogs([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetMealLogsAsync(userId, page, pageSize));
        }

        /// <summary>
        /// Get details of a specific meal log by ID.
        /// </summary>
        [HttpGet("meal-logs/{mealLogId:guid}")]
        public async Task<IActionResult> GetMealLogById(Guid mealLogId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetMealLogByIdAsync(userId, mealLogId));
        }

        /// <summary>
        /// Create a new meal log (record a meal).
        /// </summary>
        [HttpPost("meal-logs")]
        public async Task<IActionResult> CreateMealLog([FromBody] MealLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var mealLog = await _service.CreateMealLogAsync(userId, request);
            if (request.AddToMealPlan && !mealLog.MealPlanItemId.HasValue)
            {
                await _mealPlanService.LinkMealLogToDailyPlanAsync(userId, mealLog.Id);
            }
            return Ok(mealLog);
        }

        /// <summary>
        /// Update meal log information.
        /// </summary>
        [HttpPut("meal-logs/{mealLogId:guid}")]
        public async Task<IActionResult> UpdateMealLog(Guid mealLogId, [FromBody] MealLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateMealLogAsync(userId, mealLogId, request));
        }

        /// <summary>
        /// Delete a meal log.
        /// </summary>
        [HttpDelete("meal-logs/{mealLogId:guid}")]
        public async Task<IActionResult> DeleteMealLog(Guid mealLogId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.DeleteMealLogAsync(userId, mealLogId);
            return Ok();
        }

        /// <summary>
        /// Get meal logs within a date range.
        /// </summary>
        [HttpGet("meal-logs/range")]
        public async Task<IActionResult> GetMealLogsByRange([FromQuery] DateOnly startDate, [FromQuery] DateOnly endDate)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetMealLogsByRangeAsync(userId, startDate, endDate));
        }

        /// <summary>
        /// Aggregate nutrition data for a time period (day/week/month).
        /// </summary>
        [HttpGet("summary")]
        public async Task<IActionResult> GetSummary([FromQuery] string period = "day", [FromQuery] DateOnly? date = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetNutritionSummaryAsync(userId, period, date));
        }

        /// <summary>
        /// Analyze nutrition trends over time (for charts).
        /// </summary>
        [HttpGet("trends")]
        public async Task<IActionResult> GetTrends([FromQuery] DateOnly startDate, [FromQuery] DateOnly endDate)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetNutritionTrendsAsync(userId, startDate, endDate));
        }

        /// <summary>
        /// Get daily nutrition summary.
        /// </summary>
        [HttpGet("daily")]
        public async Task<IActionResult> GetDaily([FromQuery] DateOnly date)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetDailySummaryAsync(userId, date));
        }

        /// <summary>
        /// Get combined dashboard (meal logs and weight logs).
        /// </summary>
        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboard([FromQuery] string range = "day", [FromQuery] DateOnly? startDate = null, [FromQuery] DateOnly? endDate = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetDashboardAsync(userId, range, startDate, endDate));
        }

        /// <summary>
        /// Get paginated list of user weight logs.
        /// </summary>
        [HttpGet("weight-logs")]
        public async Task<IActionResult> GetWeightLogs([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetWeightLogsAsync(userId, page, pageSize));
        }

        /// <summary>
        /// Get details of a specific weight log by ID.
        /// </summary>
        [HttpGet("weight-logs/{weightLogId:guid}")]
        public async Task<IActionResult> GetWeightLogById(Guid weightLogId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetWeightLogByIdAsync(userId, weightLogId));
        }

        /// <summary>
        /// Analyze weight change trends over time (for charts).
        /// </summary>
        [HttpGet("weight-logs/trend")]
        public async Task<IActionResult> GetWeightTrend([FromQuery] DateOnly startDate, [FromQuery] DateOnly endDate)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetWeightTrendAsync(userId, startDate, endDate));
        }

        /// <summary>
        /// Create a new weight log (record weight).
        /// </summary>
        [HttpPost("weight-logs")]
        public async Task<IActionResult> CreateWeightLog([FromBody] WeightLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateWeightLogAsync(userId, request));
        }

        /// <summary>
        /// Update weight log information.
        /// </summary>
        [HttpPut("weight-logs/{weightLogId:guid}")]
        public async Task<IActionResult> UpdateWeightLog(Guid weightLogId, [FromBody] WeightLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateWeightLogAsync(userId, weightLogId, request));
        }

        /// <summary>
        /// Delete a weight log.
        /// </summary>
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
