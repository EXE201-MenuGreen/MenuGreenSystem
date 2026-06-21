using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text.Json;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Safety, trust, and compliance workflow controller.
    /// Reuses existing profile, health, allergy, user status, and analytics services to avoid duplicate storage.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class SafetyController : ControllerBase
    {
        private readonly IProfileService _profileService;
        private readonly INutritionTrackingService _nutritionTrackingService;
        private readonly IHealthProfileService _healthProfileService;
        private readonly IUserAiProfileService _userAiProfileService;
        private readonly IAllergyService _allergyService;
        private readonly IUserService _userService;
        private readonly IAnalyticsService _analyticsService;

        public SafetyController(
            IProfileService profileService,
            INutritionTrackingService nutritionTrackingService,
            IHealthProfileService healthProfileService,
            IUserAiProfileService userAiProfileService,
            IAllergyService allergyService,
            IUserService userService,
            IAnalyticsService analyticsService)
        {
            _profileService = profileService;
            _nutritionTrackingService = nutritionTrackingService;
            _healthProfileService = healthProfileService;
            _userAiProfileService = userAiProfileService;
            _allergyService = allergyService;
            _userService = userService;
            _analyticsService = analyticsService;
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
        /// Lấy trạng thái consent hiện tại của user được lưu trữ trong AI Profile preferences.
        /// </summary>
        [HttpGet("consent")]
        public async Task<IActionResult> GetConsent()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var aiProfile = await _userAiProfileService.GetAsync(userId);
            bool analytics = true;
            bool notification = true;
            bool marketing = false;

            if (aiProfile != null && !string.IsNullOrEmpty(aiProfile.Preferences))
            {
                try
                {
                    using var doc = JsonDocument.Parse(aiProfile.Preferences);
                    var root = doc.RootElement;
                    if (root.TryGetProperty("analyticsConsent", out var aProp)) analytics = aProp.GetBoolean();
                    if (root.TryGetProperty("notificationConsent", out var nProp)) notification = nProp.GetBoolean();
                    if (root.TryGetProperty("marketingConsent", out var mProp)) marketing = mProp.GetBoolean();
                }
                catch { }
            }

            return Ok(new
            {
                UserId = userId,
                Analytics = analytics,
                Notification = notification,
                Marketing = marketing,
                Source = "UserAiProfile.Preferences"
            });
        }

        /// <summary>
        /// Cập nhật consent analytics/notification/marketing vào AI Profile Preferences.
        /// </summary>
        [HttpPut("consent")]
        public async Task<IActionResult> UpdateConsent([FromBody] SafetyConsentRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var aiProfile = await _userAiProfileService.GetAsync(userId);
            var preferencesData = new Dictionary<string, object>();

            if (aiProfile != null && !string.IsNullOrEmpty(aiProfile.Preferences))
            {
                try
                {
                    var existingDict = JsonSerializer.Deserialize<Dictionary<string, object>>(aiProfile.Preferences);
                    if (existingDict != null)
                    {
                        preferencesData = existingDict;
                    }
                }
                catch { }
            }

            // Ghi đè hoặc thêm consent mới
            preferencesData["analyticsConsent"] = request.Analytics;
            preferencesData["notificationConsent"] = request.Notification;
            preferencesData["marketingConsent"] = request.Marketing;

            var preferencesJson = JsonSerializer.Serialize(preferencesData);

            await _userAiProfileService.UpsertAsync(userId, new UpdateUserAiProfileRequest
            {
                Preferences = preferencesJson,
                EatingPattern = aiProfile?.EatingPattern,
                DislikedFoods = aiProfile?.DislikedFoods,
                AllergiesAcknowledged = aiProfile?.AllergiesAcknowledged
            });

            // Ghi nhận Activity Log
            try
            {
                await _analyticsService.CreateActivityLogAsync(userId, new ActivityLogCreateRequest
                {
                    Action = "UpdateConsent",
                    EntityType = "Safety",
                    Metadata = preferencesJson
                });
            }
            catch { }

            return Ok(new
            {
                UserId = userId,
                request.Analytics,
                request.Notification,
                request.Marketing,
                Message = "Consent updated and saved to AI Profile preferences."
            });
        }

        /// <summary>
        /// Trả cảnh báo an toàn/rủi ro cao dựa trên chỉ số BMI thực tế và danh sách dị ứng của người dùng.
        /// </summary>
        [HttpGet("alerts")]
        public async Task<IActionResult> GetAlerts()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var healthProfile = await _healthProfileService.GetAsync(userId);
            var allergies = await _allergyService.GetAllAsync(userId);

            string riskLevel = "low";
            var alertList = new List<string>
            {
                "MenuGreen chỉ cung cấp hướng dẫn dinh dưỡng và không thay thế chẩn đoán y khoa từ bác sĩ chuyên môn."
            };

            if (healthProfile != null && healthProfile.Bmi.HasValue)
            {
                decimal bmi = healthProfile.Bmi.Value;
                if (bmi < 16.0m)
                {
                    riskLevel = "high";
                    alertList.Add($"Cảnh báo an toàn: Chỉ số BMI của bạn rất thấp ({bmi:0.0}) - nguy cơ suy dinh dưỡng mức độ nặng. Hãy tham vấn ý kiến bác sĩ hoặc chuyên gia dinh dưỡng để thiết lập chế độ phục hồi phù hợp.");
                }
                else if (bmi > 30.0m)
                {
                    riskLevel = "high";
                    alertList.Add($"Cảnh báo an toàn: Chỉ số BMI của bạn phản ánh béo phì mức độ cao ({bmi:0.0}). Vui lòng kiểm tra sức khỏe tim mạch và tham khảo ý kiến chuyên gia trước khi thay đổi chế độ dinh dưỡng đột ngột.");
                }
                else if (bmi >= 25.0m && bmi <= 30.0m)
                {
                    riskLevel = "medium";
                    alertList.Add($"Lưu ý: Chỉ số BMI của bạn đang ở ngưỡng thừa cân ({bmi:0.0}). Hãy cân nhắc điều chỉnh lượng calo vừa phải.");
                }
            }

            if (allergies != null && allergies.Any())
            {
                var allergyNames = string.Join(", ", allergies.Select(a => a.Name));
                alertList.Add($"Cảnh báo dị ứng: Bạn có đăng ký dị ứng với: {allergyNames}. Hệ thống đề xuất bạn luôn kiểm tra kỹ các thành phần món ăn trước khi chuẩn bị hoặc log bữa ăn.");
            }

            return Ok(new
            {
                UserId = userId,
                RiskLevel = riskLevel,
                Alerts = alertList,
                Bmi = healthProfile?.Bmi,
                AllergiesCount = allergies?.Count() ?? 0
            });
        }

        /// <summary>
        /// Yêu cầu xuất toàn bộ dữ liệu cá nhân (đóng gói trực tiếp Profile, Health Profile, AI Profile, Dị ứng).
        /// </summary>
        [HttpPost("export-data")]
        public async Task<IActionResult> ExportData()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var profile = await _profileService.GetProfileAsync(userId);
            var healthProfile = await _healthProfileService.GetAsync(userId);
            var aiProfile = await _userAiProfileService.GetAsync(userId);
            var allergies = await _allergyService.GetAllAsync(userId);

            var exportedData = new
            {
                ExportedAt = DateTime.UtcNow,
                UserId = userId,
                Profile = profile,
                HealthProfile = healthProfile,
                AiProfile = aiProfile,
                Allergies = allergies
            };

            // Ghi nhận Activity Log
            try
            {
                await _analyticsService.CreateActivityLogAsync(userId, new ActivityLogCreateRequest
                {
                    Action = "ExportData",
                    EntityType = "Safety",
                    Metadata = JsonSerializer.Serialize(new { message = "User personal data exported successfully." })
                });
            }
            catch { }

            return Ok(new
            {
                UserId = userId,
                Status = "Exported",
                ExportedAt = DateTime.UtcNow,
                Data = exportedData
            });
        }

        /// <summary>
        /// Yêu cầu xóa dữ liệu cá nhân bằng cách vô hiệu hóa tài khoản của người dùng.
        /// </summary>
        [HttpDelete("delete-data")]
        public async Task<IActionResult> DeleteData()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            // Vô hiệu hóa tài khoản của người dùng
            var isActive = await _userService.ToggleUserStatusAsync(userId);

            // Ghi nhận Activity Log
            try
            {
                await _analyticsService.CreateActivityLogAsync(userId, new ActivityLogCreateRequest
                {
                    Action = "DeleteData",
                    EntityType = "Safety",
                    Metadata = JsonSerializer.Serialize(new { message = "User requested account deactivation. Account deactivated." })
                });
            }
            catch { }

            return Ok(new
            {
                UserId = userId,
                Status = "Deactivated",
                IsActive = isActive,
                Message = "Tài khoản của bạn đã được vô hiệu hóa thành công theo chính sách bảo mật và xóa dữ liệu của Google Play."
            });
        }

        /// <summary>
        /// Gửi phản hồi lỗi production hoặc sự cố quan trọng và lưu vào Activity Log.
        /// </summary>
        [HttpPost("report-issue")]
        public async Task<IActionResult> ReportIssue([FromBody] SafetyReportIssueRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var issueMetadata = JsonSerializer.Serialize(new
            {
                request.Category,
                request.Severity,
                request.Description,
                request.ContactEmail
            });

            // Ghi nhận sự cố vào Activity Logs
            try
            {
                await _analyticsService.CreateActivityLogAsync(userId, new ActivityLogCreateRequest
                {
                    Action = "ReportIssue",
                    EntityType = "SafetyIssue",
                    Metadata = issueMetadata
                });
            }
            catch { }

            return Ok(new
            {
                UserId = userId,
                Status = "Received",
                Message = "Báo cáo sự cố của bạn đã được ghi nhận thành công.",
                request.Category,
                request.Severity
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

