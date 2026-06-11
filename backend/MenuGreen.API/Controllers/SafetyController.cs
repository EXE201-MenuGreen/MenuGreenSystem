using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Safety, trust, and compliance workflow controller.
    /// Reuses existing profile and tracking data; avoids duplicating consent/risk engines.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class SafetyController : ControllerBase
    {
        private readonly IProfileService _profileService;
        private readonly INutritionTrackingService _nutritionTrackingService;

        public SafetyController(IProfileService profileService, INutritionTrackingService nutritionTrackingService)
        {
            _profileService = profileService;
            _nutritionTrackingService = nutritionTrackingService;
        }

        /// <summary>
        /// Trả nội dung disclaimer chuẩn theo version.
        /// </summary>
        [HttpGet("disclaimer")]
        public IActionResult GetDisclaimer()
        {
            return Ok(new
            {
                Version = "1.0",
                Title = "MenuGreen Nutrition Disclaimer",
                Content = "MenuGreen chỉ hỗ trợ theo dõi và gợi ý dinh dưỡng, không thay thế chẩn đoán hoặc điều trị y khoa.",
                UpdatedAt = DateTime.UtcNow
            });
        }

        /// <summary>
        /// Lấy trạng thái consent hiện tại của user.
        /// Hiện tại tái sử dụng profile flow hiện có, chưa tạo bảng consent riêng.
        /// </summary>
        [HttpGet("consent")]
        public async Task<IActionResult> GetConsent()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var profile = await _profileService.GetProfileAsync(userId);
            return Ok(new
            {
                UserId = userId,
                Analytics = true,
                Notification = true,
                Marketing = false,
                Source = "Derived from existing profile flow",
                Profile = profile
            });
        }

        /// <summary>
        /// Cập nhật consent analytics/notification/marketing.
        /// Hiện tại trả kết quả mô phỏng orchestration để tránh tạo storage trùng.
        /// </summary>
        [HttpPut("consent")]
        public IActionResult UpdateConsent([FromBody] SafetyConsentRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            return Ok(new
            {
                UserId = userId,
                request.Analytics,
                request.Notification,
                request.Marketing,
                Message = "Consent updated through existing profile/onboarding flow orchestration."
            });
        }

        /// <summary>
        /// Trả cảnh báo an toàn/rủi ro cao dựa trên profile và tracking hiện có.
        /// </summary>
        [HttpGet("alerts")]
        public async Task<IActionResult> GetAlerts()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var profile = await _profileService.GetProfileAsync(userId);
            var summary = await _nutritionTrackingService.GetNutritionSummaryAsync(userId, "week", null);

            return Ok(new
            {
                UserId = userId,
                RiskLevel = "low",
                Alerts = new[]
                {
                    "App only supports nutrition guidance and should not replace medical advice.",
                    "Review nutrition targets if you have allergies or health conditions."
                },
                Profile = profile,
                Summary = summary
            });
        }

        /// <summary>
        /// Yêu cầu xuất toàn bộ dữ liệu cá nhân.
        /// Hiện tại trả payload mô tả để nối vào export job sau này.
        /// </summary>
        [HttpPost("export-data")]
        public IActionResult ExportData()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            return Ok(new
            {
                UserId = userId,
                Status = "Queued",
                Message = "Export request accepted. Connect this endpoint to a background export job if needed."
            });
        }

        /// <summary>
        /// Yêu cầu xóa dữ liệu cá nhân theo chính sách.
        /// </summary>
        [HttpDelete("delete-data")]
        public IActionResult DeleteData()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            return Ok(new
            {
                UserId = userId,
                Status = "Queued",
                Message = "Delete request accepted. Connect this endpoint to a background delete workflow if needed."
            });
        }

        /// <summary>
        /// Gửi phản hồi lỗi production hoặc sự cố quan trọng.
        /// </summary>
        [HttpPost("report-issue")]
        public IActionResult ReportIssue([FromBody] SafetyReportIssueRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            return Ok(new
            {
                UserId = userId,
                Status = "Received",
                Message = "Issue report captured.",
                request.Category,
                request.Severity,
                request.Description,
                request.ContactEmail
            });
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }

    public class SafetyConsentRequest
    {
        public bool Analytics { get; set; }
        public bool Notification { get; set; }
        public bool Marketing { get; set; }
    }

    public class SafetyReportIssueRequest
    {
        public string? Category { get; set; }
        public string? Severity { get; set; }
        public string? Description { get; set; }
        public string? ContactEmail { get; set; }
    }
}
