using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin")]
    public class MealPlanController : ControllerBase
    {
        private readonly IMealPlanService _service;

        public MealPlanController(IMealPlanService service)
        {
            _service = service;
        }

        // Lấy danh sách meal plan, có thể lọc theo trạng thái hoạt động.
        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] bool? isActive = null)
        {
            return Ok(await _service.GetAllAsync(isActive));
        }

        // Lấy chi tiết một meal plan theo Id.
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

        // Tạo mới meal plan mẫu.
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] MealPlanUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try
            {
                return Ok(await _service.CreateAsync(request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        // Cập nhật meal plan theo Id.
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] MealPlanUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try
            {
                return Ok(await _service.UpdateAsync(id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        // Xóa meal plan theo Id.
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            try
            {
                await _service.DeleteAsync(id);
                return Ok(new { Message = "Deleted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        // Cập nhật trạng thái hoạt động của meal plan.
        [HttpPatch("{id:guid}/status")]
        public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] MealPlanStatusRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try
            {
                return Ok(await _service.UpdateStatusAsync(id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        // Phân phối meal plan cho nhóm đối tượng mục tiêu.
        [HttpPost("{id:guid}/distribute")]
        public async Task<IActionResult> Distribute(Guid id, [FromQuery] string targetAudience, [FromQuery] string? notes = null)
        {
            try
            {
                return Ok(await _service.DistributeAsync(id, targetAudience, notes));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }
    }
}
