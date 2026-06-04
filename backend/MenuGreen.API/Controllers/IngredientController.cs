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
    [Authorize(Policy = "UserOnly")]
    public class IngredientController : ControllerBase
    {
        private readonly IIngredientService _ingredientService;

        public IngredientController(IIngredientService ingredientService)
        {
            _ingredientService = ingredientService;
        }

        private Guid? TryGetUserId()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userId, out var id) ? id : null;
        }

        /// <summary>
        /// Tìm kiếm nguyên liệu theo keyword, category và trạng thái.
        /// </summary>
        [HttpGet("search")]
        public async Task<IActionResult> Search(
            [FromQuery] string? keyword,
            [FromQuery] string? category,
            [FromQuery] bool? isActive,
            [FromQuery] string? allergyMode)
        {
            try
            {
                return Ok(await _ingredientService.SearchAsync(
                    keyword, category, isActive, TryGetUserId(), allergyMode));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy danh sách công thức đang sử dụng nguyên liệu này.
        /// </summary>
        [HttpGet("{id:guid}/recipes")]
        public async Task<IActionResult> GetRecipes(Guid id)
        {
            try
            {
                return Ok(await _ingredientService.GetRecipesAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy danh mục nguyên liệu để hiển thị trong catalog.
        /// </summary>
        [HttpGet("catalog")]
        public async Task<IActionResult> GetCatalog()
        {
            try
            {
                return Ok(await _ingredientService.GetCatalogAsync());
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy chi tiết nguyên liệu theo Id.
        /// </summary>
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id, [FromQuery] string? allergyMode)
        {
            try
            {
                return Ok(await _ingredientService.GetByIdAsync(id, TryGetUserId(), allergyMode));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Tạo mới nguyên liệu.
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] IngredientUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                return Ok(await _ingredientService.CreateAsync(request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Cập nhật thông tin nguyên liệu theo Id.
        /// </summary>
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] IngredientUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                return Ok(await _ingredientService.UpdateAsync(id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Xóa nguyên liệu theo Id.
        /// </summary>
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            try
            {
                await _ingredientService.DeleteAsync(id);
                return Ok(new { Message = "Deleted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }
    }
}
