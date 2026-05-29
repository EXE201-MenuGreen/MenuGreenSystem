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
    public class SubscriptionPlanController : ControllerBase
    {
        private readonly ISubscriptionPlanService _service;

        public SubscriptionPlanController(ISubscriptionPlanService service)
        {
            _service = service;
        }

        // Lấy danh sách gói thành viên, có thể lọc theo trạng thái hoạt động.
        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] bool? isActive = null)
        {
            return Ok(await _service.GetAllAsync(isActive));
        }

        // Lấy chi tiết một gói thành viên theo Id.
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

        // Tạo mới một gói thành viên.
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] SubscriptionPlanUpsertRequest request)
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

        // Cập nhật thông tin gói thành viên.
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] SubscriptionPlanUpsertRequest request)
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

        // Xóa một gói thành viên theo Id.
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

        // Kích hoạt hoặc vô hiệu hóa gói thành viên.
        [HttpPatch("{id:guid}/status")]
        public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] SubscriptionPlanStatusRequest request)
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
    }
}
