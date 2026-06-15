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
    /// Điều khiển các hoạt động hỗ trợ người dùng mới (1-tap daily starter) khởi động nhanh trong ứng dụng.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class DailyStarterController : ControllerBase
    {
        private readonly IDailyStarterService _service;
        private readonly IRecommendationService _recommendationService;

        public DailyStarterController(IDailyStarterService service, IRecommendationService recommendationService)
        {
            _service = service;
            _recommendationService = recommendationService;
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }

        /// <summary>
        /// Lấy thông tin tóm tắt khởi đầu ngày mới cho người dùng (Quote động, banner, calories mục tiêu, trạng thái onboarding).
        /// </summary>
        [HttpGet("today")]
        public async Task<IActionResult> GetTodayStarter()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetTodayStarterAsync(userId));
        }

        /// <summary>
        /// Gợi ý thực đơn mẫu cho người dùng mới (tái sử dụng thuật toán tạo thực đơn hàng ngày).
        /// </summary>
        [HttpGet("recommendations")]
        public async Task<IActionResult> GetRecommendations([FromQuery] int? targetCalories)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var request = new RecommendationRequest
            {
                TargetCalories = targetCalories,
                ExcludeUserAllergies = true,
                Top = 5
            };
            return Ok(await _recommendationService.BuildDailyMenuAsync(userId, request));
        }

        /// <summary>
        /// Lấy danh sách các món ăn nổi bật (phổ biến, lành mạnh) để bắt đầu nhanh.
        /// </summary>
        [HttpGet("featured-meals")]
        public async Task<IActionResult> GetFeaturedMeals()
        {
            return Ok(await _service.GetFeaturedMealsAsync());
        }

        /// <summary>
        /// Chọn nhanh một thực đơn mẫu để áp dụng trực tiếp vào kế hoạch ăn uống (MealPlan) của ngày hôm nay.
        /// </summary>
        [HttpPost("select-meal")]
        public async Task<IActionResult> SelectMeal([FromBody] DailyStarterSelectMealRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            
            await _service.SelectMealPlanAsync(userId, request);
            return Ok(new { Message = "Áp dụng thực đơn mẫu vào kế hoạch hôm nay thành công." });
        }

        /// <summary>
        /// Bắt đầu ghi nhật ký nhanh. Trả về gợi ý bữa ăn phù hợp dựa vào giờ hệ thống hiện tại.
        /// </summary>
        [HttpPost("start-log")]
        public async Task<IActionResult> StartLog()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.StartLogFlowAsync(userId));
        }

        /// <summary>
        /// Lấy thông tin gộp về cá nhân hóa hiện tại của người dùng (chỉ số sức khỏe, sở thích AI, dị ứng).
        /// </summary>
        [HttpGet("personalization")]
        public async Task<IActionResult> GetPersonalization()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetPersonalizationAsync(userId));
        }

        /// <summary>
        /// Cập nhật đồng thời các chỉ số cá nhân hóa của người dùng (HealthProfile, AI Profile, Allergy).
        /// </summary>
        [HttpPut("personalization")]
        public async Task<IActionResult> UpdatePersonalization([FromBody] DailyStarterPersonalizationUpdateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdatePersonalizationAsync(userId, request));
        }
    }
}
