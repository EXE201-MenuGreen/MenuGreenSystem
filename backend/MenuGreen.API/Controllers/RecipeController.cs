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
    public class RecipeController : ControllerBase
    {
        private readonly IRecipeService _recipeService;

        public RecipeController(IRecipeService recipeService)
        {
            _recipeService = recipeService;
        }

        /// <summary>
        /// Tìm kiếm công thức theo keyword, mealType, difficulty và trạng thái.
        /// </summary>
        [HttpGet("search")]
        public async Task<IActionResult> Search(
            [FromQuery] string? keyword,
            [FromQuery] string? mealType,
            [FromQuery] string? difficulty,
            [FromQuery] bool? isActive)
        {
            try
            {
                return Ok(await _recipeService.SearchAsync(keyword, mealType, difficulty, isActive));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy chi tiết công thức theo Id.
        /// </summary>
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            try
            {
                return Ok(await _recipeService.GetByIdAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy danh sách nguyên liệu của công thức.
        /// </summary>
        [HttpGet("{id:guid}/ingredients")]
        public async Task<IActionResult> GetIngredients(Guid id)
        {
            try
            {
                return Ok(await _recipeService.GetIngredientsAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy thông tin dinh dưỡng của công thức.
        /// </summary>
        [HttpGet("{id:guid}/nutrition")]
        public async Task<IActionResult> GetNutrition(Guid id)
        {
            try
            {
                return Ok(await _recipeService.GetNutritionAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy danh sách công thức liên quan.
        /// </summary>
        [HttpGet("{id:guid}/related")]
        public async Task<IActionResult> GetRelated(Guid id)
        {
            try
            {
                return Ok(await _recipeService.GetRelatedAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Tạo mới công thức chế biến.
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] RecipeUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                return Ok(await _recipeService.CreateAsync(request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Cập nhật công thức theo Id.
        /// </summary>
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] RecipeUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                return Ok(await _recipeService.UpdateAsync(id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Xóa công thức theo Id.
        /// </summary>
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            try
            {
                await _recipeService.DeleteAsync(id);
                return Ok(new { Message = "Deleted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }
    }
}
