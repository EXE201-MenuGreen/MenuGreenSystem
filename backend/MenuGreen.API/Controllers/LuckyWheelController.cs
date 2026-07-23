using System;
using System.Security.Claims;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "CasualFeatures")]
    public class LuckyWheelController : ControllerBase
    {
        private readonly ILuckyWheelService _luckyWheelService;

        public LuckyWheelController(ILuckyWheelService luckyWheelService)
        {
            _luckyWheelService = luckyWheelService;
        }

        /// <summary>
        /// Get 10 personalized non-duplicate foods for the lucky wheel display.
        /// </summary>
        [HttpGet("foods")]
        public async Task<IActionResult> GetWheelFoods()
        {
            if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
            {
                return Unauthorized();
            }

            var result = await _luckyWheelService.GetWheelFoodsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Apply the chosen food from the lucky wheel to today's meal plan.
        /// </summary>
        [HttpPost("apply")]
        public async Task<IActionResult> ApplySelection([FromBody] ApplyWheelSelectionRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
            {
                return Unauthorized();
            }

            try
            {
                await _luckyWheelService.ApplyWheelSelectionAsync(userId, request.FoodId, request.MealType);
                return Ok(new { Message = "Food applied to today's meal plan successfully." });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }

    public class ApplyWheelSelectionRequest
    {
        public Guid FoodId { get; set; }

        [RegularExpression("^(Breakfast|Lunch|Dinner|Snack)$", ErrorMessage = "MealType must be Breakfast, Lunch, Dinner, or Snack.")]
        public string MealType { get; set; } = "Snack";
    }
}
