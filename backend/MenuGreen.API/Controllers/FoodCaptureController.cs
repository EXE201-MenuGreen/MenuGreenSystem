using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Real-world food data capture workflow.
    /// Reuses existing food search and meal log APIs instead of duplicating them.
    /// </summary>
    [ApiController]
    [Route("api/Nutrition/food-capture")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class FoodCaptureController : ControllerBase
    {
        private readonly IFoodService _foodService;
        private readonly INutritionTrackingService _nutritionTrackingService;
        private readonly IMealPlanService _mealPlanService;

        public FoodCaptureController(
            IFoodService foodService,
            INutritionTrackingService nutritionTrackingService,
            IMealPlanService mealPlanService)
        {
            _foodService = foodService;
            _nutritionTrackingService = nutritionTrackingService;
            _mealPlanService = mealPlanService;
        }

        /// <summary>
        /// Create quick log template from an existing food or meal log.
        /// This endpoint does not create new storage, only normalizes data for user reuse.
        /// </summary>
        [HttpPost("quick-template")]
        public async Task<IActionResult> QuickTemplate([FromBody] FoodCaptureQuickTemplateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            if (request.FoodId.HasValue)
            {
                var food = await _foodService.GetByIdAsync(request.FoodId.Value, userId, request.AllergyMode);
                return Ok(new
                {
                    TemplateType = "food",
                    Source = "FoodController.GetById",
                    Food = food,
                    SuggestedMealType = request.MealType,
                    SuggestedQuantityG = request.QuantityG,
                    Notes = request.Notes
                });
            }

            if (request.MealLogId.HasValue)
            {
                var log = await _nutritionTrackingService.GetMealLogByIdAsync(userId, request.MealLogId.Value);
                return Ok(new
                {
                    TemplateType = "meal-log",
                    Source = "NutritionTrackingController.GetMealLogById",
                    MealLog = log,
                    SuggestedMealType = request.MealType,
                    SuggestedQuantityG = request.QuantityG,
                    Notes = request.Notes
                });
            }

            return BadRequest(new { Message = "FoodId or MealLogId is required." });
        }

        /// <summary>
        /// Suggest template from existing meal plan if user wants preset instead of searching.
        /// </summary>
        [HttpGet("template-from-plan")]
        public async Task<IActionResult> TemplateFromPlan([FromQuery] DateOnly date)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var plan = await _mealPlanService.GetByDateAsync(userId, date);
            if (plan == null) return NotFound(new { Message = "Meal plan not found." });

            return Ok(new
            {
                TemplateType = "meal-plan",
                Source = "UserMealPlanController.GetByDate",
                MealPlan = plan,
                Note = "Reuses existing meal plan, no new template storage created."
            });
        }

        /// <summary>
        /// Manually input estimated macros with notes when food is not found.
        /// </summary>
        [HttpPost("fallback-estimate")]
        public async Task<IActionResult> FallbackEstimate([FromBody] MealLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _nutritionTrackingService.CreateMealLogAsync(userId, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Save a standard meal log as quick-add for future use.
        /// </summary>
        [HttpPost("save-as-quick-add")]
        public async Task<IActionResult> SaveAsQuickAdd([FromBody] MealLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _nutritionTrackingService.CreateMealLogAsync(userId, request);
                return Ok(new
                {
                    Message = "Saved as quick add successfully.",
                    MealLog = result
                });
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

    public class FoodCaptureQuickTemplateRequest
    {
        public Guid? FoodId { get; set; }
        public Guid? MealLogId { get; set; }
        public string MealType { get; set; } = string.Empty;
        public decimal QuantityG { get; set; } = 100;
        public string? Notes { get; set; }
        public string? AllergyMode { get; set; }
    }
}
