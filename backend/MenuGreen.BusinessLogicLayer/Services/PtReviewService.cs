using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Nodes;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.Extensions.Logging;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class PtReviewService : IPtReviewService
    {
        private const int VietnamUtcOffsetHours = 7;

        private readonly IUnitOfWork _unitOfWork;
        private readonly IPlannedVsActualService _plannedVsActualService;
        private readonly NotiServiceWrapper _notificationService;
        private readonly ILogger<PtReviewService>? _logger;

        public PtReviewService(
            IUnitOfWork unitOfWork,
            IPlannedVsActualService plannedVsActualService,
            INotificationService notificationService,
            ILogger<PtReviewService>? logger = null)
        {
            _unitOfWork = unitOfWork;
            _plannedVsActualService = plannedVsActualService;
            // Wrapped because INotificationService is injected and we can cast it
            _notificationService = new NotiServiceWrapper(notificationService);
            _logger = logger;
        }

        public async Task<CreatePtReviewReportResponse> CreateReportAsync(Guid userId, CreatePtReviewReportRequest request)
        {
            var requestType = string.IsNullOrWhiteSpace(request.RequestType)
                ? "WeeklyReport"
                : request.RequestType.Trim();
            var isWeeklyReport = requestType.Equals(
                "WeeklyReport",
                StringComparison.OrdinalIgnoreCase);
            var isRouteApproval = requestType.Equals(
                "RouteApproval",
                StringComparison.OrdinalIgnoreCase);

            if (!isWeeklyReport && !isRouteApproval)
            {
                throw new Exception("Loại yêu cầu không hợp lệ.");
            }

            if (isWeeklyReport)
            {
                ValidateWeeklyReportWindow(request);

                var sameWeekRequests = await _unitOfWork.PtReviewRequests.FindAsync(r =>
                    r.UserId == userId && r.WeekStartDate == request.WeekStartDate);
                if (sameWeekRequests.Any(r =>
                    GetRequestType(r).Equals(
                        "WeeklyReport",
                        StringComparison.OrdinalIgnoreCase)))
                {
                    throw new Exception(
                        "Bạn đã gửi báo cáo cho tuần này. Mỗi tuần chỉ được gửi một báo cáo.");
                }
            }

            // 0. Check connection with PT
            var connections = await _unitOfWork.CoachConnections.FindAsync(c =>
                c.ClientId == userId &&
                (c.Status == "Connected" || c.Status == "Approved"));
            if (!connections.Any())
            {
                throw new Exception("Bạn chưa Đăng ký kết nối với PT");
            }

            var weekStartDate = request.WeekStartDate;
            // RouteApproval is the approval request for one daily plan.
            // WeeklyReport remains a seven-day snapshot.
            var weekEndDate = isRouteApproval
                ? weekStartDate
                : weekStartDate.AddDays(6);

            // 1. Load Health Profile
            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId);
            var healthProfile = healthProfiles.FirstOrDefault();
            var healthProfileSnapshot = new HealthProfileSnapshot();
            if (healthProfile != null)
            {
                healthProfileSnapshot.HeightCm = healthProfile.HeightCm;
                healthProfileSnapshot.WeightKg = healthProfile.WeightKg;
                healthProfileSnapshot.ActivityLevel = healthProfile.ActivityLevel;
                healthProfileSnapshot.Goal = healthProfile.Goal;
                healthProfileSnapshot.TargetCalories = healthProfile.TargetCalories;
                healthProfileSnapshot.TargetProteinG = healthProfile.TargetProteinG;
                healthProfileSnapshot.TargetCarbsG = healthProfile.TargetCarbsG;
                healthProfileSnapshot.TargetFatG = healthProfile.TargetFatG;
            }

            // 2. Fetch planned vs actual summaries
            var summary = await _plannedVsActualService.GetSummaryAsync(userId, weekStartDate, weekEndDate);
            var score = await _plannedVsActualService.GetAdherenceScoreAsync(userId, weekStartDate, weekEndDate);
            var drift = await _plannedVsActualService.GetDriftAnalysisAsync(userId, weekStartDate, weekEndDate);

            // 3. Fetch weight logs
            var startDateTime = weekStartDate
                .ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc)
                .AddHours(-VietnamUtcOffsetHours);
            var endDateTime = weekEndDate
                .ToDateTime(TimeOnly.MaxValue, DateTimeKind.Utc)
                .AddHours(-VietnamUtcOffsetHours);
            var weightLogs = await _unitOfWork.WeightLogs.FindAsync(w => w.UserId == userId && w.RecordedAt >= startDateTime && w.RecordedAt <= endDateTime);
            var weightLogsList = weightLogs.Select(w => new WeightLogSnapshot
            {
                WeightKg = w.WeightKg,
                BodyFatPercent = w.BodyFatPercent,
                RecordedAt = w.RecordedAt
            }).ToList();

            // 4. Load daily meals details (planned and actual)
            var plans = await _unitOfWork.MealPlanHeaders.FindAsync(h =>
                h.UserId == userId
                && h.StartDate <= weekEndDate
                && h.EndDate >= weekStartDate);
            var planIds = plans.Select(p => p.Id).ToList();
            var configuredPlan = SelectPlanForDate(plans, weekStartDate);
            var configuredTargets = await ResolveGymTargetsAsync(
                userId,
                weekStartDate);
            var planItems = planIds.Any()
                ? (await _unitOfWork.MealPlanItems.FindAsync(i => planIds.Contains(i.MealPlanId))).ToList()
                : new List<MealPlanItem>();

            var mealLogs = (await _unitOfWork.MealLogs.FindAsync(l => l.UserId == userId && l.LoggedAt >= startDateTime && l.LoggedAt <= endDateTime)).ToList();

            var foodIds = planItems.Where(i => i.FoodId.HasValue).Select(i => i.FoodId!.Value)
                .Concat(mealLogs.Where(l => l.FoodId.HasValue).Select(l => l.FoodId!.Value))
                .Distinct()
                .ToList();
            var recipeIds = planItems.Where(i => i.RecipeId.HasValue).Select(i => i.RecipeId!.Value)
                .Concat(mealLogs.Where(l => l.RecipeId.HasValue).Select(l => l.RecipeId!.Value))
                .Distinct()
                .ToList();

            var foods = foodIds.Any()
                ? (await _unitOfWork.Foods.FindAsync(f => foodIds.Contains(f.Id))).ToDictionary(f => f.Id)
                : new Dictionary<Guid, Food>();

            var recipes = recipeIds.Any()
                ? (await _unitOfWork.Recipes.FindAsync(r => recipeIds.Contains(r.Id))).ToDictionary(r => r.Id)
                : new Dictionary<Guid, Recipe>();

            var dailyMeals = new List<DailyMealsSnapshot>();
            var snapshotDayCount = isRouteApproval ? 1 : 7;
            for (int i = 0; i < snapshotDayCount; i++)
            {
                var currentDate = weekStartDate.AddDays(i);
                var dayMeals = new DailyMealsSnapshot { Date = currentDate };

                // Planned Items for this day
                var itemsForDay = planItems.Where(item => item.PlannedDate == currentDate).ToList();
                foreach (var item in itemsForDay)
                {
                    foods.TryGetValue(item.FoodId ?? Guid.Empty, out var food);
                    recipes.TryGetValue(item.RecipeId ?? Guid.Empty, out var recipe);

                    dayMeals.PlannedItems.Add(new MealPlanItemSnapshot
                    {
                        Id = item.Id,
                        MealType = item.MealType ?? "snack",
                        FoodId = item.FoodId,
                        FoodName = food?.NameVi,
                        RecipeId = item.RecipeId,
                        RecipeName = recipe?.Title,
                        TargetCalories = item.TargetCalories,
                        IsCompleted = item.IsCompleted
                    });
                }

                // Actual Logs for this day
                var logsForDay = mealLogs.Where(log =>
                    log.LoggedAt.HasValue
                    && DateOnly.FromDateTime(
                        log.LoggedAt.Value.AddHours(VietnamUtcOffsetHours)) == currentDate)
                    .ToList();
                foreach (var log in logsForDay)
                {
                    foods.TryGetValue(log.FoodId ?? Guid.Empty, out var food);
                    recipes.TryGetValue(log.RecipeId ?? Guid.Empty, out var recipe);

                    dayMeals.ActualLogs.Add(new MealLogSnapshot
                    {
                        Id = log.Id,
                        MealType = log.MealType ?? "snack",
                        FoodId = log.FoodId,
                        FoodName = food?.NameVi,
                        RecipeId = log.RecipeId,
                        RecipeName = recipe?.Title,
                        CaloriesKcal = log.CaloriesKcal,
                        QuantityG = log.QuantityG,
                        Notes = log.Notes,
                        LoggedAt = log.LoggedAt
                    });
                }

                dailyMeals.Add(dayMeals);
            }

            var snapshot = new WeeklyReportSnapshot
            {
                RequestType = requestType,
                MealPlanId = configuredPlan?.Id,
                WeekStartDate = weekStartDate,
                TargetCaloriesDaily =
                    configuredTargets.TargetCalories
                    ?? configuredPlan?.TargetCalories,
                MinCalories =
                    configuredTargets.MinCalories
                    ?? configuredPlan?.MinCalories,
                MaxCalories =
                    configuredTargets.MaxCalories
                    ?? configuredPlan?.MaxCalories,
                ConfigurationScope = configuredTargets.Scope,
                ConfigurationStartDate = configuredTargets.StartDate,
                ConfigurationEndDate = configuredTargets.EndDate,
                StudentNote = request.StudentNote ?? string.Empty,
                CheckInWeight = request.CheckInWeight,
                CheckInBodyFat = request.CheckInBodyFat,
                TrainingDaysCount = request.TrainingDaysCount,
                BodyFeeling = request.BodyFeeling ?? string.Empty,
                StudentHealthProfile = healthProfileSnapshot,
                NutritionSummary = summary,
                AdherenceScore = score,
                DriftAnalysis = drift,
                WeightLogs = weightLogsList,
                DailyMeals = dailyMeals
            };

            var reportId = Guid.NewGuid();
            var token = Guid.NewGuid().ToString("N");
            var expiresAt = DateTime.UtcNow.AddDays(request.ExpirationDays);

            var ptReviewRequest = new PtReviewRequest
            {
                Id = reportId,
                UserId = userId,
                WeekStartDate = weekStartDate,
                ReviewToken = token,
                ExpiresAt = expiresAt,
                Status = "Pending",
                CreatedAt = DateTime.UtcNow,
                ReportDataJson = System.Text.Json.JsonSerializer.Serialize(snapshot, new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                })
            };

            await _unitOfWork.PtReviewRequests.AddAsync(ptReviewRequest);
            await _unitOfWork.CompleteAsync();

            // Gửi notification cho PT và Gymer. Mỗi notification phải chạy độc
            // lập với nhau để nếu một bên lỗi vẫn không ảnh hưởng bên còn lại.
            // Trước đây toàn bộ khối đặt trong 1 try/catch lớn: khi gửi cho PT
            // bị nuốt exception thì Gymer cũng không nhận được thông báo.
            // FIX: tách 2 lần gửi, mỗi lần có try/atch riêng, đồng thời log lỗi
            // để dễ truy vết (trước đây nuốt hoàn toàn không log).
            string gymerName = "Học viên";
            try
            {
                var gymerProfile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == userId)).FirstOrDefault();
                if (!string.IsNullOrWhiteSpace(gymerProfile?.FullName))
                {
                    gymerName = gymerProfile!.FullName!;
                }
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, "PtReview.CreateReport: cannot load gymer profile for userId={UserId}", userId);
            }

            // Tìm Coach (PT) đang Connected với Gymer này. Cố gắng lấy cả
            // Status == "Connected" và "Approved" để phòng trường hợp seed data
            // hoặc tích hợp khác dùng status khác.
            Guid? coachId = null;
            try
            {
                var connection = (await _unitOfWork.CoachConnections.FindAsync(c =>
                    c.ClientId == userId &&
                    (c.Status == "Connected" || c.Status == "Approved"))).FirstOrDefault();
                if (connection != null && connection.CoachId != Guid.Empty)
                {
                    coachId = connection.CoachId;
                }
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, "PtReview.CreateReport: cannot load coach connection for userId={UserId}", userId);
            }

            // 1) Gửi notification cho PT/Coach.
            if (coachId.HasValue)
            {
                try
                {
                    await _notificationService.SendAsync(new NotificationSendRequest
                    {
                        UserId = coachId.Value,
                        Type = isWeeklyReport
                            ? "weekly_report_submitted"
                            : "pt_review_request",
                        Title = isWeeklyReport
                            ? "Báo cáo tuần mới từ học viên"
                            : "Yêu cầu duyệt lộ trình từ học viên",
                        Body = isWeeklyReport
                            ? $"Học viên {gymerName} vừa gửi báo cáo tuần. Hãy xem các chỉ số và gửi đánh giá."
                            : $"Học viên {gymerName} vừa gửi lộ trình ăn uống để bạn kiểm tra và duyệt.",
                        ActionUrl = isWeeklyReport
                            ? $"coach_weekly_report:{reportId}"
                            : null,
                        ScheduledAt = null
                    });
                }
                catch (Exception ex)
                {
                    _logger?.LogError(ex, "PtReview.CreateReport: failed to send notification to coach {CoachId}", coachId);
                    // Không throw - để Gymer vẫn nhận được notification bên dưới.
                }
            }
            else
            {
                _logger?.LogWarning(
                    "PtReview.CreateReport: Gymer {UserId} chưa có Connected Coach — bỏ qua notification cho PT",
                    userId);
            }

            // 2) Gửi notification cho Gymer (luôn luôn chạy).
            try
            {
                await _notificationService.SendAsync(new NotificationSendRequest
                {
                    UserId = userId,
                    Type = isWeeklyReport
                        ? "weekly_report_pending"
                        : "PT_REVIEW_SUBMITTED",
                    Title = isWeeklyReport
                        ? "Đã gửi báo cáo tuần cho PT"
                        : "Đã gửi lộ trình cho PT",
                    Body = isWeeklyReport
                        ? "Báo cáo tuần đã được gửi thành công. Trạng thái hiện tại: Chờ PT đánh giá."
                        : "Lộ trình ăn uống của bạn đã được gửi thành công đến PT. Đang chờ phản hồi.",
                    ActionUrl = isWeeklyReport
                        ? $"gymer_weekly_report:{reportId}"
                        : null,
                    ScheduledAt = null
                });
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "PtReview.CreateReport: failed to send notification to gymer {UserId}", userId);
            }

            var shareLink = $"https://menugreen.vn/shared-report/{token}";

            return new CreatePtReviewReportResponse
            {
                ReportId = reportId,
                ShareLink = shareLink,
                Token = token,
                ExpiresAt = expiresAt,
                WeekStartDate = weekStartDate,
                RequestType = requestType,
                Status = ptReviewRequest.Status,
                CreatedAt = ptReviewRequest.CreatedAt
            };
        }

        public async Task<PtReviewRequestDetailResponse> GetSharedReportAsync(string token)
        {
            var requests = await _unitOfWork.PtReviewRequests.FindAsync(x => x.ReviewToken == token);
            var request = requests.FirstOrDefault() ?? throw new Exception("Review request does not exist or token is invalid.");

            if (request.ExpiresAt < DateTime.UtcNow)
            {
                throw new Exception("Link has expired.");
            }

            var user = await _unitOfWork.Users.GetByIdAsync(request.UserId);
            var profile = user != null ? await _unitOfWork.Profiles.GetByIdAsync(request.UserId) : null;
            var studentName = profile?.FullName ?? user?.Email ?? "Student";

            var reportData = System.Text.Json.JsonSerializer.Deserialize<WeeklyReportSnapshot>(request.ReportDataJson, new System.Text.Json.JsonSerializerOptions
            {
                PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
            });
            await RefreshMealCompletionAsync(reportData);
            await RefreshConfiguredTargetsAsync(request, reportData);
            var effectiveDate = reportData == null
                ? request.WeekStartDate
                : ResolveReportDate(request, reportData);

            var suggestedChanges = new List<PtSuggestedChangeDto>();
            if (!string.IsNullOrEmpty(request.SuggestedChangesJson))
            {
                suggestedChanges = System.Text.Json.JsonSerializer.Deserialize<List<PtSuggestedChangeDto>>(request.SuggestedChangesJson, new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                }) ?? new List<PtSuggestedChangeDto>();
            }

            return new PtReviewRequestDetailResponse
            {
                ReportId = request.Id,
                StudentName = studentName,
                WeekStartDate = effectiveDate,
                ExpiresAt = request.ExpiresAt,
                Status = request.Status,
                CreatedAt = request.CreatedAt,
                PtComment = request.PtComment ?? string.Empty,
                SuggestedCalorieTarget = request.SuggestedCalorieTarget,
                SuggestedProteinTarget = request.SuggestedProteinTarget,
                ConfiguredCalorieTarget = reportData?.TargetCaloriesDaily,
                ConfiguredMinCalories = reportData?.MinCalories,
                ConfiguredMaxCalories = reportData?.MaxCalories,
                ConfigurationScope = reportData?.ConfigurationScope,
                ConfigurationStartDate = reportData?.ConfigurationStartDate,
                ConfigurationEndDate = reportData?.ConfigurationEndDate,
                SuggestedChanges = suggestedChanges,
                ReportData = reportData,
                ReviewedAt = request.ReviewedAt,
                ActionedAt = request.ActionedAt,
                ReviewToken = request.ReviewToken,
                RequestType = reportData?.RequestType ?? "",
                CreatedByRole = request.CreatedByRole
            };
        }

        public async Task<IEnumerable<PtReviewRequestDetailResponse>> GetMyRequestsAsync(Guid userId)
        {
            // This endpoint represents the Gymer -> PT direction only.
            // Coach-created PersonalPrograms have their own /my-personal-programs endpoint.
            var requests = await _unitOfWork.PtReviewRequests.FindAsync(
                x => x.UserId == userId && x.CreatedByRole != "Coach");
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            var profile = user != null ? await _unitOfWork.Profiles.GetByIdAsync(userId) : null;
            var studentName = profile?.FullName ?? user?.Email ?? "Student";

            var list = new List<PtReviewRequestDetailResponse>();
            foreach (var req in requests.OrderByDescending(r => r.CreatedAt))
            {
                var suggestedChanges = new List<PtSuggestedChangeDto>();
                if (!string.IsNullOrEmpty(req.SuggestedChangesJson))
                {
                    suggestedChanges = System.Text.Json.JsonSerializer.Deserialize<List<PtSuggestedChangeDto>>(req.SuggestedChangesJson, new System.Text.Json.JsonSerializerOptions
                    {
                        PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                    }) ?? new List<PtSuggestedChangeDto>();
                }

                string requestType = "";
                decimal? checkInWeight = null;
                decimal? checkInBodyFat = null;
                int? trainingDaysCount = null;
                string? bodyFeeling = null;
                string? studentNote = null;
                WeeklyReportSnapshot? reportData = null;
                try
                {
                    if (!string.IsNullOrEmpty(req.ReportDataJson))
                    {
                        reportData = System.Text.Json.JsonSerializer.Deserialize<WeeklyReportSnapshot>(
                            req.ReportDataJson,
                            new System.Text.Json.JsonSerializerOptions
                            {
                                PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                            });
                        using var doc = System.Text.Json.JsonDocument.Parse(req.ReportDataJson);
                        if (doc.RootElement.TryGetProperty("requestType", out var prop))
                        {
                            requestType = prop.GetString() ?? "";
                        }
                        if (doc.RootElement.TryGetProperty("checkInWeight", out var wProp) && wProp.ValueKind != System.Text.Json.JsonValueKind.Null)
                        {
                            checkInWeight = wProp.GetDecimal();
                        }
                        if (doc.RootElement.TryGetProperty("checkInBodyFat", out var bfProp) && bfProp.ValueKind != System.Text.Json.JsonValueKind.Null)
                        {
                            checkInBodyFat = bfProp.GetDecimal();
                        }
                        if (doc.RootElement.TryGetProperty("trainingDaysCount", out var tdProp) && tdProp.ValueKind != System.Text.Json.JsonValueKind.Null)
                        {
                            trainingDaysCount = tdProp.GetInt32();
                        }
                        if (doc.RootElement.TryGetProperty("bodyFeeling", out var fProp) && fProp.ValueKind != System.Text.Json.JsonValueKind.Null)
                        {
                            bodyFeeling = fProp.GetString();
                        }
                        if (doc.RootElement.TryGetProperty("studentNote", out var nProp) && nProp.ValueKind != System.Text.Json.JsonValueKind.Null)
                        {
                            studentNote = nProp.GetString();
                        }
                    }
                }
                catch {}
                var isRouteApproval = requestType.Equals(
                    "RouteApproval",
                    StringComparison.OrdinalIgnoreCase);
                var effectiveDate = isRouteApproval
                    ? DateOnly.FromDateTime(
                        DateTime.SpecifyKind(req.CreatedAt, DateTimeKind.Utc)
                            .AddHours(VietnamUtcOffsetHours))
                    : req.WeekStartDate;
                var configuredTargets = await ResolveGymTargetsAsync(
                    req.UserId,
                    effectiveDate);

                list.Add(new PtReviewRequestDetailResponse
                {
                    ReportId = req.Id,
                    StudentName = studentName,
                    WeekStartDate = effectiveDate,
                    ExpiresAt = DateTime.SpecifyKind(req.ExpiresAt, DateTimeKind.Utc),
                    Status = req.Status,
                    CreatedAt = DateTime.SpecifyKind(req.CreatedAt, DateTimeKind.Utc),
                    PtComment = req.PtComment ?? string.Empty,
                    SuggestedCalorieTarget = req.SuggestedCalorieTarget,
                    SuggestedProteinTarget = req.SuggestedProteinTarget,
                    ConfiguredCalorieTarget = configuredTargets.TargetCalories,
                    ConfiguredMinCalories = configuredTargets.MinCalories,
                    ConfiguredMaxCalories = configuredTargets.MaxCalories,
                    ConfigurationScope = configuredTargets.Scope,
                    ConfigurationStartDate = configuredTargets.StartDate,
                    ConfigurationEndDate = configuredTargets.EndDate,
                    SuggestedChanges = suggestedChanges,
                    ReportData = null, // Skip heavy report details in list view
                    ReviewedAt = req.ReviewedAt.HasValue ? DateTime.SpecifyKind(req.ReviewedAt.Value, DateTimeKind.Utc) : null,
                    ActionedAt = req.ActionedAt.HasValue ? DateTime.SpecifyKind(req.ActionedAt.Value, DateTimeKind.Utc) : null,
                    ReviewToken = req.ReviewToken,
                    RequestType = requestType,
                    CreatedByRole = req.CreatedByRole,
                    CheckInWeight = checkInWeight,
                    CheckInBodyFat = checkInBodyFat,
                    TrainingDaysCount = trainingDaysCount,
                    BodyFeeling = bodyFeeling,
                    StudentNote = studentNote
                });
            }

            return list;
        }

        public async Task SubmitReviewAsync(string token, PtSubmitReviewRequest request)
        {
            var requests = await _unitOfWork.PtReviewRequests.FindAsync(x => x.ReviewToken == token);
            var requestEntity = requests.FirstOrDefault() ?? throw new Exception("Review request does not exist.");

            if (requestEntity.ExpiresAt < DateTime.UtcNow)
            {
                throw new Exception("Link has expired.");
            }

            if (requestEntity.Status != "Pending")
            {
                throw new Exception("This review request has already been responded to or applied.");
            }

            requestEntity.PtComment = request.Comment;
            requestEntity.SuggestedCalorieTarget = request.SuggestedCalorieTarget;
            requestEntity.SuggestedProteinTarget = request.SuggestedProteinTarget;
            requestEntity.SuggestedChangesJson = System.Text.Json.JsonSerializer.Serialize(request.SuggestedChanges ?? new List<PtSuggestedChangeDto>(), new System.Text.Json.JsonSerializerOptions
            {
                PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
            });
            requestEntity.Status = "Reviewed";
            requestEntity.ReviewedAt = DateTime.UtcNow;

            _unitOfWork.PtReviewRequests.Update(requestEntity);
            await _unitOfWork.CompleteAsync();

            // Send notification to student
            try
            {
                string requestType = "";
                try
                {
                    if (!string.IsNullOrEmpty(requestEntity.ReportDataJson))
                    {
                        using var doc = System.Text.Json.JsonDocument.Parse(requestEntity.ReportDataJson);
                        if (doc.RootElement.TryGetProperty("requestType", out var prop))
                        {
                            requestType = prop.GetString() ?? "";
                        }
                    }
                }
                catch {}

                bool isRouteApproval = requestType.Equals("RouteApproval", StringComparison.OrdinalIgnoreCase) || string.IsNullOrEmpty(requestType);

                await _notificationService.SendAsync(new NotificationSendRequest
                {
                    UserId = requestEntity.UserId,
                    Type = isRouteApproval
                        ? "PT_ROUTE_APPROVAL"
                        : "weekly_report_reviewed",
                    Title = isRouteApproval
                        ? "Lộ trình dinh dưỡng đã được duyệt"
                        : "PT đã đánh giá báo cáo tuần",
                    Body = isRouteApproval 
                        ? "PT đã duyệt lộ trình dinh dưỡng của bạn. Hãy kiểm tra và áp dụng mục tiêu mới!" 
                        : "PT đã gửi nhận xét và mục tiêu điều chỉnh. Hãy xem báo cáo để cập nhật kế hoạch.",
                    ActionUrl = isRouteApproval
                        ? $"gymer_route_approval:{requestEntity.Id}"
                        : $"gymer_weekly_report:{requestEntity.Id}"
                });
            }
            catch
            {
                // Silence notification failures to prevent breaking core PT Review Submission
            }
        }

        public async Task<PtReviewRequestDetailResponse> GetReviewResultAsync(Guid userId, Guid requestId)
        {
            var requestEntity = await _unitOfWork.PtReviewRequests.GetByIdAsync(requestId)
                ?? throw new Exception("Review request does not exist.");

            if (requestEntity.UserId != userId)
            {
                throw new Exception("Access denied.");
            }

            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            var profile = user != null ? await _unitOfWork.Profiles.GetByIdAsync(userId) : null;
            var studentName = profile?.FullName ?? user?.Email ?? "Student";

            var reportData = System.Text.Json.JsonSerializer.Deserialize<WeeklyReportSnapshot>(requestEntity.ReportDataJson, new System.Text.Json.JsonSerializerOptions
            {
                PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
            });
            await RefreshMealCompletionAsync(reportData);
            await RefreshConfiguredTargetsAsync(requestEntity, reportData);
            var effectiveDate = reportData == null
                ? requestEntity.WeekStartDate
                : ResolveReportDate(requestEntity, reportData);

            var suggestedChanges = new List<PtSuggestedChangeDto>();
            if (!string.IsNullOrEmpty(requestEntity.SuggestedChangesJson))
            {
                suggestedChanges = System.Text.Json.JsonSerializer.Deserialize<List<PtSuggestedChangeDto>>(requestEntity.SuggestedChangesJson, new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                }) ?? new List<PtSuggestedChangeDto>();
            }

            return new PtReviewRequestDetailResponse
            {
                ReportId = requestEntity.Id,
                StudentName = studentName,
                WeekStartDate = effectiveDate,
                ExpiresAt = requestEntity.ExpiresAt,
                Status = requestEntity.Status,
                CreatedAt = requestEntity.CreatedAt,
                PtComment = requestEntity.PtComment ?? string.Empty,
                SuggestedCalorieTarget = requestEntity.SuggestedCalorieTarget,
                SuggestedProteinTarget = requestEntity.SuggestedProteinTarget,
                ConfiguredCalorieTarget = reportData?.TargetCaloriesDaily,
                ConfiguredMinCalories = reportData?.MinCalories,
                ConfiguredMaxCalories = reportData?.MaxCalories,
                ConfigurationScope = reportData?.ConfigurationScope,
                ConfigurationStartDate = reportData?.ConfigurationStartDate,
                ConfigurationEndDate = reportData?.ConfigurationEndDate,
                SuggestedChanges = suggestedChanges,
                ReportData = reportData,
                ReviewedAt = requestEntity.ReviewedAt,
                ActionedAt = requestEntity.ActionedAt,
                CheckInWeight = reportData?.CheckInWeight,
                CheckInBodyFat = reportData?.CheckInBodyFat,
                TrainingDaysCount = reportData?.TrainingDaysCount,
                BodyFeeling = reportData?.BodyFeeling,
                StudentNote = reportData?.StudentNote,
                RequestType = reportData?.RequestType ?? string.Empty,
                CreatedByRole = requestEntity.CreatedByRole
            };
        }

        public async Task ApplyReviewAsync(Guid userId, Guid requestId)
        {
            var requestEntity = await _unitOfWork.PtReviewRequests.GetByIdAsync(requestId)
                ?? throw new Exception("Review request does not exist.");

            if (requestEntity.UserId != userId)
            {
                throw new Exception("Access denied.");
            }

            if (requestEntity.Status != "Reviewed")
            {
                throw new Exception("Review request has not been responded to by PT or has already been processed.");
            }

            // 1. Update Health Profile target calorie/protein/macros
            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId);
            var healthProfile = healthProfiles.FirstOrDefault();
            if (healthProfile != null)
            {
                if (requestEntity.SuggestedCalorieTarget.HasValue)
                {
                    healthProfile.TargetCalories = requestEntity.SuggestedCalorieTarget.Value;
                    if (requestEntity.SuggestedProteinTarget.HasValue)
                    {
                        healthProfile.TargetProteinG = requestEntity.SuggestedProteinTarget.Value;
                        // Proportional distribution of Fat and Carbs
                        var remainingCal = requestEntity.SuggestedCalorieTarget.Value - (requestEntity.SuggestedProteinTarget.Value * 4);
                        if (remainingCal > 0)
                        {
                            healthProfile.TargetCarbsG = (int)Math.Round((remainingCal * 0.60) / 4);
                            healthProfile.TargetFatG = (int)Math.Round((remainingCal * 0.40) / 9);
                        }
                    }
                    else
                    {
                        // Use default formula to redistribute macros based on target calories
                        HealthProfileMetricsCalculator.ApplyMacroTargets(healthProfile);
                    }
                }
                healthProfile.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.HealthProfiles.Update(healthProfile);
            }

            // Sync targets to UserAiProfile.Preferences JSON so frontend reflects changes
            var aiProfiles = await _unitOfWork.UserAiProfiles.FindAsync(up => up.UserId == userId);
            var aiProfile = aiProfiles.FirstOrDefault();
            if (aiProfile != null && !string.IsNullOrEmpty(aiProfile.Preferences))
            {
                try
                {
                    var options = new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                    var prefs = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(aiProfile.Preferences, options) ?? new();
                    
                    if (requestEntity.SuggestedCalorieTarget.HasValue)
                    {
                        prefs["trainingDayTargetCalories"] = requestEntity.SuggestedCalorieTarget.Value;
                    }
                    if (requestEntity.SuggestedProteinTarget.HasValue)
                    {
                        prefs["minProteinG"] = requestEntity.SuggestedProteinTarget.Value;
                    }
                    
                    aiProfile.Preferences = System.Text.Json.JsonSerializer.Serialize(prefs);
                    aiProfile.UpdatedAt = DateTime.UtcNow;
                    _unitOfWork.UserAiProfiles.Update(aiProfile);
                }
                catch {}
            }

            // 2. Apply suggested meal alterations to next week's plan (or current week if route approval)
            string requestType = "";
            try
            {
                if (!string.IsNullOrEmpty(requestEntity.ReportDataJson))
                {
                    using var doc = System.Text.Json.JsonDocument.Parse(requestEntity.ReportDataJson);
                    if (doc.RootElement.TryGetProperty("requestType", out var prop))
                    {
                        requestType = prop.GetString() ?? "";
                    }
                }
            }
            catch {}

            bool isRouteApproval = requestType.Equals("RouteApproval", StringComparison.OrdinalIgnoreCase) || string.IsNullOrEmpty(requestType);
            var targetStartDate = isRouteApproval ? requestEntity.WeekStartDate : requestEntity.WeekStartDate.AddDays(7);

            var suggestedChanges = new List<PtSuggestedChangeDto>();
            if (!string.IsNullOrEmpty(requestEntity.SuggestedChangesJson))
            {
                suggestedChanges = System.Text.Json.JsonSerializer.Deserialize<List<PtSuggestedChangeDto>>(requestEntity.SuggestedChangesJson, new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                }) ?? new List<PtSuggestedChangeDto>();
            }

            foreach (var change in suggestedChanges)
            {
                var targetDate = GetTargetDate(targetStartDate, change.DayOfWeek);
                if (!targetDate.HasValue) continue;

                var dailyPlans = await _unitOfWork.MealPlanHeaders.FindAsync(x =>
                    x.UserId == userId
                    && x.PlanType == "DAILY"
                    && x.StartDate == targetDate.Value
                    && x.IsActive);
                var planHeader = dailyPlans.OrderByDescending(x => x.UpdatedAt ?? x.CreatedAt).FirstOrDefault();

                if (planHeader == null)
                {
                    planHeader = new MealPlanHeader
                    {
                        Id = Guid.NewGuid(),
                        UserId = userId,
                        Title = $"Daily plan {targetDate:yyyy-MM-dd}",
                        PlanType = "DAILY",
                        StartDate = targetDate.Value,
                        EndDate = targetDate.Value,
                        TargetCalories = healthProfile?.TargetCalories ?? 2000,
                        GeneratedBy = "PT_SUGGESTION",
                        IsActive = true,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };
                    await _unitOfWork.MealPlanHeaders.AddAsync(planHeader);
                    await _unitOfWork.CompleteAsync(); // save header first to establish foreign keys
                }

                var normMealType = NormalizeMealType(change.MealType);
                var planItems = (await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == planHeader.Id)).ToList();
                
                var cleanAction = (change.Action ?? "Replace").Trim().ToLowerInvariant();

                if (cleanAction == "replace")
                {
                    var targetItem = planItems.FirstOrDefault(x =>
                        NormalizeMealType(x.MealType ?? "") == normMealType
                        && (!change.OldFoodId.HasValue || x.FoodId == change.OldFoodId.Value));

                    if (targetItem != null)
                    {
                        if (change.NewFoodId.HasValue)
                        {
                            targetItem.FoodId = change.NewFoodId.Value;
                            targetItem.RecipeId = null;
                            var food = await _unitOfWork.Foods.GetByIdAsync(change.NewFoodId.Value);
                            if (food != null) targetItem.TargetCalories = (int?)food.CaloriesKcal;
                        }
                        else if (change.NewRecipeId.HasValue)
                        {
                            targetItem.RecipeId = change.NewRecipeId.Value;
                            targetItem.FoodId = null;
                            var recipe = await _unitOfWork.Recipes.GetByIdAsync(change.NewRecipeId.Value);
                            if (recipe != null) targetItem.TargetCalories = recipe.EstimatedPriceVnd.HasValue ? 500 : 400;
                        }
                        _unitOfWork.MealPlanItems.Update(targetItem);
                    }
                    else
                    {
                        // Fallback to Add
                        var newItem = new MealPlanItem
                        {
                            Id = Guid.NewGuid(),
                            MealPlanId = planHeader.Id,
                            MealType = normMealType,
                            PlannedDate = targetDate.Value,
                            ScheduledTime = normMealType switch
                            {
                                "breakfast" => new TimeOnly(7, 30),
                                "lunch" => new TimeOnly(12, 0),
                                "dinner" => new TimeOnly(18, 30),
                                _ => new TimeOnly(15, 0)
                            },
                            IsCompleted = false,
                            CreatedAt = DateTime.UtcNow
                        };
                        if (change.NewFoodId.HasValue)
                        {
                            newItem.FoodId = change.NewFoodId.Value;
                            var food = await _unitOfWork.Foods.GetByIdAsync(change.NewFoodId.Value);
                            if (food != null) newItem.TargetCalories = (int?)food.CaloriesKcal;
                        }
                        else if (change.NewRecipeId.HasValue)
                        {
                            newItem.RecipeId = change.NewRecipeId.Value;
                        }
                        await _unitOfWork.MealPlanItems.AddAsync(newItem);
                    }
                }
                else if (cleanAction == "add")
                {
                    var newItem = new MealPlanItem
                    {
                        Id = Guid.NewGuid(),
                        MealPlanId = planHeader.Id,
                        MealType = normMealType,
                        PlannedDate = targetDate.Value,
                        ScheduledTime = normMealType switch
                        {
                            "breakfast" => new TimeOnly(7, 30),
                            "lunch" => new TimeOnly(12, 0),
                            "dinner" => new TimeOnly(18, 30),
                            _ => new TimeOnly(15, 0)
                        },
                        IsCompleted = false,
                        CreatedAt = DateTime.UtcNow
                    };
                    if (change.NewFoodId.HasValue)
                    {
                        newItem.FoodId = change.NewFoodId.Value;
                        var food = await _unitOfWork.Foods.GetByIdAsync(change.NewFoodId.Value);
                        if (food != null) newItem.TargetCalories = (int?)food.CaloriesKcal;
                    }
                    else if (change.NewRecipeId.HasValue)
                    {
                        newItem.RecipeId = change.NewRecipeId.Value;
                    }
                    await _unitOfWork.MealPlanItems.AddAsync(newItem);
                }
                else if (cleanAction == "remove")
                {
                    var targetItem = planItems.FirstOrDefault(x =>
                        NormalizeMealType(x.MealType ?? "") == normMealType
                        && (!change.OldFoodId.HasValue || x.FoodId == change.OldFoodId.Value));
                    if (targetItem != null)
                    {
                        _unitOfWork.MealPlanItems.Remove(targetItem);
                    }
                }
            }

            requestEntity.Status = "Applied";
            requestEntity.ActionedAt = DateTime.UtcNow;

            _unitOfWork.PtReviewRequests.Update(requestEntity);
            await _unitOfWork.CompleteAsync();
        }

        public async Task RejectReviewAsync(Guid userId, Guid requestId)
        {
            var requestEntity = await _unitOfWork.PtReviewRequests.GetByIdAsync(requestId)
                ?? throw new Exception("Review request does not exist.");

            if (requestEntity.UserId != userId)
            {
                throw new Exception("Access denied.");
            }

            if (requestEntity.Status != "Reviewed")
            {
                throw new Exception("Review request has not been responded to by PT or has already been processed.");
            }

            requestEntity.Status = "Rejected";
            requestEntity.ActionedAt = DateTime.UtcNow;

            _unitOfWork.PtReviewRequests.Update(requestEntity);
            await _unitOfWork.CompleteAsync();
        }

        // ====================================================================
        // Phase 8: Coach -> Gymer (PersonalProgram direction)
        // ====================================================================

        public async Task<CreatePersonalProgramResponse> CreatePersonalProgramAsync(Guid coachId, CreatePersonalProgramRequest request)
        {
            // 1. Validate coach has Connected relationship with client.
            var connections = await _unitOfWork.CoachConnections.FindAsync(c =>
                c.ClientId == request.ClientId
                && c.CoachId == coachId
                && c.Status == "Connected");
            if (!connections.Any())
            {
                throw new Exception("You are not connected with this client.");
            }
            if (
                request.MinCalories.HasValue
                && request.MaxCalories.HasValue
                && request.MinCalories.Value > request.MaxCalories.Value
            )
            {
                throw new Exception("Calo tối thiểu không được lớn hơn calo tối đa.");
            }

            // 2. Keep at most one pending Coach -> Gymer program. When the PT
            // sends a newer plan, replace the pending payload instead of
            // blocking the submission. The database also enforces one pending
            // Coach program per client.
            var existing = (await _unitOfWork.PtReviewRequests.FindAsync(r =>
                r.UserId == request.ClientId
                && r.CreatedByRole == "Coach"
                && r.Status == "Pending")).FirstOrDefault();

            // 3. Validate client exists.
            var client = await _unitOfWork.Users.GetByIdAsync(request.ClientId)
                ?? throw new Exception("Client does not exist.");

            MealPlanHeader? mealPlan = null;
            if (request.MealPlanId.HasValue)
            {
                mealPlan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(
                    request.MealPlanId.Value
                );
                if (mealPlan == null || mealPlan.UserId != request.ClientId)
                {
                    throw new Exception("Lộ trình món ăn không tồn tại.");
                }
                if (!mealPlan.IsActive)
                {
                    throw new Exception("Lộ trình món ăn đã ngừng hoạt động.");
                }
            }

            // 4. Build snapshot JSON with all program data.
            var snapshot = new PersonalProgramSnapshot
            {
                Title = request.Title,
                Description = request.Description ?? string.Empty,
                DurationWeeks = request.DurationWeeks,
                WeekStartDate = request.WeekStartDate,
                TargetCaloriesDaily = request.TargetCaloriesDaily,
                MinCalories = request.MinCalories,
                MaxCalories = request.MaxCalories,
                TargetProteinG = request.TargetProteinG,
                TargetCarbsG = request.TargetCarbsG,
                TargetFatG = request.TargetFatG,
                CoachComment = request.CoachComment ?? string.Empty,
                SuggestedChanges = request.SuggestedChanges ?? new List<PtSuggestedChangeDto>(),
                MealPlanId = request.MealPlanId,
                PlanType = request.PlanType ?? mealPlan?.PlanType ?? "DAILY",
                StartDate = request.StartDate ?? mealPlan?.StartDate ?? request.WeekStartDate,
                EndDate = request.EndDate ?? mealPlan?.EndDate ?? request.WeekStartDate,
                Meals = request.Meals ?? new List<PersonalProgramMealDto>()
            };

            // 5. Create a new request, or update the existing pending request
            // so the Gymer sees only the PT's latest program.
            var now = DateTime.UtcNow;
            if (existing != null)
            {
                var previousSnapshot = TryParsePersonalProgramSnapshot(
                    existing.ReportDataJson
                );
                if (
                    previousSnapshot?.MealPlanId is Guid previousMealPlanId
                    && previousMealPlanId != request.MealPlanId
                )
                {
                    var previousMealPlan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(
                        previousMealPlanId
                    );
                    if (
                        previousMealPlan != null
                        && previousMealPlan.UserId == request.ClientId
                        && string.Equals(
                            previousMealPlan.Status,
                            "PendingAcceptance",
                            StringComparison.OrdinalIgnoreCase
                        )
                    )
                    {
                        previousMealPlan.Status = "Rejected";
                        previousMealPlan.ApprovedAt = null;
                        previousMealPlan.UpdatedAt = now;
                        _unitOfWork.MealPlanHeaders.Update(previousMealPlan);
                    }
                }
            }

            var programEntity = existing ?? new PtReviewRequest
            {
                Id = Guid.NewGuid(),
                UserId = request.ClientId,
                CreatedByRole = "Coach"
            };
            programEntity.WeekStartDate = request.WeekStartDate;
            programEntity.ReviewToken = Guid.NewGuid().ToString("N");
            programEntity.ExpiresAt = now.AddDays(30);
            programEntity.Status = "Pending";
            programEntity.CreatedAt = now;
            programEntity.ReportDataJson = System.Text.Json.JsonSerializer.Serialize(
                snapshot,
                new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                }
            );
            programEntity.PtComment = request.CoachComment;
            programEntity.SuggestedCalorieTarget = request.TargetCaloriesDaily;
            programEntity.SuggestedProteinTarget = request.TargetProteinG;
            programEntity.SuggestedCarbsTarget = request.TargetCarbsG;
            programEntity.SuggestedFatTarget = request.TargetFatG;
            programEntity.SuggestedChangesJson = System.Text.Json.JsonSerializer.Serialize(
                request.SuggestedChanges ?? new List<PtSuggestedChangeDto>(),
                new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                }
            );
            programEntity.ReviewedAt = null;
            programEntity.ActionedAt = null;
            programEntity.AcceptedAt = null;
            programEntity.AcceptedByUserId = null;

            if (existing == null)
            {
                await _unitOfWork.PtReviewRequests.AddAsync(programEntity);
            }
            else
            {
                _unitOfWork.PtReviewRequests.Update(programEntity);
            }
            if (mealPlan != null)
            {
                mealPlan.GeneratedBy = "COACH";
                mealPlan.Status = "PendingAcceptance";
                mealPlan.ApprovedAt = null;
                mealPlan.UpdatedAt = now;
                _unitOfWork.MealPlanHeaders.Update(mealPlan);
            }
            await _unitOfWork.CompleteAsync();

            // 6. Notify the Gymer.
            try
            {
                await _notificationService.SendAsync(new NotificationSendRequest
                {
                    UserId = request.ClientId,
                    Type = "COACH_PERSONAL_PROGRAM",
                    Title = "PT đã gửi lộ trình cá nhân",
                    Body = $"PT vừa gửi lộ trình \"{request.Title}\" ({GetPersonalProgramDurationLabel(snapshot)}). Mở tab \"PT gửi tôi\" để xem chi tiết và chấp nhận.",
                    ActionUrl = $"gymer_personal_program:{programEntity.Id}"
                });
            }
            catch
            {
                // Silence notification failure - PersonalProgram creation must not depend on notifications.
            }

            return new CreatePersonalProgramResponse
            {
                ProgramId = programEntity.Id,
                ClientId = request.ClientId,
                CreatedAt = programEntity.CreatedAt
            };
        }

        public async Task<PersonalProgramResponse> AcceptPersonalProgramAsync(Guid gymerId, Guid requestId)
        {
            var requestEntity = await _unitOfWork.PtReviewRequests.GetByIdAsync(requestId)
                ?? throw new Exception("Personal program does not exist.");

            if (requestEntity.UserId != gymerId)
            {
                throw new Exception("Access denied.");
            }

            if (requestEntity.CreatedByRole != "Coach")
            {
                throw new Exception("This request was not sent by your coach.");
            }

            if (requestEntity.Status != "Pending")
            {
                throw new Exception("Personal program has already been processed.");
            }

            var now = DateTime.UtcNow;
            var snapshot = TryParsePersonalProgramSnapshot(requestEntity.ReportDataJson);

            // Mark as Accepted.
            requestEntity.Status = "Accepted";
            requestEntity.AcceptedAt = now;
            requestEntity.AcceptedByUserId = gymerId;
            requestEntity.ActionedAt = now;
            _unitOfWork.PtReviewRequests.Update(requestEntity);

            if (snapshot?.MealPlanId != null)
            {
                var mealPlan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(
                    snapshot.MealPlanId.Value
                );
                if (mealPlan == null || mealPlan.UserId != gymerId)
                {
                    throw new Exception("Lộ trình món ăn đính kèm không tồn tại.");
                }

                mealPlan.Status = "Approved";
                mealPlan.ApprovedAt = now;
                mealPlan.UpdatedAt = now;
                _unitOfWork.MealPlanHeaders.Update(mealPlan);

                await ApplyScopedGymConfigurationAsync(
                    gymerId,
                    snapshot,
                    requestEntity.PtComment
                );
            }
            else
            {
                // Backward compatibility for legacy PersonalPrograms that only
                // contained general macro targets and no concrete meal plan.
                var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(
                    hp => hp.UserId == gymerId
                );
                var healthProfile = healthProfiles.FirstOrDefault();
                if (healthProfile != null && requestEntity.SuggestedCalorieTarget.HasValue)
                {
                    healthProfile.TargetCalories = requestEntity.SuggestedCalorieTarget.Value;
                    if (requestEntity.SuggestedProteinTarget.HasValue)
                        healthProfile.TargetProteinG = requestEntity.SuggestedProteinTarget.Value;
                    if (requestEntity.SuggestedCarbsTarget.HasValue)
                        healthProfile.TargetCarbsG = requestEntity.SuggestedCarbsTarget.Value;
                    if (requestEntity.SuggestedFatTarget.HasValue)
                        healthProfile.TargetFatG = requestEntity.SuggestedFatTarget.Value;
                    _unitOfWork.HealthProfiles.Update(healthProfile);
                }
            }

            await _unitOfWork.CompleteAsync();

            return await BuildPersonalProgramResponseAsync(requestEntity);
        }

        public async Task<PersonalProgramResponse> RejectPersonalProgramAsync(
            Guid gymerId,
            Guid requestId)
        {
            var requestEntity = await _unitOfWork.PtReviewRequests.GetByIdAsync(requestId)
                ?? throw new Exception("Personal program does not exist.");

            if (requestEntity.UserId != gymerId)
            {
                throw new Exception("Access denied.");
            }
            if (requestEntity.CreatedByRole != "Coach")
            {
                throw new Exception("This request was not sent by your coach.");
            }
            if (requestEntity.Status != "Pending")
            {
                throw new Exception("Personal program has already been processed.");
            }

            var now = DateTime.UtcNow;
            requestEntity.Status = "Rejected";
            requestEntity.ActionedAt = now;
            _unitOfWork.PtReviewRequests.Update(requestEntity);

            var snapshot = TryParsePersonalProgramSnapshot(requestEntity.ReportDataJson);
            if (snapshot?.MealPlanId != null)
            {
                var mealPlan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(
                    snapshot.MealPlanId.Value
                );
                if (mealPlan != null && mealPlan.UserId == gymerId)
                {
                    mealPlan.Status = "Rejected";
                    mealPlan.ApprovedAt = null;
                    mealPlan.UpdatedAt = now;
                    _unitOfWork.MealPlanHeaders.Update(mealPlan);
                }
            }

            await _unitOfWork.CompleteAsync();
            return await BuildPersonalProgramResponseAsync(requestEntity);
        }

        public async Task<IEnumerable<PersonalProgramResponse>> GetMyPersonalProgramsAsync(Guid gymerId)
        {
            var requests = (await _unitOfWork.PtReviewRequests.FindAsync(r =>
                r.UserId == gymerId && r.CreatedByRole == "Coach"))
                .OrderByDescending(r => r.CreatedAt)
                .ToList();

            var list = new List<PersonalProgramResponse>();
            foreach (var req in requests)
            {
                list.Add(await BuildPersonalProgramResponseAsync(req));
            }
            return list;
        }

        public async Task<IEnumerable<CoachSentProgramResponse>> GetCoachSentProgramsAsync(Guid coachId, Guid? clientId)
        {
            var requests = (await _unitOfWork.PtReviewRequests.FindAsync(r =>
                r.CreatedByRole == "Coach"
                && (clientId == null || r.UserId == clientId.Value)))
                .OrderByDescending(r => r.CreatedAt)
                .ToList();

            // Filter to only those sent by this coach (validate connection).
            var filtered = new List<PtReviewRequest>();
            foreach (var req in requests)
            {
                var hasConnection = (await _unitOfWork.CoachConnections.FindAsync(c =>
                    c.ClientId == req.UserId && c.CoachId == coachId && c.Status == "Connected")).Any();
                if (hasConnection)
                {
                    filtered.Add(req);
                }
            }

            var list = new List<CoachSentProgramResponse>();
            foreach (var req in filtered)
            {
                var client = await _unitOfWork.Users.GetByIdAsync(req.UserId);
                var profile = await _unitOfWork.Profiles.GetByIdAsync(req.UserId);
                var snapshot = TryParsePersonalProgramSnapshot(req.ReportDataJson);

                list.Add(new CoachSentProgramResponse
                {
                    Id = req.Id,
                    ClientId = req.UserId,
                    ClientName = profile?.FullName ?? client?.Email ?? "Client",
                    Title = snapshot?.Title ?? "Personal program",
                    Description = snapshot?.Description,
                    DurationWeeks = snapshot?.DurationWeeks ?? 0,
                    WeekStartDate = req.WeekStartDate,
                    TargetCaloriesDaily = snapshot?.TargetCaloriesDaily ?? 0,
                    MinCalories = snapshot?.MinCalories,
                    MaxCalories = snapshot?.MaxCalories,
                    TargetProteinG = snapshot?.TargetProteinG ?? 0,
                    TargetCarbsG = snapshot?.TargetCarbsG ?? 0,
                    TargetFatG = snapshot?.TargetFatG ?? 0,
                    Status = req.Status,
                    CreatedAt = req.CreatedAt,
                    AcceptedAt = req.AcceptedAt,
                    MealPlanId = snapshot?.MealPlanId,
                    PlanType = snapshot?.PlanType ?? "DAILY",
                    StartDate = snapshot?.StartDate ?? req.WeekStartDate,
                    EndDate = snapshot?.EndDate ?? req.WeekStartDate,
                    MealCount = snapshot?.Meals.Count ?? 0
                });
            }
            return list;
        }

        private async Task ApplyScopedGymConfigurationAsync(
            Guid gymerId,
            PersonalProgramSnapshot snapshot,
            string? coachComment)
        {
            var aiProfile = (await _unitOfWork.UserAiProfiles.FindAsync(
                profile => profile.UserId == gymerId
            )).FirstOrDefault();

            JsonObject preferences;
            try
            {
                preferences = string.IsNullOrWhiteSpace(aiProfile?.Preferences)
                    ? new JsonObject()
                    : JsonNode.Parse(aiProfile.Preferences!) as JsonObject
                        ?? new JsonObject();
            }
            catch
            {
                preferences = new JsonObject();
            }

            var planType = (snapshot.PlanType ?? "DAILY").Trim().ToUpperInvariant();
            var startDate = snapshot.StartDate == default
                ? snapshot.WeekStartDate
                : snapshot.StartDate;

            string arrayName;
            string keyName;
            string keyValue;
            if (planType == "MONTHLY")
            {
                arrayName = "monthlyDetails";
                keyName = "monthString";
                keyValue = startDate.ToString("yyyy-MM");
            }
            else if (planType == "WEEKLY")
            {
                arrayName = "weeklyDetails";
                keyName = "weekStartDateString";
                keyValue = startDate.ToString("yyyy-MM-dd");
            }
            else
            {
                arrayName = "dailyDetails";
                keyName = "dateString";
                keyValue = startDate.ToString("yyyy-MM-dd");
            }

            var details = preferences[arrayName] as JsonArray;
            if (details == null)
            {
                details = new JsonArray();
                preferences[arrayName] = details;
            }

            JsonObject? detail = null;
            foreach (var node in details)
            {
                if (
                    node is JsonObject candidate
                    && candidate[keyName]?.GetValue<string>() == keyValue
                )
                {
                    detail = candidate;
                    break;
                }
            }

            if (detail == null)
            {
                detail = new JsonObject { [keyName] = keyValue };
                details.Add(detail);
            }

            detail["customCalories"] = snapshot.TargetCaloriesDaily;
            if (snapshot.MinCalories.HasValue)
            {
                detail["minCalories"] = snapshot.MinCalories.Value;
            }
            if (snapshot.MaxCalories.HasValue)
            {
                detail["maxCalories"] = snapshot.MaxCalories.Value;
            }
            if (!string.IsNullOrWhiteSpace(coachComment))
            {
                detail["customNotes"] = coachComment.Trim();
            }

            if (planType == "DAILY" && detail["isTraining"] == null)
            {
                var schedule =
                    preferences["weeklyTrainingSchedule"]?.GetValue<string>()
                    ?? string.Empty;
                detail["dayOfWeek"] = startDate.DayOfWeek.ToString();
                detail["isTraining"] = schedule
                    .Split(',', StringSplitOptions.RemoveEmptyEntries)
                    .Select(day => day.Trim())
                    .Contains(
                        startDate.DayOfWeek.ToString(),
                        StringComparer.OrdinalIgnoreCase
                    );
            }

            if (aiProfile == null)
            {
                aiProfile = new UserAiProfile
                {
                    UserId = gymerId,
                    Preferences = preferences.ToJsonString(),
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.UserAiProfiles.AddAsync(aiProfile);
            }
            else
            {
                aiProfile.Preferences = preferences.ToJsonString();
                aiProfile.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.UserAiProfiles.Update(aiProfile);
            }
        }

        private async Task<PersonalProgramResponse> BuildPersonalProgramResponseAsync(PtReviewRequest req)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(req.UserId);
            var profile = await _unitOfWork.Profiles.GetByIdAsync(req.UserId);
            var snapshot = TryParsePersonalProgramSnapshot(req.ReportDataJson);

            return new PersonalProgramResponse
            {
                Id = req.Id,
                ClientId = req.UserId,
                ClientName = profile?.FullName ?? user?.Email ?? "Client",
                Title = snapshot?.Title ?? "Personal program",
                Description = snapshot?.Description,
                DurationWeeks = snapshot?.DurationWeeks ?? 0,
                WeekStartDate = req.WeekStartDate,
                TargetCaloriesDaily = snapshot?.TargetCaloriesDaily ?? 0,
                MinCalories = snapshot?.MinCalories,
                MaxCalories = snapshot?.MaxCalories,
                TargetProteinG = snapshot?.TargetProteinG ?? 0,
                TargetCarbsG = snapshot?.TargetCarbsG ?? 0,
                TargetFatG = snapshot?.TargetFatG ?? 0,
                CoachComment = req.PtComment,
                SuggestedChanges = ParseSuggestedChanges(req.SuggestedChangesJson),
                MealPlanId = snapshot?.MealPlanId,
                PlanType = snapshot?.PlanType ?? "DAILY",
                StartDate = snapshot?.StartDate ?? req.WeekStartDate,
                EndDate = snapshot?.EndDate ?? req.WeekStartDate,
                Meals = snapshot?.Meals ?? new List<PersonalProgramMealDto>(),
                Status = req.Status,
                CreatedAt = DateTime.SpecifyKind(req.CreatedAt, DateTimeKind.Utc),
                AcceptedAt = req.AcceptedAt.HasValue ? DateTime.SpecifyKind(req.AcceptedAt.Value, DateTimeKind.Utc) : null
            };
        }

        private static PersonalProgramSnapshot? TryParsePersonalProgramSnapshot(string? json)
        {
            if (string.IsNullOrEmpty(json)) return null;
            try
            {
                return System.Text.Json.JsonSerializer.Deserialize<PersonalProgramSnapshot>(json, new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase,
                    PropertyNameCaseInsensitive = true
                });
            }
            catch
            {
                return null;
            }
        }

        private static List<PtSuggestedChangeDto> ParseSuggestedChanges(string? json)
        {
            if (string.IsNullOrEmpty(json)) return new();
            try
            {
                return System.Text.Json.JsonSerializer.Deserialize<List<PtSuggestedChangeDto>>(json, new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase,
                    PropertyNameCaseInsensitive = true
                }) ?? new();
            }
            catch
            {
                return new();
            }
        }

        private static DateOnly? GetTargetDate(DateOnly nextWeekStartDate, string dayOfWeekStr)
        {
            var cleanStr = (dayOfWeekStr ?? string.Empty).Trim().ToLowerInvariant();
            int offset = -1;
            if (cleanStr.Contains("mon") || cleanStr.Contains("hai") || cleanStr == "thứ 2" || cleanStr == "thu 2") offset = 0;
            else if (cleanStr.Contains("tue") || cleanStr.Contains("ba") || cleanStr == "thứ 3" || cleanStr == "thu 3") offset = 1;
            else if (cleanStr.Contains("wed") || cleanStr.Contains("tư") || cleanStr.Contains("tu") || cleanStr == "thứ 4" || cleanStr == "thu 4") offset = 2;
            else if (cleanStr.Contains("thu") || cleanStr.Contains("năm") || cleanStr.Contains("nam") || cleanStr == "thứ 5" || cleanStr == "thu 5") offset = 3;
            else if (cleanStr.Contains("fri") || cleanStr.Contains("sáu") || cleanStr.Contains("sau") || cleanStr == "thứ 6" || cleanStr == "thu 6") offset = 4;
            else if (cleanStr.Contains("sat") || cleanStr.Contains("bảy") || cleanStr.Contains("bay") || cleanStr == "thứ 7" || cleanStr == "thu 7") offset = 5;
            else if (cleanStr.Contains("sun") || cleanStr.Contains("chủ") || cleanStr.Contains("chu") || cleanStr == "cn") offset = 6;

            if (offset >= 0)
            {
                return nextWeekStartDate.AddDays(offset);
            }
            return null;
        }

        private static void ValidateWeeklyReportWindow(
            CreatePtReviewReportRequest request)
        {
            // Vietnam does not observe daylight saving time, so UTC+7 is
            // deterministic on both Windows and Linux deployments.
            var vietnamToday = DateOnly.FromDateTime(DateTime.UtcNow.AddHours(7));
            if (vietnamToday.DayOfWeek != DayOfWeek.Sunday)
            {
                throw new Exception(
                    "Báo cáo tuần chỉ được tạo vào Chủ nhật sau khi tuần đã kết thúc.");
            }

            var expectedWeekStart = vietnamToday.AddDays(-6);
            if (request.WeekStartDate != expectedWeekStart)
            {
                throw new Exception(
                    $"Ngày bắt đầu tuần phải là Thứ hai {expectedWeekStart:dd/MM/yyyy}.");
            }

            if (!request.CheckInWeight.HasValue)
            {
                throw new Exception("Vui lòng nhập cân nặng hiện tại.");
            }

            if (!request.TrainingDaysCount.HasValue)
            {
                throw new Exception("Vui lòng chọn số buổi đã tập trong tuần.");
            }

            if (string.IsNullOrWhiteSpace(request.BodyFeeling))
            {
                throw new Exception("Vui lòng chọn cảm nhận thể trạng.");
            }
        }

        private static string GetRequestType(PtReviewRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.ReportDataJson))
            {
                return string.Empty;
            }

            try
            {
                using var document = System.Text.Json.JsonDocument.Parse(
                    request.ReportDataJson);
                return document.RootElement.TryGetProperty(
                    "requestType",
                    out var property)
                    ? property.GetString() ?? string.Empty
                    : string.Empty;
            }
            catch
            {
                return string.Empty;
            }
        }

        private static string NormalizeMealType(string mealType)
        {
            var normalized = (mealType ?? string.Empty).Trim().ToLowerInvariant();
            return normalized switch
            {
                "breakfast" or "lunch" or "dinner" or "snack" => normalized,
                "bữa sáng" or "bua sang" => "breakfast",
                "bữa trưa" or "bua trua" => "lunch",
                "bữa tối" or "bua toi" => "dinner",
                "bữa phụ" or "bua phu" => "snack",
                _ => normalized.Length > 0 ? normalized : "snack"
            };
        }

        private static string GetPersonalProgramDurationLabel(
            PersonalProgramSnapshot snapshot)
        {
            if (snapshot.PlanType.Equals(
                    "DAILY",
                    StringComparison.OrdinalIgnoreCase))
            {
                return "1 ngày";
            }

            var inclusiveDays =
                snapshot.EndDate.DayNumber - snapshot.StartDate.DayNumber + 1;
            if (snapshot.PlanType.Equals(
                    "MONTHLY",
                    StringComparison.OrdinalIgnoreCase)
                && inclusiveDays > 0)
            {
                return $"{inclusiveDays} ngày";
            }

            return $"{Math.Max(snapshot.DurationWeeks, 1)} tuần";
        }

        private async Task RefreshMealCompletionAsync(
            WeeklyReportSnapshot? reportData)
        {
            if (reportData == null) return;

            var snapshotItems = reportData.DailyMeals
                .SelectMany(day => day.PlannedItems)
                .Where(item => item.Id != Guid.Empty)
                .ToList();
            if (snapshotItems.Count == 0) return;

            var itemIds = snapshotItems.Select(item => item.Id).Distinct().ToList();
            var currentItems = await _unitOfWork.MealPlanItems.FindAsync(
                item => itemIds.Contains(item.Id));
            var completionById = currentItems.ToDictionary(
                item => item.Id,
                item => item.IsCompleted);

            foreach (var snapshotItem in snapshotItems)
            {
                if (completionById.TryGetValue(snapshotItem.Id, out var isCompleted))
                {
                    snapshotItem.IsCompleted = isCompleted;
                }
            }
        }

        private async Task RefreshConfiguredTargetsAsync(
            PtReviewRequest request,
            WeeklyReportSnapshot? reportData)
        {
            if (reportData == null) return;

            var targetDate = ResolveReportDate(request, reportData);
            var configuredTargets = await ResolveGymTargetsAsync(
                request.UserId,
                targetDate);
            var plans = await _unitOfWork.MealPlanHeaders.FindAsync(plan =>
                plan.UserId == request.UserId
                && plan.IsActive
                && plan.Status != "Draft"
                && plan.StartDate <= targetDate
                && (plan.EndDate ?? plan.StartDate) >= targetDate);
            var configuredPlan = SelectPlanForDate(plans, targetDate);

            reportData.TargetCaloriesDaily =
                configuredTargets.TargetCalories
                ?? configuredPlan?.TargetCalories;
            reportData.MinCalories =
                configuredTargets.MinCalories
                ?? configuredPlan?.MinCalories;
            reportData.MaxCalories =
                configuredTargets.MaxCalories
                ?? configuredPlan?.MaxCalories;
            if (
                string.IsNullOrWhiteSpace(reportData.ConfigurationScope)
                && !string.IsNullOrWhiteSpace(configuredTargets.Scope)
            )
            {
                reportData.ConfigurationScope = configuredTargets.Scope;
                reportData.ConfigurationStartDate = configuredTargets.StartDate;
                reportData.ConfigurationEndDate = configuredTargets.EndDate;
            }
        }

        private async Task<ConfiguredGymTargets> ResolveGymTargetsAsync(
            Guid userId,
            DateOnly date)
        {
            var profile = (await _unitOfWork.UserAiProfiles.FindAsync(
                item => item.UserId == userId
            )).FirstOrDefault();
            if (string.IsNullOrWhiteSpace(profile?.Preferences))
            {
                return new ConfiguredGymTargets();
            }

            JsonObject preferences;
            try
            {
                preferences = JsonNode.Parse(profile.Preferences!) as JsonObject
                    ?? new JsonObject();
            }
            catch
            {
                return new ConfiguredGymTargets();
            }

            var dateString = date.ToString("yyyy-MM-dd");
            var monday = date.AddDays(
                -(7 + (date.DayOfWeek - DayOfWeek.Monday)) % 7);
            var weekString = monday.ToString("yyyy-MM-dd");
            var monthString = date.ToString("yyyy-MM");

            var daily = FindScopedConfiguration(
                preferences,
                "dailyDetails",
                "dateString",
                dateString);
            var weekly = FindScopedConfiguration(
                preferences,
                "weeklyDetails",
                "weekStartDateString",
                weekString);
            var monthly = FindScopedConfiguration(
                preferences,
                "monthlyDetails",
                "monthString",
                monthString);

            var scope = daily != null
                ? "day"
                : weekly != null
                    ? "week"
                    : monthly != null
                        ? "month"
                        : null;
            DateOnly? scopeStart = scope switch
            {
                "day" => date,
                "week" => monday,
                "month" => new DateOnly(date.Year, date.Month, 1),
                _ => null
            };
            DateOnly? scopeEnd = scope switch
            {
                "day" => date,
                "week" => monday.AddDays(6),
                "month" => new DateOnly(date.Year, date.Month, 1)
                    .AddMonths(1)
                    .AddDays(-1),
                _ => null
            };

            var target =
                ReadInt(daily, "customCalories")
                ?? ReadInt(weekly, "customCalories")
                ?? ReadInt(monthly, "customCalories");
            var min =
                ReadInt(daily, "minCalories")
                ?? ReadInt(weekly, "minCalories")
                ?? ReadInt(monthly, "minCalories");
            var max =
                ReadInt(daily, "maxCalories")
                ?? ReadInt(weekly, "maxCalories")
                ?? ReadInt(monthly, "maxCalories");

            if (!target.HasValue)
            {
                var isTraining =
                    ReadBool(daily, "isTraining")
                    ?? IsScheduledTrainingDay(preferences, date.DayOfWeek);
                target = isTraining
                    ? ReadInt(preferences, "trainingDayTargetCalories")
                    : ReadInt(preferences, "restDayTargetCalories");
                min ??= ReadInt(preferences, "minCalories");
                max ??= ReadInt(preferences, "maxCalories");
            }

            return new ConfiguredGymTargets
            {
                TargetCalories = target,
                MinCalories = min,
                MaxCalories = max,
                Scope = scope,
                StartDate = scopeStart,
                EndDate = scopeEnd
            };
        }

        private static JsonObject? FindScopedConfiguration(
            JsonObject preferences,
            string arrayName,
            string keyName,
            string keyValue)
        {
            if (preferences[arrayName] is not JsonArray details) return null;
            return details
                .OfType<JsonObject>()
                .FirstOrDefault(item =>
                    item[keyName]?.GetValue<string>() == keyValue);
        }

        private static int? ReadInt(JsonObject? source, string key)
        {
            if (source?[key] is not JsonValue value) return null;
            if (value.TryGetValue<int>(out var integer)) return integer;
            if (
                value.TryGetValue<string>(out var text)
                && int.TryParse(text, out integer)
            )
            {
                return integer;
            }
            return null;
        }

        private static bool? ReadBool(JsonObject? source, string key)
        {
            if (
                source?[key] is JsonValue value
                && value.TryGetValue<bool>(out var result)
            )
            {
                return result;
            }
            return null;
        }

        private static bool IsScheduledTrainingDay(
            JsonObject preferences,
            DayOfWeek dayOfWeek)
        {
            var schedule =
                preferences["weeklyTrainingSchedule"]?.GetValue<string>()
                ?? string.Empty;
            return schedule
                .Split(',', StringSplitOptions.RemoveEmptyEntries)
                .Select(day => day.Trim())
                .Contains(
                    dayOfWeek.ToString(),
                    StringComparer.OrdinalIgnoreCase);
        }

        private static DateOnly ResolveReportDate(
            PtReviewRequest request,
            WeeklyReportSnapshot reportData)
        {
            if (!reportData.RequestType.Equals(
                    "RouteApproval",
                    StringComparison.OrdinalIgnoreCase))
            {
                return request.WeekStartDate;
            }

            var createdDate = DateOnly.FromDateTime(
                DateTime.SpecifyKind(request.CreatedAt, DateTimeKind.Utc)
                    .AddHours(VietnamUtcOffsetHours));
            if (reportData.DailyMeals.Any(day => day.Date == createdDate))
            {
                return createdDate;
            }

            if (reportData.DailyMeals.Count == 1)
            {
                return reportData.DailyMeals[0].Date;
            }

            return request.WeekStartDate;
        }

        private static MealPlanHeader? SelectPlanForDate(
            IEnumerable<MealPlanHeader> plans,
            DateOnly date)
        {
            return plans
                .Where(plan =>
                    plan.StartDate <= date
                    && (plan.EndDate ?? plan.StartDate) >= date)
                .OrderByDescending(plan =>
                    (plan.PlanType ?? string.Empty).Equals(
                        "DAILY",
                        StringComparison.OrdinalIgnoreCase)
                    && plan.StartDate == date)
                .ThenByDescending(plan => plan.UpdatedAt ?? plan.CreatedAt)
                .FirstOrDefault();
        }

        private sealed class ConfiguredGymTargets
        {
            public int? TargetCalories { get; init; }
            public int? MinCalories { get; init; }
            public int? MaxCalories { get; init; }
            public string? Scope { get; init; }
            public DateOnly? StartDate { get; init; }
            public DateOnly? EndDate { get; init; }
        }
    }

    // A lightweight wrapper to send notifications safely
    internal class NotiServiceWrapper
    {
        private readonly INotificationService _service;
        public NotiServiceWrapper(INotificationService service) { _service = service; }
        public async Task SendAsync(NotificationSendRequest request)
        {
            var mapped = new MenuGreen.BusinessLogicLayer.DTOs.Requests.NotificationSendRequest
            {
                UserId = request.UserId,
                Type = request.Type,
                Title = request.Title,
                Body = request.Body,
                ActionUrl = request.ActionUrl,
                ScheduledAt = null
            };
            await _service.SendAsync(mapped);
        }
    }

    // Support models inside the snapshot
    public class WeeklyReportSnapshot
    {
        public string RequestType { get; set; } = "WeeklyReport";
        public Guid? MealPlanId { get; set; }
        public DateOnly WeekStartDate { get; set; }
        public int? TargetCaloriesDaily { get; set; }
        public int? MinCalories { get; set; }
        public int? MaxCalories { get; set; }
        public string? ConfigurationScope { get; set; }
        public DateOnly? ConfigurationStartDate { get; set; }
        public DateOnly? ConfigurationEndDate { get; set; }
        public string StudentNote { get; set; } = string.Empty;
        public decimal? CheckInWeight { get; set; }
        public decimal? CheckInBodyFat { get; set; }
        public int? TrainingDaysCount { get; set; }
        public string BodyFeeling { get; set; } = string.Empty;
        public HealthProfileSnapshot StudentHealthProfile { get; set; } = new();
        public PlannedVsActualSummaryResponse NutritionSummary { get; set; } = new();
        public AdherenceScoreResponse AdherenceScore { get; set; } = new();
        public DriftAnalysisResponse DriftAnalysis { get; set; } = new();
        public List<WeightLogSnapshot> WeightLogs { get; set; } = new();
        public List<DailyMealsSnapshot> DailyMeals { get; set; } = new();
    }

    /// <summary>
    /// Phase 8: Snapshot JSON for PersonalProgram (Coach -> Gymer direction).
    /// </summary>
    public class PersonalProgramSnapshot
    {
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int DurationWeeks { get; set; }
        public DateOnly WeekStartDate { get; set; }
        public int TargetCaloriesDaily { get; set; }
        public int? MinCalories { get; set; }
        public int? MaxCalories { get; set; }
        public int TargetProteinG { get; set; }
        public int TargetCarbsG { get; set; }
        public int TargetFatG { get; set; }
        public string CoachComment { get; set; } = string.Empty;
        public List<PtSuggestedChangeDto> SuggestedChanges { get; set; } = new();
        public Guid? MealPlanId { get; set; }
        public string PlanType { get; set; } = "DAILY";
        public DateOnly StartDate { get; set; }
        public DateOnly EndDate { get; set; }
        public List<PersonalProgramMealDto> Meals { get; set; } = new();
    }

    public class HealthProfileSnapshot
    {
        public decimal? HeightCm { get; set; }
        public decimal? WeightKg { get; set; }
        public string? ActivityLevel { get; set; }
        public string? Goal { get; set; }
        public int? TargetCalories { get; set; }
        public int? TargetProteinG { get; set; }
        public int? TargetCarbsG { get; set; }
        public int? TargetFatG { get; set; }
    }

    public class WeightLogSnapshot
    {
        public decimal? WeightKg { get; set; }
        public decimal? BodyFatPercent { get; set; }
        public DateTime? RecordedAt { get; set; }
    }

    public class DailyMealsSnapshot
    {
        public DateOnly Date { get; set; }
        public List<MealPlanItemSnapshot> PlannedItems { get; set; } = new();
        public List<MealLogSnapshot> ActualLogs { get; set; } = new();
    }

    public class MealPlanItemSnapshot
    {
        public Guid Id { get; set; }
        public string MealType { get; set; } = string.Empty;
        public Guid? FoodId { get; set; }
        public string? FoodName { get; set; }
        public Guid? RecipeId { get; set; }
        public string? RecipeName { get; set; }
        public int? TargetCalories { get; set; }
        public bool IsCompleted { get; set; }
    }

    public class MealLogSnapshot
    {
        public Guid Id { get; set; }
        public string MealType { get; set; } = string.Empty;
        public Guid? FoodId { get; set; }
        public string? FoodName { get; set; }
        public Guid? RecipeId { get; set; }
        public string? RecipeName { get; set; }
        public decimal? CaloriesKcal { get; set; }
        public decimal? QuantityG { get; set; }
        public string? Notes { get; set; }
        public DateTime? LoggedAt { get; set; }
    }
}
