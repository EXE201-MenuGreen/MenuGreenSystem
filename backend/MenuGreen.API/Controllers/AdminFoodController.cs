using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/admin/foods")]
    [Authorize(Roles = "Admin")]
    [Authorize(Policy = "AdminOnly")]
    public class AdminFoodController : ControllerBase
    {
        private readonly IAdminFoodService _service;

        public AdminFoodController(IAdminFoodService service)
        {
            _service = service;
        }

        // Tạo mới món ăn ở cấp quản trị tối cao.
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] FoodUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try { return Ok(await _service.CreateAsync(request)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        // Lấy chi tiết món ăn ở cấp quản trị tối cao.
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            try { return Ok(await _service.GetByIdAsync(id)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        // Cập nhật món ăn ở cấp quản trị tối cao.
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] FoodUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try { return Ok(await _service.UpdateAsync(id, request)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        // Xóa món ăn ở cấp quản trị tối cao.
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            try { await _service.DeleteAsync(id); return Ok(); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }
    }
}
