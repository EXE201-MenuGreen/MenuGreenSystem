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
    [Authorize(Policy = "UserOnly")]
    public class FoodController : ControllerBase
    {
        private readonly IFoodService _foodService;

        public FoodController(IFoodService foodService)
        {
            _foodService = foodService;
        }

        // Tìm kiếm món ăn theo keyword, calories, giá, thời gian và category.
        [HttpGet]
        public async Task<IActionResult> Search(
            [FromQuery] string? keyword,
            [FromQuery] decimal? minCalories,
            [FromQuery] decimal? maxCalories,
            [FromQuery] string? proteinLevel,
            [FromQuery] int? maxPriceVnd,
            [FromQuery] int? maxPrepTimeMin,
            [FromQuery] string? category)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var result = await _foodService.SearchAsync(keyword, minCalories, maxCalories, proteinLevel, maxPriceVnd, maxPrepTimeMin, category);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        // Lấy chi tiết món ăn theo Id.
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            try
            {
                return Ok(await _foodService.GetByIdAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        // Tạo mới món ăn.
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] FoodUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                return Ok(await _foodService.CreateAsync(request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        // Cập nhật thông tin món ăn theo Id.
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] FoodUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                return Ok(await _foodService.UpdateAsync(id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        // Xóa món ăn theo Id.
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            try
            {
                await _foodService.DeleteAsync(id);
                return Ok(new { Message = "Deleted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }
    }
}
