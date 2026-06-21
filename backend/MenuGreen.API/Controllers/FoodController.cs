using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.BusinessLogicLayer.Services;
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
        private readonly IAllergenMatchingService _allergenMatching;

        public FoodController(IFoodService foodService, IAllergenMatchingService allergenMatching)
        {
            _foodService = foodService;
            _allergenMatching = allergenMatching;
        }

        private Guid? TryGetUserId()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userId, out var id) ? id : null;
        }

        /// <summary>
        /// Tìm kiếm món ăn theo keyword và các bộ lọc dinh dưỡng/giá/thời gian.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Search(
            [FromQuery] string? keyword,
            [FromQuery] decimal? minCalories,
            [FromQuery] decimal? maxCalories,
            [FromQuery] string? proteinLevel,
            [FromQuery] int? maxPriceVnd,
            [FromQuery] int? maxPrepTimeMin,
            [FromQuery] string? category,
            [FromQuery] string? allergyMode)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var userId = TryGetUserId();
                var result = await _foodService.SearchAsync(
                    keyword, minCalories, maxCalories, proteinLevel, maxPriceVnd, maxPrepTimeMin, category,
                    userId, allergyMode);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy chi tiết món ăn theo Id.
        /// </summary>
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id, [FromQuery] string? allergyMode)
        {
            try
            {
                return Ok(await _foodService.GetByIdAsync(id, TryGetUserId(), allergyMode));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy danh sách công thức liên quan đến một món ăn.
        /// </summary>
        [HttpGet("{id:guid}/recipes")]
        public async Task<IActionResult> GetRecipes(Guid id)
        {
            try
            {
                return Ok(await _foodService.GetRecipesAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy danh sách món ăn yêu thích của user hiện tại.
        /// </summary>
        [HttpGet("favorites")]
        public async Task<IActionResult> GetFavorites()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var id)) return Unauthorized();
            try
            {
                return Ok(await _foodService.GetFavoritesAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Thêm một món ăn vào danh sách yêu thích của user.
        /// </summary>
        [HttpPost("{id:guid}/favorite")]
        public async Task<IActionResult> Favorite(Guid id)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var uid)) return Unauthorized();
            try
            {
                await _foodService.FavoriteAsync(uid, id);
                return Ok(new { Message = "Added to favorites successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Xóa một món ăn khỏi danh sách yêu thích của user.
        /// </summary>
        [HttpDelete("{id:guid}/favorite")]
        public async Task<IActionResult> Unfavorite(Guid id)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var uid)) return Unauthorized();
            try
            {
                await _foodService.UnfavoriteAsync(uid, id);
                return Ok(new { Message = "Removed from favorites successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Tạo mới món ăn.
        /// </summary>
        [HttpPost]
        [Authorize(Roles = "Admin")]
        [Authorize(Policy = "AdminOnly")]
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

        /// <summary>
        /// Cập nhật thông tin món ăn theo Id.
        /// </summary>
        [HttpPut("{id:guid}")]
        [Authorize(Roles = "Admin")]
        [Authorize(Policy = "AdminOnly")]
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

        /// <summary>
        /// Xóa món ăn theo Id.
        /// </summary>
        [HttpDelete("{id:guid}")]
        [Authorize(Roles = "Admin")]
        [Authorize(Policy = "AdminOnly")]
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

        /// <summary>
        /// Cập nhật danh sách chất gây dị ứng của món ăn (Admin only).
        /// </summary>
        [HttpPut("{id:guid}/allergies")]
        [Authorize(Roles = "Admin")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> SetAllergies(Guid id, [FromBody] FoodAllergenTagsUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                // Verify food exists
                var food = await _foodService.GetByIdAsync(id);
                if (food == null) return NotFound(new { Message = "Food not found." });

                await _allergenMatching.SetFoodAllergenKeysAsync(id, request.AllergenKeys);

                var keys = await _allergenMatching.GetFoodAllergenKeysListAsync(id);
                var labels = AllergenCatalog.ToDisplayNamesVi(keys).ToList();

                var response = new FoodAllergenTagsResponse
                {
                    FoodId = id,
                    AllergenKeys = keys.ToList(),
                    AllergenLabelsVi = labels,
                    AvailableAllergenKeys = AllergenCatalog.AllKeys.ToList()
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }
    }
}
