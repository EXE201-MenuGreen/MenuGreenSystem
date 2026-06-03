using System;
using System.Linq;
using System.Security.Claims;
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

        private bool TryGetUserId(out Guid userId)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }

        /// <summary>
        /// Gợi ý món ăn/công thức theo mục tiêu calories của user.
        /// </summary>
        [HttpGet("calories")]
        public async Task<IActionResult> Calories([FromQuery] RecommendationRequest request)
        {
            return Ok(await _service.RecommendByCaloriesAsync(request));
        }

        /// <summary>
        /// Gợi ý món ăn/công thức tối ưu theo ngân sách và thời gian nấu.
        /// </summary>
        [HttpGet("eco")]
        public async Task<IActionResult> Eco([FromQuery] RecommendationRequest request)
        {
            return Ok(await _service.RecommendByEcoAsync(request));
        }

        /// <summary>
        /// Gợi ý bữa trưa nhanh, phù hợp calories và budget.
        /// </summary>
        [HttpGet("lunch")]
        public async Task<IActionResult> Lunch([FromQuery] RecommendationRequest request)
        {
            return Ok(await _service.RecommendLunchAsync(request));
        }

        /// <summary>
        /// Tạo thực đơn cả ngày từ target calories của user.
        /// </summary>
        [HttpGet("daily-menu")]
        public async Task<IActionResult> DailyMenu([FromQuery] RecommendationRequest request)
        {
            return Ok(await _service.BuildDailyMenuAsync(request));
        }

        /// <summary>
        /// Tạo lịch nhắc nấu ăn dựa trên giờ ăn dự kiến và thời gian chuẩn bị.
        /// </summary>
        [HttpPost("smart-schedule")]
        public async Task<IActionResult> SmartSchedule([FromBody] SmartScheduleRequest request)
        {
            return Ok(await _service.BuildSmartScheduleAsync(request));
        }

        /// <summary>
        /// Lấy lịch sử các recommendation đã tạo của user hiện tại.
        /// </summary>
        [HttpGet("history")]
        public async Task<IActionResult> History()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetHistoryAsync(userId));
        }

        /// <summary>
        /// Lấy chi tiết một recommendation cụ thể theo Id.
        /// </summary>
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetByIdAsync(userId, id));
        }

        /// <summary>
        /// Xem trước kết quả recommendation trước khi lưu hoặc áp dụng.
        /// </summary>
        [HttpPost("preview")]
        public async Task<IActionResult> Preview([FromBody] RecommendationPreviewRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.PreviewAsync(userId, request));
        }

        /// <summary>
        /// Lưu đánh giá/feedback của user cho một recommendation.
        /// </summary>
        [HttpPost("feedback")]
        public async Task<IActionResult> Feedback([FromBody] RecommendationFeedbackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.SubmitFeedbackAsync(userId, request);
            return Ok(new { Message = "Feedback saved successfully." });
        }

        /// <summary>
        /// Giải thích vì sao recommendation này được đề xuất.
        /// </summary>
        [HttpGet("explain/{id:guid}")]
        public async Task<IActionResult> Explain(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.ExplainAsync(userId, id));
        }
    }
}
