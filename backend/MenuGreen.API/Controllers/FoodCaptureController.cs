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
        /// Tạo template log nhanh từ một món hoặc meal log đã có.
        /// Endpoint này không tạo storage mới, chỉ chuẩn hóa dữ liệu để user dùng lại.
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

            return BadRequest(new { Message = "FoodId hoặc MealLogId là bắt buộc." });
        }

        /// <summary>
        /// Gợi ý template từ meal plan hiện có nếu user muốn lấy preset thay vì tìm món.
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
                Note = "Dùng lại meal plan hiện có, không tạo template storage mới."
            });
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
