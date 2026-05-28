using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RecommendationController : ControllerBase
    {
        private readonly IRecommendationService _service;

        public RecommendationController(IRecommendationService service)
        {
            _service = service;
        }

        [HttpGet("calories")]
        public async Task<IActionResult> Calories([FromQuery] RecommendationRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.RecommendByCaloriesAsync(request));
        }

        [HttpGet("eco")]
        public async Task<IActionResult> Eco([FromQuery] RecommendationRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.RecommendByEcoAsync(request));
        }

        [HttpGet("lunch")]
        public async Task<IActionResult> Lunch([FromQuery] RecommendationRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.RecommendLunchAsync(request));
        }

        [HttpGet("daily-menu")]
        public async Task<IActionResult> DailyMenu([FromQuery] RecommendationRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.BuildDailyMenuAsync(request));
        }

        [HttpPost("smart-schedule")]
        public async Task<IActionResult> SmartSchedule([FromBody] SmartScheduleRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.BuildSmartScheduleAsync(request));
        }
    }
}
