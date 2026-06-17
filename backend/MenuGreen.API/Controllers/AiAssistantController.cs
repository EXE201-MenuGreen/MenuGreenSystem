using System;
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
    public class AiAssistantController : ControllerBase
    {
        private readonly IAiAssistantService _service;

        public AiAssistantController(IAiAssistantService service)
        {
            _service = service;
        }

        private bool TryGetUserId(out Guid userId)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }

        // ==========================================
        // A. Conversation Lifecycle
        // ==========================================

        /// <summary>
        /// Tạo một phiên hội thoại chat mới với trợ lý AI.
        /// </summary>
        [HttpPost("conversations")]
        public async Task<IActionResult> CreateConversation([FromBody] CreateConversationRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateConversationAsync(userId, request));
        }

        /// <summary>
        /// Lấy danh sách toàn bộ các hội thoại của người dùng hiện tại.
        /// </summary>
        [HttpGet("conversations")]
        public async Task<IActionResult> GetConversations()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetConversationsAsync(userId));
        }

        /// <summary>
        /// Lấy chi tiết một phiên hội thoại theo Id.
        /// </summary>
        [HttpGet("conversations/{id:guid}")]
        public async Task<IActionResult> GetConversationById(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetConversationByIdAsync(userId, id));
            }
            catch (Exception ex)
            {
                return NotFound(new { ex.Message });
            }
        }

        /// <summary>
        /// Xóa một phiên hội thoại chat theo Id.
        /// </summary>
        [HttpDelete("conversations/{id:guid}")]
        public async Task<IActionResult> DeleteConversation(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.DeleteConversationAsync(userId, id);
            return Ok(new { Message = "Conversation deleted successfully." });
        }

        /// <summary>
        /// Cập nhật/đổi tên tiêu đề của phiên hội thoại chat.
        /// </summary>
        [Obsolete]
        [HttpPatch("conversations/{id:guid}/title")]
        public async Task<IActionResult> UpdateConversationTitleOld(Guid id, [FromBody] string newTitle)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateConversationTitleAsync(userId, id, newTitle));
            }
            catch (Exception ex)
            {
                return NotFound(new { ex.Message });
            }
        }

        /// <summary>
        /// Cập nhật/đổi tên tiêu đề của phiên hội thoại chat (Hỗ trợ JSON payload).
        /// </summary>
        [HttpPatch("conversations/{id:guid}/title-json")]
        [HttpPost("conversations/{id:guid}/title")] // Hỗ trợ cả hai để dễ dàng gọi từ UI
        public async Task<IActionResult> UpdateConversationTitle(Guid id, [FromBody] TitleUpdateRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateConversationTitleAsync(userId, id, request.Title));
            }
            catch (Exception ex)
            {
                return NotFound(new { ex.Message });
            }
        }

        // ==========================================
        // B. Message Workflow
        // ==========================================

        /// <summary>
        /// Gửi tin nhắn mới vào một cuộc hội thoại và nhận phản hồi của AI.
        /// </summary>
        [HttpPost("conversations/{id:guid}/messages")]
        public async Task<IActionResult> SendMessage(Guid id, [FromBody] SendMessageRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.SendMessageAsync(userId, id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { ex.Message });
            }
        }

        /// <summary>
        /// Lấy toàn bộ các tin nhắn thuộc cuộc hội thoại cụ thể.
        /// </summary>
        [HttpGet("conversations/{id:guid}/messages")]
        public async Task<IActionResult> GetMessages(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetMessagesAsync(userId, id));
            }
            catch (Exception ex)
            {
                return NotFound(new { ex.Message });
            }
        }

        /// <summary>
        /// Yêu cầu AI sinh lại câu trả lời thay thế cho tin nhắn assistant chỉ định.
        /// </summary>
        [HttpPost("conversations/{id:guid}/messages/{msgId:guid}/regenerate")]
        public async Task<IActionResult> RegenerateMessage(Guid id, Guid msgId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.RegenerateMessageAsync(userId, id, msgId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { ex.Message });
            }
        }

        /// <summary>
        /// Gửi đánh giá/feedback (like/dislike) cho tin nhắn cụ thể của AI.
        /// </summary>
        [HttpPatch("conversations/{id:guid}/messages/{msgId:guid}/feedback")]
        [HttpPost("conversations/{id:guid}/messages/{msgId:guid}/feedback")]
        public async Task<IActionResult> FeedbackMessage(Guid id, Guid msgId, [FromBody] MessageFeedbackRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.FeedbackMessageAsync(userId, id, msgId, request);
                return Ok(new { Message = "Feedback recorded successfully." });
            }
            catch (Exception ex)
            {
                return NotFound(new { ex.Message });
            }
        }

        // ==========================================
        // C. Context & Profile
        // ==========================================

        /// <summary>
        /// Lấy toàn bộ ngữ cảnh sức khỏe, dinh dưỡng hiện tại của người dùng.
        /// </summary>
        [HttpGet("context")]
        public async Task<IActionResult> GetContext()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetContextAsync(userId));
        }

        /// <summary>
        /// Cập nhật sở thích/ngữ cảnh ưu tiên của người dùng.
        /// </summary>
        [HttpPut("context")]
        public async Task<IActionResult> UpdateContext([FromBody] UpdateAiProfileRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateProfileAsync(userId, request));
        }

        /// <summary>
        /// Lấy thông tin hồ sơ AI của người dùng (Preferences, DislikedFoods, EatingPattern).
        /// </summary>
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetProfileAsync(userId));
        }

        /// <summary>
        /// Cập nhật hồ sơ AI của người dùng.
        /// </summary>
        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateAiProfileRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateProfileAsync(userId, request));
        }

        // ==========================================
        // D. Action Suggestions
        // ==========================================

        /// <summary>
        /// Lấy danh sách câu hỏi đề xuất hành động tiếp theo dựa trên hồ sơ dinh dưỡng.
        /// </summary>
        [HttpGet("suggestions")]
        public async Task<IActionResult> GetSuggestions()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetSuggestionsAsync(userId));
        }

        /// <summary>
        /// AI phân tích và đề xuất tạo kế hoạch Meal Plan dựa trên yêu cầu văn bản.
        /// </summary>
        [HttpPost("actions/meal-plan")]
        public async Task<IActionResult> GenerateMealPlan([FromBody] PromptRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GenerateMealPlanFromAiAsync(userId, request.Prompt));
        }

        /// <summary>
        /// AI đề xuất món ăn/nguyên liệu thay thế lành mạnh dựa trên lý do cụ thể.
        /// </summary>
        [HttpPost("actions/replace-food")]
        public async Task<IActionResult> ReplaceFood([FromBody] ReplaceFoodRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.SuggestFoodReplacementAsync(userId, request.FoodId, request.Reason));
        }

        /// <summary>
        /// AI đề xuất phương án tối ưu hóa ngân sách thực đơn ăn uống.
        /// </summary>
        [HttpPost("actions/budget-optimize")]
        public async Task<IActionResult> BudgetOptimize()
        {
            // Mock action suggestion
            return Ok(new
            {
                Message = "Tối ưu hóa ngân sách hoàn tất.",
                SuggestedSavingsVnd = 50000,
                Tip = "Hãy thay thế ức gà tươi bằng trứng gà hoặc đậu hũ trong 2 bữa phụ để tiết kiệm chi phí mà vẫn đảm bảo lượng protein cần thiết."
            });
        }

        // ==========================================
        // E. History & Analytics
        // ==========================================

        /// <summary>
        /// Lấy thống kê các chủ đề trao đổi chính với trợ lý AI.
        /// </summary>
        [HttpGet("insights")]
        public async Task<IActionResult> GetInsights()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetInsightsAsync(userId));
        }

        /// <summary>
        /// Lấy văn bản tóm tắt nội dung ngắn gọn của một phiên hội thoại chỉ định.
        /// </summary>
        [HttpGet("conversations/{id:guid}/summary")]
        public async Task<IActionResult> SummarizeConversation(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                var summary = await _service.SummarizeConversationAsync(userId, id);
                return Ok(new { Summary = summary });
            }
            catch (Exception ex)
            {
                return NotFound(new { ex.Message });
            }
        }

        /// <summary>
        /// Thống kê số lượng sử dụng tin nhắn theo thời gian của người dùng.
        /// </summary>
        [HttpGet("usage")]
        public async Task<IActionResult> GetUsageMetrics()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetUsageMetricsAsync(userId));
        }

        // ==========================================
        // Helper DTOs for Controllers
        // ==========================================

        public class TitleUpdateRequest
        {
            public string Title { get; set; } = string.Empty;
        }

        public class PromptRequest
        {
            public string Prompt { get; set; } = string.Empty;
        }

        public class ReplaceFoodRequest
        {
            public Guid FoodId { get; set; }
            public string Reason { get; set; } = string.Empty;
        }
    }
}
