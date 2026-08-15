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
        /// Search for food by keyword and nutrition/price/cooking time filters.
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
            [FromQuery] string? allergyMode,
            [FromQuery] string? region,
            [FromQuery] bool? localOnly,
            [FromQuery] string? mealContext,
            [FromQuery] string? sort,
            [FromQuery] int? page,
            [FromQuery] int? pageSize)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var userId = TryGetUserId();
                var result = await _foodService.SearchAsync(
                    keyword, minCalories, maxCalories, proteinLevel, maxPriceVnd, maxPrepTimeMin, category,
                    userId, allergyMode, region, localOnly, mealContext, sort, page, pageSize);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Get food details by Id.
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
        /// Get list of recipes related to a food item.
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
        /// Get current user favorite foods.
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
        /// Add a food to current user favorites.
        /// </summary>
        [HttpPost("{id:guid}/favorite")]
        public async Task<IActionResult> Favorite(Guid id)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var uid)) return Unauthorized();
            try
            {
                var favorite = await _foodService.FavoriteAsync(uid, id);
                return Ok(new
                {
                    FoodId = favorite.FoodId,
                    IsFavorite = true,
                    Item = favorite,
                    Message = "Added to favorites successfully."
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Remove a food from current user favorites.
        /// </summary>
        [HttpDelete("{id:guid}/favorite")]
        public async Task<IActionResult> Unfavorite(Guid id)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var uid)) return Unauthorized();
            try
            {
                await _foodService.UnfavoriteAsync(uid, id);
                return Ok(new
                {
                    FoodId = id,
                    IsFavorite = false,
                    Message = "Removed from favorites successfully."
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Create new food.
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
        /// Update food information by Id.
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
        /// Delete food by Id.
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
        /// Update food allergen list (Admin only).
        /// </summary>
        [HttpPut("{id:guid}/allergies")]
        [Authorize(Roles = "Admin")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> SetAllergies(Guid id, [FromBody] FoodAllergenTagsUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
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
