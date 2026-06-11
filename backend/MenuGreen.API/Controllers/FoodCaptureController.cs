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
        private readonly IUserMealPlanService _userMealPlanService;

        public FoodCaptureController(
            IFoodService foodService,
            INutritionTrackingService nutritionTrackingService,
            IUserMealPlanService userMealPlanService)
        {
            _foodService = foodService;
            _nutritionTrackingService = nutritionTrackingService;
            _userMealPlanService = userMealPlanService;
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
        /// Nhập tay macro ước tính khi không tìm thấy món hoặc barcode bị lỗi.
        /// Nếu user có truyền FoodId thì vẫn ưu tiên map sang món có sẵn.
        /// </summary>
        [HttpPost("fallback-estimate")]
        public async Task<IActionResult> FallbackEstimate([FromBody] FoodCaptureFallbackEstimateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var estimatedCalories = (request.ProteinG * 4m) + (request.CarbsG * 4m) + (request.FatG * 9m);
            var notes = string.IsNullOrWhiteSpace(request.Notes)
                ? "Fallback estimate captured from manual macro input."
                : request.Notes;

            var logRequest = new MealLogUpsertRequest
            {
                FoodId = request.FoodId,
                MealType = request.MealType,
                QuantityG = request.QuantityG,
                Notes = $"{notes} | EstimatedCalories={estimatedCalories:F2}; ProteinG={request.ProteinG}; CarbsG={request.CarbsG}; FatG={request.FatG}",
                LoggedAt = request.LoggedAt ?? DateTime.UtcNow
            };

            var created = await _nutritionTrackingService.CreateMealLogAsync(userId, logRequest);
            return Ok(new
            {
                Message = "Fallback estimate saved using existing meal log API.",
                EstimatedCalories = estimatedCalories,
                MealLog = created,
                Note = "Không tạo meal-log API mới; dùng lại NutritionTrackingController.CreateMealLogAsync."
            });
        }

        /// <summary>
        /// Lưu một meal log chuẩn thành quick-add để tái sử dụng cho những lần sau.
        /// Không có storage riêng cho quick-add, nên endpoint này trả về bản chuẩn hóa để UI lưu preset nếu cần.
        /// </summary>
        [HttpPost("save-as-quick-add")]
        public async Task<IActionResult> SaveAsQuickAdd([FromBody] FoodCaptureSaveQuickAddRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var logRequest = new MealLogUpsertRequest
            {
                FoodId = request.FoodId,
                RecipeId = request.RecipeId,
                MealType = request.MealType,
                QuantityG = request.QuantityG,
                Notes = request.Notes,
                LoggedAt = request.LoggedAt ?? DateTime.UtcNow,
                MealPlanItemId = request.MealPlanItemId
            };

            var created = await _nutritionTrackingService.CreateMealLogAsync(userId, logRequest);
            var normalized = new
            {
                TemplateType = "quick-add",
                Source = "NutritionTrackingController.CreateMealLogAsync",
                CreatedMealLog = created,
                QuickAdd = new
                {
                    request.FoodId,
                    request.RecipeId,
                    request.MealType,
                    request.QuantityG,
                    request.Notes,
                    request.MealPlanItemId
                },
                Note = "Nếu cần preset lưu lâu dài thì dùng UserMealPlanController hoặc storage riêng ở bước sau."
            };

            return Ok(normalized);
        }

        /// <summary>
        /// Gợi ý template từ meal plan hiện có nếu user muốn lấy preset thay vì tìm món.
        /// </summary>
        [HttpGet("template-from-plan")]
        public async Task<IActionResult> TemplateFromPlan([FromQuery] DateOnly date)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var plan = await _userMealPlanService.GetByDateAsync(userId, date);
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

    public class FoodCaptureFallbackEstimateRequest
    {
        public Guid? FoodId { get; set; }
        public string MealType { get; set; } = string.Empty;
        public decimal QuantityG { get; set; } = 100;
        public decimal ProteinG { get; set; }
        public decimal CarbsG { get; set; }
        public decimal FatG { get; set; }
        public string? Notes { get; set; }
        public DateTime? LoggedAt { get; set; }
    }

    public class FoodCaptureSaveQuickAddRequest
    {
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }
        public string MealType { get; set; } = string.Empty;
        public decimal QuantityG { get; set; }
        public string? Notes { get; set; }
        public DateTime? LoggedAt { get; set; }
        public Guid? MealPlanItemId { get; set; }
    }
}
