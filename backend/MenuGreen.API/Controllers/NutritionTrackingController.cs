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
    /// Controller quản lý Nutrition Tracking - Theo dõi dinh dưỡng và cân nặng.
    /// </summary>
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

        /// <summary>
        /// Lấy danh sách tất cả meal logs của user (có phân trang).
        /// </summary>
        [HttpGet("meal-logs")]
        public async Task<IActionResult> GetMealLogs([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetMealLogsAsync(userId, page, pageSize));
        }

        /// <summary>
        /// Xem chi tiết một meal log cụ thể theo ID.
        /// </summary>
        [HttpGet("meal-logs/{mealLogId:guid}")]
        public async Task<IActionResult> GetMealLogById(Guid mealLogId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetMealLogByIdAsync(userId, mealLogId));
        }

        /// <summary>
        /// Tạo meal log mới (ghi nhận bữa ăn).
        /// </summary>
        [HttpPost("meal-logs")]
        public async Task<IActionResult> CreateMealLog([FromBody] MealLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateMealLogAsync(userId, request));
        }

        /// <summary>
        /// Cập nhật thông tin meal log.
        /// </summary>
        [HttpPut("meal-logs/{mealLogId:guid}")]
        public async Task<IActionResult> UpdateMealLog(Guid mealLogId, [FromBody] MealLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateMealLogAsync(userId, mealLogId, request));
        }

        /// <summary>
        /// Xóa meal log.
        /// </summary>
        [HttpDelete("meal-logs/{mealLogId:guid}")]
        public async Task<IActionResult> DeleteMealLog(Guid mealLogId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.DeleteMealLogAsync(userId, mealLogId);
            return Ok();
        }

        /// <summary>
        /// Lấy tóm tắt meal logs theo ngày cụ thể.
        /// </summary>
        [HttpGet("meal-logs/daily")]
        public async Task<IActionResult> GetMealLogsDaily([FromQuery] DateOnly date)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetDailySummaryAsync(userId, date));
        }

        /// <summary>
        /// Lấy danh sách meal logs trong khoảng thời gian.
        /// </summary>
        [HttpGet("meal-logs/range")]
        public async Task<IActionResult> GetMealLogsByRange([FromQuery] DateOnly startDate, [FromQuery] DateOnly endDate)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetMealLogsByRangeAsync(userId, startDate, endDate));
        }

        /// <summary>
        /// Tổng hợp dinh dưỡng theo khoảng thời gian (day/week/month).
        /// </summary>
        [HttpGet("summary")]
        public async Task<IActionResult> GetSummary([FromQuery] string period = "day", [FromQuery] DateOnly? date = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetNutritionSummaryAsync(userId, period, date));
        }

        /// <summary>
        /// Phân tích xu hướng dinh dưỡng theo thời gian (dùng cho biểu đồ).
        /// </summary>
        [HttpGet("trends")]
        public async Task<IActionResult> GetTrends([FromQuery] DateOnly startDate, [FromQuery] DateOnly endDate)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetNutritionTrendsAsync(userId, startDate, endDate));
        }

        /// <summary>
        /// Lấy tóm tắt dinh dưỡng theo ngày.
        /// </summary>
        [HttpGet("daily")]
        public async Task<IActionResult> GetDaily([FromQuery] DateOnly date)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetDailySummaryAsync(userId, date));
        }

        /// <summary>
        /// Lấy dashboard tổng hợp (meal logs và weight logs).
        /// </summary>
        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboard([FromQuery] string range = "day", [FromQuery] DateOnly? startDate = null, [FromQuery] DateOnly? endDate = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetDashboardAsync(userId, range, startDate, endDate));
        }

        /// <summary>
        /// Lấy danh sách tất cả weight logs của user (có phân trang).
        /// </summary>
        [HttpGet("weight-logs")]
        public async Task<IActionResult> GetWeightLogs([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetWeightLogsAsync(userId, page, pageSize));
        }

        /// <summary>
        /// Xem chi tiết một weight log cụ thể theo ID.
        /// </summary>
        [HttpGet("weight-logs/{weightLogId:guid}")]
        public async Task<IActionResult> GetWeightLogById(Guid weightLogId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetWeightLogByIdAsync(userId, weightLogId));
        }

        /// <summary>
        /// Phân tích xu hướng thay đổi cân nặng theo thời gian (dùng cho biểu đồ).
        /// </summary>
        [HttpGet("weight-logs/trend")]
        public async Task<IActionResult> GetWeightTrend([FromQuery] DateOnly startDate, [FromQuery] DateOnly endDate)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetWeightTrendAsync(userId, startDate, endDate));
        }

        /// <summary>
        /// Tạo weight log mới (ghi nhận cân nặng).
        /// </summary>
        [HttpPost("weight-logs")]
        public async Task<IActionResult> CreateWeightLog([FromBody] WeightLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateWeightLogAsync(userId, request));
        }

        /// <summary>
        /// Cập nhật thông tin weight log.
        /// </summary>
        [HttpPut("weight-logs/{weightLogId:guid}")]
        public async Task<IActionResult> UpdateWeightLog(Guid weightLogId, [FromBody] WeightLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateWeightLogAsync(userId, weightLogId, request));
        }

        /// <summary>
        /// Xóa weight log.
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
