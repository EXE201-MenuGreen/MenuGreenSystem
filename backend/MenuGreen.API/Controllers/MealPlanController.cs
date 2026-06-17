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
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class MealPlanController : ControllerBase
    {
        private readonly IMealPlanService _service;

        public MealPlanController(IMealPlanService service)
        {
            _service = service;
        }

        /// <summary>
        /// Lấy danh sách meal plan của user hiện tại, có thể lọc theo trạng thái hoạt động.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] bool? isActive = null)
        {
            return Ok(await _service.GetAllAsync(isActive));
        }

        /// <summary>
        /// Xem chi tiết một meal plan theo Id.
        /// </summary>
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            try
            {
                return Ok(await _service.GetByIdAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Tạo meal plan mới cho user hiện tại.
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] MealPlanUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.CreateAsync(request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Tạo meal plan rỗng (không cần items) - user tạo plan trước, thêm items sau.
        /// </summary>
        [HttpPost("empty")]
        public async Task<IActionResult> CreateEmpty([FromBody] CreateEmptyPlanRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                var upsertRequest = new MealPlanUpsertRequest
                {
                    Title = request.Title,
                    PlanType = request.PlanType,
                    StartDate = request.StartDate,
                    EndDate = request.EndDate,
                    TargetCalories = request.TargetCalories,
                    IsActive = request.IsActive,
                    Items = new List<MealPlanItemUpsertRequest>()
                };
                return Ok(await _service.CreateAsync(upsertRequest, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Cập nhật thông tin meal plan hiện tại.
        /// </summary>
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] MealPlanUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateAsync(id, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Xóa meal plan theo Id.
        /// </summary>
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.DeleteAsync(id, userId);
                return Ok(new { Message = "Deleted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Cập nhật trạng thái hoạt động của meal plan.
        /// </summary>
        [HttpPatch("{id:guid}/status")]
        public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] MealPlanStatusRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateStatusAsync(id, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Phân phối meal plan cho nhóm đối tượng mục tiêu.
        /// </summary>
        [HttpPost("{id:guid}/distribute")]
        public async Task<IActionResult> Distribute(Guid id, [FromQuery] string targetAudience, [FromQuery] string? notes = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.DistributeAsync(id, targetAudience, notes, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Thêm một món hoặc một bữa mới vào meal plan.
        /// </summary>
        [HttpPost("{planId:guid}/items")]
        public async Task<IActionResult> AddItem(Guid planId, [FromBody] MealPlanItemUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.AddItemAsync(planId, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Cập nhật một item đã có trong meal plan.
        /// </summary>
        [HttpPut("{planId:guid}/items/{itemId:guid}")]
        public async Task<IActionResult> UpdateItem(Guid planId, Guid itemId, [FromBody] MealPlanItemUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateItemAsync(planId, itemId, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Xóa một item khỏi meal plan.
        /// </summary>
        [HttpDelete("{planId:guid}/items/{itemId:guid}")]
        public async Task<IActionResult> DeleteItem(Guid planId, Guid itemId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.DeleteItemAsync(planId, itemId, userId);
                return Ok(new { Message = "Deleted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Đánh dấu trạng thái của item trong meal plan.
        /// </summary>
        [HttpPatch("{planId:guid}/items/{itemId:guid}/status")]
        public async Task<IActionResult> UpdateItemStatus(Guid planId, Guid itemId, [FromBody] MealPlanStatusRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateItemStatusAsync(planId, itemId, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Chuyển item trong meal plan thành meal log thực tế.
        /// </summary>
        [HttpPost("{planId:guid}/items/{itemId:guid}/convert-to-log")]
        public async Task<IActionResult> ConvertToLog(Guid planId, Guid itemId, [FromBody] MealPlanConvertToLogRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.ConvertItemToLogAsync(planId, itemId, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Chốt meal plan của ngày hiện tại để phục vụ dashboard và báo cáo.
        /// </summary>
        [HttpPost("{planId:guid}/commit")]
        public async Task<IActionResult> Commit(Guid planId, [FromBody] MealPlanCommitRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.CommitAsync(planId, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Nhân bản meal plan sang khung ngày mới.
        /// </summary>
        [HttpPost("{planId:guid}/duplicate")]
        public async Task<IActionResult> Duplicate(Guid planId, [FromBody] MealPlanDuplicateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.DuplicateAsync(planId, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy dashboard theo ngày: kế hoạch, meal log thực tế và tỷ lệ hoàn thành.
        /// </summary>
        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboard([FromQuery] DateOnly date)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetDashboardAsync(date, userId));
        }

        /// <summary>
        /// So sánh kế hoạch và thực tế theo khoảng ngày.
        /// </summary>
        [HttpGet("compare")]
        public async Task<IActionResult> GetCompare([FromQuery] DateOnly from, [FromQuery] DateOnly to)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetCompareAsync(from, to, userId));
        }

        /// <summary>
        /// Thống kê mức độ bám plan theo chuỗi ngày.
        /// </summary>
        [HttpGet("streaks")]
        public async Task<IActionResult> GetStreaks()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetStreaksAsync(userId));
        }

        /// <summary>
        /// Tự động sinh thực đơn tuần tiết kiệm dựa trên yêu cầu ngân sách mới nhất của user.
        /// </summary>
        [HttpPost("generate-by-budget")]
        public async Task<IActionResult> GenerateByBudget()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GenerateByBudgetAsync(userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy thông tin so sánh chi phí kế hoạch thực đơn hiện tại với ngân sách của user.
        /// </summary>
        [HttpGet("{id:guid}/budget-status")]
        public async Task<IActionResult> GetBudgetStatus(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetBudgetStatusAsync(id, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Đề xuất các món ăn/công thức thay thế có giá rẻ hơn món ăn được chọn trong kế hoạch.
        /// </summary>
        [HttpGet("{planId:guid}/alternatives/{itemId:guid}")]
        public async Task<IActionResult> GetAlternatives(Guid planId, Guid itemId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetAlternativesAsync(planId, itemId, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// So sánh chi phí ăn uống thực tế (meal log) với chi phí kế hoạch và ngân sách đã thiết lập.
        /// </summary>
        [HttpGet("compare-expenses")]
        public async Task<IActionResult> CompareExpenses([FromQuery] DateOnly from, [FromQuery] DateOnly to)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CompareExpensesAsync(from, to, userId));
        }

        /// <summary>
        /// Phân tích tỷ trọng chi tiêu theo danh mục thực phẩm và gợi ý cách tiết kiệm tiền.
        /// </summary>
        [HttpGet("expense-breakdown")]
        public async Task<IActionResult> GetExpenseBreakdown()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetExpenseBreakdownAsync(userId));
        }

        /// <summary>
        /// Tính toán điểm bám sát ngân sách ăn uống trong chuỗi ngày gần đây của user.
        /// </summary>
        [HttpGet("adherence-scores")]
        public async Task<IActionResult> GetAdherenceScores()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetAdherenceScoresAsync(userId));
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
