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
    /// Controller quản lý tính năng Micro-learning Cards - học dinh dưỡng ngắn và đố vui tích điểm.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class MicroLearningController : ControllerBase
    {
        private readonly IMicroLearningService _service;

        public MicroLearningController(IMicroLearningService service)
        {
            _service = service;
        }

        /// <summary>
        /// Lấy danh sách các thẻ kiến thức ngắn đề xuất dựa trên vấn đề dinh dưỡng/sức khỏe thực tế của user.
        /// </summary>
        [HttpGet("cards/recommended")]
        public async Task<IActionResult> GetRecommended()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var result = await _service.GetRecommendedCardsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Xem nội dung chi tiết của một thẻ micro-learning (bao gồm tiêu đề, tóm tắt, mẹo nhanh, đố vui).
        /// </summary>
        [HttpGet("cards/{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                var result = await _service.GetCardByIdAsync(id, userId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return NotFound(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy danh mục các nhóm chủ đề kiến thức (Protein, Sodium, Allergy, Hydration, General).
        /// </summary>
        [HttpGet("categories")]
        public async Task<IActionResult> GetCategories()
        {
            var result = await _service.GetCategoriesAsync();
            return Ok(result);
        }

        /// <summary>
        /// Ghi nhận hành động tương tác của user đối với thẻ (read - đã đọc, save - lưu, unsave - bỏ lưu, dismiss - ẩn thẻ).
        /// </summary>
        [HttpPost("cards/{id:guid}/action")]
        public async Task<IActionResult> RecordAction(Guid id, [FromBody] CardActionRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _service.RecordCardActionAsync(userId, id, request.Action);
                return Ok(new { success = result, message = $"Hành động '{request.Action}' được ghi nhận thành công." });
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return NotFound(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy danh sách toàn bộ các thẻ kiến thức mà user đã lưu trữ.
        /// </summary>
        [HttpGet("cards/saved")]
        public async Task<IActionResult> GetSavedCards()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var result = await _service.GetSavedCardsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Nộp câu trả lời cho mini-quiz đính kèm trên thẻ để nhận phản hồi và tích lũy điểm thưởng.
        /// </summary>
        [HttpPost("cards/{id:guid}/quiz/submit")]
        public async Task<IActionResult> SubmitQuiz(Guid id, [FromBody] QuizSubmitRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _service.SubmitQuizAnswerAsync(userId, id, request.SelectedOptionIndex);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
