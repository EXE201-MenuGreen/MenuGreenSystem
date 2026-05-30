using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "UserOnly")]
    public class RecommendationController : ControllerBase
    {
        private readonly IRecommendationService _service;

        public RecommendationController(IRecommendationService service)
        {
            _service = service;
        }

        // Gợi ý món ăn hoặc combo dựa trên mục tiêu Calories.
        [HttpGet("calories")]
        public async Task<IActionResult> Calories([FromQuery] RecommendationRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.RecommendByCaloriesAsync(request));
        }

        // Gợi ý món ăn theo tiêu chí kinh tế: giá và thời gian nấu.
        [HttpGet("eco")]
        public async Task<IActionResult> Eco([FromQuery] RecommendationRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.RecommendByEcoAsync(request));
        }

        // Gợi ý bữa trưa nhanh, rẻ và phù hợp calories.
        [HttpGet("lunch")]
        public async Task<IActionResult> Lunch([FromQuery] RecommendationRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.RecommendLunchAsync(request));
        }

        // Tạo thực đơn một ngày gồm Breakfast, Lunch, Dinner, Snack.
        [HttpGet("daily-menu")]
        public async Task<IActionResult> DailyMenu([FromQuery] RecommendationRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.BuildDailyMenuAsync(request));
        }

        // Tính thời gian nhắc chuẩn bị món ăn dựa trên giờ ăn dự kiến.
        [HttpPost("smart-schedule")]
        public async Task<IActionResult> SmartSchedule([FromBody] SmartScheduleRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return Ok(await _service.BuildSmartScheduleAsync(request));
        }
    }
}
