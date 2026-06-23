using System;
using System.Collections.Generic;
using System.Linq;
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
    /// Vietnam-first nutrition endpoints.
    /// Most features reuse existing profile, food search, meal log, and recommendation flows to avoid duplication.
    /// </summary>
    [ApiController]
    [Route("api/Nutrition")]
    [Authorize(Policy = "UserOnly")]
    public class VietnamNutritionController : ControllerBase
    {
        private readonly IUserAiProfileService _aiProfileService;
        private readonly IFoodService _foodService;
        private readonly INutritionTrackingService _nutritionTrackingService;
        private readonly IRecommendationService _recommendationService;
        private readonly IPortionConverterService _portionConverterService;

        public VietnamNutritionController(
            IUserAiProfileService aiProfileService,
            IFoodService foodService,
            INutritionTrackingService nutritionTrackingService,
            IRecommendationService recommendationService,
            IPortionConverterService portionConverterService)
        {
            _aiProfileService = aiProfileService;
            _foodService = foodService;
            _nutritionTrackingService = nutritionTrackingService;
            _recommendationService = recommendationService;
            _portionConverterService = portionConverterService;
        }

        [HttpGet("local-preferences")]
        public async Task<IActionResult> GetLocalPreferences()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _aiProfileService.GetAsync(userId));
        }

        [HttpPost("local-preferences")]
        [HttpPut("local-preferences")]
        public async Task<IActionResult> UpsertLocalPreferences([FromBody] UpdateUserAiProfileRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _aiProfileService.UpsertAsync(userId, request));
        }

        [HttpGet("discovery/local")]
        public async Task<IActionResult> DiscoveryLocal([FromQuery] string? keyword, [FromQuery] int? maxPriceVnd)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _foodService.SearchAsync(keyword, null, null, null, maxPriceVnd, null, null, userId, null));
        }

        [HttpGet("discovery/local/by-region/{region}")]
        public async Task<IActionResult> DiscoveryByRegion(string region)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _foodService.SearchAsync(region, null, null, null, null, null, null, userId, null));
        }

        [HttpGet("discovery/local/by-budget")]
        public async Task<IActionResult> DiscoveryByBudget([FromQuery] int maxPrice)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _foodService.SearchAsync(null, null, null, null, maxPrice, null, null, userId, null));
        }

        [HttpGet("meal-log/vn/suggestions")]
        public async Task<IActionResult> MealLogSuggestions([FromQuery] string? keyword, [FromQuery] int? maxPriceVnd)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _foodService.SearchAsync(keyword, null, null, null, maxPriceVnd, null, null, userId, null));
        }

        [HttpPost("meal-log/vn")]
        public async Task<IActionResult> CreateVnMealLog([FromBody] VnMealLogUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                decimal quantityG = request.Quantity;

                if (request.FoodId.HasValue && !string.IsNullOrWhiteSpace(request.Unit) &&
                    !request.Unit.Equals("gram", StringComparison.OrdinalIgnoreCase) &&
                    !request.Unit.Equals("g", StringComparison.OrdinalIgnoreCase))
                {
                    var convertReq = new PortionConvertRequest
                    {
                        FoodId = request.FoodId.Value,
                        Unit = request.Unit,
                        Quantity = request.Quantity
                    };
                    var converted = await _portionConverterService.ConvertPortionAsync(convertReq, userId);
                    quantityG = converted.ConvertedGrams;
                }

                var standardRequest = new MealLogUpsertRequest
                {
                    FoodId = request.FoodId,
                    RecipeId = request.RecipeId,
                    MealType = request.MealType,
                    QuantityG = quantityG,
                    Notes = request.Notes,
                    LoggedAt = request.LoggedAt,
                    MealPlanItemId = request.MealPlanItemId
                };

                var created = await _nutritionTrackingService.CreateMealLogAsync(userId, standardRequest);

                var response = new VnMealLogResponse
                {
                    Id = created.Id,
                    UserId = created.UserId,
                    FoodId = created.FoodId,
                    RecipeId = created.RecipeId,
                    MealType = created.MealType,
                    QuantityG = created.QuantityG,
                    CaloriesKcal = created.CaloriesKcal,
                    ProteinG = created.ProteinG,
                    CarbsG = created.CarbsG,
                    FatG = created.FatG,
                    SourceType = created.SourceType,
                    Notes = created.Notes,
                    LoggedAt = created.LoggedAt,
                    MealPlanItemId = created.MealPlanItemId,
                    IsFromMealPlan = created.IsFromMealPlan,
                    FoodName = created.FoodName,
                    RecipeTitle = created.RecipeTitle,
                    DisplayName = created.DisplayName,
                    VnDisplayPortion = request.FoodId.HasValue ? $"{request.Quantity:0.##} {request.Unit}" : $"{request.Quantity:0.##}g"
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPost("meal-log/vn/quick-add")]
        public async Task<IActionResult> QuickAddVnMealLog([FromBody] VnMealLogUpsertRequest request)
        {
            return await CreateVnMealLog(request);
        }

        [HttpGet("meal-log/vn/history")]
        public async Task<IActionResult> GetVnMealLogHistory()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var history = await _nutritionTrackingService.GetMealLogsAsync(userId, 1, 20);
                var vnHistory = new List<VnMealLogResponse>();

                foreach (var log in history.MealLogs)
                {
                    var vnDisplay = await HelperInferVnPortion(log.FoodId, log.QuantityG, userId);
                    vnHistory.Add(new VnMealLogResponse
                    {
                        Id = log.Id,
                        UserId = log.UserId,
                        FoodId = log.FoodId,
                        RecipeId = log.RecipeId,
                        MealType = log.MealType,
                        QuantityG = log.QuantityG,
                        CaloriesKcal = log.CaloriesKcal,
                        ProteinG = log.ProteinG,
                        CarbsG = log.CarbsG,
                        FatG = log.FatG,
                        SourceType = log.SourceType,
                        Notes = log.Notes,
                        LoggedAt = log.LoggedAt,
                        MealPlanItemId = log.MealPlanItemId,
                        IsFromMealPlan = log.IsFromMealPlan,
                        FoodName = log.FoodName,
                        RecipeTitle = log.RecipeTitle,
                        DisplayName = log.DisplayName,
                        VnDisplayPortion = vnDisplay
                    });
                }

                return Ok(new { Items = vnHistory, TotalCount = history.TotalCount });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpGet("recommendations/budget-aware")]
        [HttpGet("recommendations/local-friendly")]
        public async Task<IActionResult> Recommendations([FromQuery] RecommendationRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _recommendationService.RecommendByEcoAsync(userId, request));
        }

        [HttpPost("recommendations/feedback")]
        public async Task<IActionResult> RecommendationFeedback([FromBody] RecommendationFeedbackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _recommendationService.SubmitFeedbackAsync(userId, request);
            return Ok(new { Message = "Feedback saved successfully." });
        }

        private bool TryGetUserId(out Guid userId)
        {
            var raw = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(raw, out userId);
        }

        private async Task<string> HelperInferVnPortion(Guid? foodId, decimal? quantityG, Guid userId)
        {
            if (!foodId.HasValue || !quantityG.HasValue || quantityG.Value <= 0)
            {
                return quantityG.HasValue ? $"{quantityG.Value:0.##}g" : "0g";
            }

            try
            {
                var units = await _portionConverterService.GetUnitsByFoodAsync(foodId.Value);
                foreach (var u in units)
                {
                    if (u.GramsPerUnit > 0)
                    {
                        var ratio = quantityG.Value / u.GramsPerUnit;
                        var rem = (ratio * 100) % 25;
                        if (rem == 0 && ratio >= 0.1m && ratio <= 20)
                        {
                            return $"{ratio:0.##} {u.UnitName}";
                        }
                    }
                }
            }
            catch
            {
                // Ignore and fall back to grams
            }

            return $"{quantityG.Value:0.##}g";
        }
    }
}
