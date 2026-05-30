using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/admin/ingredients")]
    [Authorize(Roles = "Admin")]
    [Authorize(Policy = "AdminOnly")]
    public class AdminIngredientController : ControllerBase
    {
        private readonly IAdminIngredientService _service;

        public AdminIngredientController(IAdminIngredientService service)
        {
            _service = service;
        }

        // Tạo mới nguyên liệu ở cấp quản trị tối cao.
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] IngredientUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try { return Ok(await _service.CreateAsync(request)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        // Lấy chi tiết nguyên liệu ở cấp quản trị tối cao.
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            try { return Ok(await _service.GetByIdAsync(id)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        // Cập nhật nguyên liệu ở cấp quản trị tối cao.
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] IngredientUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try { return Ok(await _service.UpdateAsync(id, request)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        // Xóa nguyên liệu ở cấp quản trị tối cao.
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            try { await _service.DeleteAsync(id); return Ok(); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }
    }
}
