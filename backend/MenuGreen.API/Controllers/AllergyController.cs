using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Controller for allergy profile management, allergy risk assessment, and safe food recommendations.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class AllergyController : ControllerBase
    {
        private readonly IAllergyService _service;
        private readonly IAllergenMatchingService _allergenMatching;
        private readonly IFoodService _foodService;

        public AllergyController(IAllergyService service, IAllergenMatchingService allergenMatching, IFoodService foodService)
        {
            _service = service;
            _allergenMatching = allergenMatching;
            _foodService = foodService;
        }

        private bool TryGetUserId(out Guid userId)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }

        /// <summary>
        /// Get all allergies of the currently logged-in user.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetAllAsync(userId));
        }

        /// <summary>
        /// Add a new allergy entry for the user.
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] AllergyUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateAsync(userId, request));
        }

        /// <summary>
        /// Update an existing allergy entry.
        /// </summary>
        [HttpPut("{allergyId:guid}")]
        public async Task<IActionResult> Update(Guid allergyId, [FromBody] AllergyUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateAsync(userId, allergyId, request));
        }

        /// <summary>
        /// Delete an allergy entry for the user.
        /// </summary>
        [HttpDelete("{allergyId:guid}")]
        public async Task<IActionResult> Delete(Guid allergyId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.DeleteAsync(userId, allergyId);
            return Ok();
        }

        /// <summary>
        /// Bulk update user allergen profile (e.g., after Onboarding completion or quick edit).
        /// </summary>
        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] AllergyProfileUpdateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateProfileAsync(userId, request.Allergens));
        }

        /// <summary>
        /// Get catalog of all standardized allergens supported by MenuGreen.
        /// </summary>
        [HttpGet("catalog")]
        public async Task<IActionResult> GetCatalog()
        {
            return Ok(await _service.GetCatalogAsync());
        }

        /// <summary>
        /// Đánh giá rủi ro dị ứng cho một món ăn cụ thể hoặc danh sách nguyên liệu tự nhập.
        /// </summary>
        [HttpPost("evaluate")]
        public async Task<IActionResult> Evaluate([FromBody] AllergyEvaluateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            Guid? userId = Guid.TryParse(userIdString, out var uid) ? uid : null;

            if (request.FoodId.HasValue)
            {
                return Ok(await _allergenMatching.EvaluateFoodRiskAsync(request.FoodId.Value, userId));
            }
            else if (request.IngredientNamesVi != null)
            {
                return Ok(await _allergenMatching.EvaluateRecipeRiskAsync(null, request.IngredientNamesVi, userId));
            }

            return BadRequest("FoodId hoặc IngredientNamesVi là bắt buộc.");
        }

        /// <summary>
        /// Đánh giá rủi ro dị ứng hàng loạt cho danh sách món ăn.
        /// </summary>
        [HttpPost("evaluate/batch")]
        public async Task<IActionResult> EvaluateBatch([FromBody] AllergyEvaluateBatchRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            Guid? userId = Guid.TryParse(userIdString, out var uid) ? uid : null;

            return Ok(await _allergenMatching.EvaluateFoodRiskBatchAsync(request.FoodIds, userId));
        }

        /// <summary>
        /// Lấy badge rủi ro dị ứng cho một món ăn cụ thể.
        /// </summary>
        [HttpGet("meal/{mealId:guid}/badge")]
        public async Task<IActionResult> GetBadge(Guid mealId)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            Guid? userId = Guid.TryParse(userIdString, out var uid) ? uid : null;

            return Ok(await _allergenMatching.EvaluateFoodRiskAsync(mealId, userId));
        }

        /// <summary>
        /// Gợi ý các món ăn an toàn phù hợp với hồ sơ dị ứng của người dùng.
        /// </summary>
        [HttpGet("recommendations")]
        public async Task<IActionResult> GetRecommendations()
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userIdString, out var userId)) return Unauthorized();

            // Lấy danh sách thức ăn an toàn (allergyMode = "hide")
            var result = await _foodService.SearchAsync(
                keyword: null, minCalories: null, maxCalories: null, proteinLevel: null,
                maxPriceVnd: null, maxPrepTimeMin: null, category: null,
                userId: userId, allergyMode: "hide", region: null, localOnly: null,
                mealContext: null, sort: null);

            return Ok(result.Items);
        }
    }
}
