using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "AdminOnly")]
    public class AiAdminController : ControllerBase
    {
        private readonly INutritionAssistantService _nutritionAssistantService;

        public AiAdminController(INutritionAssistantService nutritionAssistantService)
        {
            _nutritionAssistantService = nutritionAssistantService;
        }

        [HttpGet("overview")]
        public async Task<IActionResult> GetOverview([FromQuery] int recentTake = 10)
        {
            var result = await _nutritionAssistantService.GetAdminOverviewAsync(recentTake);
            return Ok(result);
        }

        [HttpGet("health")]
        public async Task<IActionResult> GetHealth()
        {
            var result = await _nutritionAssistantService.GetBridgeHealthAsync();
            return Ok(result);
        }
    }
}
