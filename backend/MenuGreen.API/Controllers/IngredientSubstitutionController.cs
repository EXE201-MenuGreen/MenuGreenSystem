using System;
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
    /// Controller for managing Ingredient Substitution suggestions and application.
    /// </summary>
    [ApiController]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class IngredientSubstitutionController : ControllerBase
    {
        private readonly IIngredientSubstitutionService _service;

        public IngredientSubstitutionController(IIngredientSubstitutionService service)
        {
            _service = service;
        }

        /// <summary>
        /// Search for suitable substitute ingredients for a specific ingredient.
        /// </summary>
        /// <param name="id">Original ingredient ID</param>
        /// <param name="reason">Substitution reason (allergy, not_available, expensive)</param>
        /// <param name="maxPrice">Maximum price ceiling for substitute</param>
        /// <param name="macroMatch">Match similar Calo/Macro content</param>
        [HttpGet("api/Ingredient/{id:guid}/substitutes")]
        public async Task<IActionResult> GetSubstitutes(
            Guid id, [FromQuery] string reason = "not_available", [FromQuery] int? maxPrice = null, [FromQuery] bool macroMatch = false)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                var result = await _service.GetSubstitutesAsync(userId, id, reason, maxPrice, macroMatch);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Suggest batch substitutes from input list for grocery shopping or cart preparation.
        /// </summary>
        [HttpPost("api/Ingredient/substitutes/batch")]
        public async Task<IActionResult> GetBatchSubstitutes([FromBody] BatchSubstitutionRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetBatchSubstitutesAsync(userId, request));
        }

        /// <summary>
        /// Suggest suitable substitutes in the culinary context of a specific recipe with equivalent weight.
        /// </summary>
        [HttpGet("api/Recipe/{recipeId:guid}/substitute-ingredient/{ingredientId:guid}")]
        public async Task<IActionResult> GetRecipeIngredientSubstitutes(Guid recipeId, Guid ingredientId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetRecipeIngredientSubstitutesAsync(userId, recipeId, ingredientId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Find similar and safe recipes to substitute for recipe with allergen risk.
        /// </summary>
        [HttpGet("api/Recipe/{recipeId:guid}/safe-alternatives")]
        public async Task<IActionResult> GetSafeRecipeAlternatives(Guid recipeId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetSafeRecipeAlternativesAsync(userId, recipeId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Apply ingredient substitution in a planned meal/recipe and update calories.
        /// </summary>
        [HttpPost("api/MealPlan/{planId:guid}/items/{itemId:guid}/substitute-ingredient")]
        public async Task<IActionResult> ApplyMealPlanSubstitution(
            Guid planId, Guid itemId, [FromBody] IngredientSubstitutionApplyRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.ApplyMealPlanSubstitutionAsync(userId, planId, itemId, request);
                return Ok(new { Message = "Ingredient substitution in plan applied successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Record ingredient substitution when user is actually cooking to meal log.
        /// </summary>
        [HttpPost("api/NutritionTracking/meal-logs/{mealLogId:guid}/substitute-ingredient")]
        public async Task<IActionResult> ApplyMealLogSubstitution(
            Guid mealLogId, [FromBody] IngredientSubstitutionApplyRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.ApplyMealLogSubstitutionAsync(userId, mealLogId, request);
                return Ok(new { Message = "Actual ingredient substitution recorded successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Get list of user's preferred default substitute pairs.
        /// </summary>
        [HttpGet("api/Ingredient/preferences/substitutes")]
        public async Task<IActionResult> GetPersonalPreferences()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetPersonalPreferencesAsync(userId));
        }

        /// <summary>
        /// Set default configuration to auto-substitute original ingredient with preferred substitute.
        /// </summary>
        [HttpPost("api/Ingredient/preferences/substitutes")]
        public async Task<IActionResult> CreatePersonalPreference([FromBody] UserSubstitutePreferenceUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.CreatePersonalPreferenceAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Delete default auto-substitution configuration.
        /// </summary>
        [HttpDelete("api/Ingredient/preferences/substitutes/{id:guid}")]
        public async Task<IActionResult> DeletePersonalPreference(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.DeletePersonalPreferenceAsync(userId, id);
                return Ok(new { Message = "Configuration deleted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
