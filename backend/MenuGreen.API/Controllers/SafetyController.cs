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
        /// Return disclaimer content by version.
        /// </summary>
        [HttpGet("disclaimer")]
        public IActionResult GetDisclaimer()
        {
            return Ok(new
            {
                Version = "1.0",
                Title = "MenuGreen Nutrition Disclaimer",
                Content = "MenuGreen only provides tracking and nutrition recommendations, and does not replace medical diagnosis or treatment.",
                UpdatedAt = DateTime.UtcNow
            });
        }

        /// <summary>
        /// Get current user consent status stored in AI Profile preferences.
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
        /// Update analytics/notification/marketing consent in AI Profile Preferences.
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

            // Overwrite or add new consent values
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

            // Record Activity Log
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
        /// Return high-risk safety/alerts based on actual BMI and user allergy list.
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
                "MenuGreen only provides nutrition guidance and does not replace professional medical diagnosis."
            };

            if (healthProfile != null && healthProfile.Bmi.HasValue)
            {
                decimal bmi = healthProfile.Bmi.Value;
                if (bmi < 16.0m)
                {
                    riskLevel = "high";
                    alertList.Add($"Safety alert: Your BMI is very low ({bmi:0.0}) - risk of severe malnutrition. Please consult a doctor or nutrition specialist to establish a proper recovery plan.");
                }
                else if (bmi > 30.0m)
                {
                    riskLevel = "high";
                    alertList.Add($"Safety alert: Your BMI reflects high obesity level ({bmi:0.0}). Please check cardiovascular health and consult a specialist before making sudden dietary changes.");
                }
                else if (bmi >= 25.0m && bmi <= 30.0m)
                {
                    riskLevel = "medium";
                    alertList.Add($"Note: Your BMI is in the overweight range ({bmi:0.0}). Consider moderate calorie adjustment.");
                }
            }

            if (allergies != null && allergies.Any())
            {
                var allergyNames = string.Join(", ", allergies.Select(a => a.Name));
                alertList.Add($"Allergy alert: You have registered allergies: {allergyNames}. We recommend always checking food ingredients carefully before preparing or logging meals.");
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
        /// Request to export all personal data (including Profile, Health Profile, AI Profile, Allergies).
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

            // Record Activity Log
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
        /// Request to delete personal data by deactivating user account.
        /// </summary>
        [HttpDelete("delete-data")]
        public async Task<IActionResult> DeleteData()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            // Deactivate user account
            var isActive = await _userService.ToggleUserStatusAsync(userId);

            // Record Activity Log
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
                Message = "Your account has been successfully deactivated per Google Play privacy and data deletion policy."
            });
        }

        /// <summary>
        /// Report production error or critical issue and save to Activity Log.
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

            // Record issue in Activity Logs
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
                Message = "Your issue report has been successfully recorded.",
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
