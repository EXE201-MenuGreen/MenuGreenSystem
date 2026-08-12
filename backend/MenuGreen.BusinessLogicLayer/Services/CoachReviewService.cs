using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.Extensions.Logging;

namespace MenuGreen.BusinessLogicLayer.Services
{
    /// <summary>
    /// Coach-side weekly report service. Reads and writes
    /// <see cref="PtReviewRequest"/>s created by connected Gymers, but
    /// authenticates the caller via the <c>CoachConnection</c> table
    /// (logged-in Coach user) instead of via a shared <c>ReviewToken</c>.
    /// </summary>
    public class CoachReviewService : ICoachReviewService
    {
        private static readonly JsonSerializerOptions JsonOpts = new()
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        private readonly IUnitOfWork _unitOfWork;
        private readonly IPtReviewService _ptReviewService;
        private readonly INotificationService _notificationService;
        private readonly IMealPlanProposalService _proposalService;
        private readonly ILogger<CoachReviewService> _logger;

        public CoachReviewService(
            IUnitOfWork unitOfWork,
            IPtReviewService ptReviewService,
            INotificationService notificationService,
            IMealPlanProposalService proposalService,
            ILogger<CoachReviewService> logger)
        {
            _unitOfWork = unitOfWork;
            _ptReviewService = ptReviewService;
            _notificationService = notificationService;
            _proposalService = proposalService;
            _logger = logger;
        }

        public async Task<IEnumerable<CoachReportSummary>> ListReportsAsync(
            Guid coachId,
            DateTime? weekStart,
            string? month,
            string? status,
            Guid? clientId)
        {
            var connectedClientIds = await GetConnectedClientIdsAsync(coachId);
            if (connectedClientIds.Count == 0)
            {
                return Array.Empty<CoachReportSummary>();
            }

            var scopedIds = clientId.HasValue && clientId.Value != Guid.Empty
                ? new List<Guid> { clientId.Value }
                : connectedClientIds;

            // The connection scope and the requested client must overlap.
            if (clientId.HasValue && !connectedClientIds.Contains(clientId.Value))
            {
                throw new UnauthorizedAccessException(
                    "You do not have access to this student's reports.");
            }

            var requests = await _unitOfWork.PtReviewRequests.FindAsync(r =>
                scopedIds.Contains(r.UserId));

            var filtered = requests.AsEnumerable();

            if (weekStart.HasValue)
            {
                var ws = DateOnly.FromDateTime(weekStart.Value.Date);
                filtered = filtered.Where(r => r.WeekStartDate == ws);
            }
            else if (!string.IsNullOrWhiteSpace(month))
            {
                if (DateTime.TryParse(month + "-01", out var monthStart))
                {
                    var ms = DateOnly.FromDateTime(monthStart);
                    var me = ms.AddMonths(1).AddDays(-1);
                    filtered = filtered.Where(r => r.WeekStartDate >= ms && r.WeekStartDate <= me);
                }
            }

            if (!string.IsNullOrWhiteSpace(status))
            {
                var normalized = status.Trim();
                filtered = filtered.Where(r =>
                    string.Equals(r.Status, normalized, StringComparison.OrdinalIgnoreCase));
            }

            var summaries = new List<CoachReportSummary>();
            foreach (var req in filtered.OrderByDescending(r => r.CreatedAt))
            {
                var data = TryParseReportData(req.ReportDataJson);
                if (!IsAssignedToCoach(data, coachId))
                {
                    continue;
                }
                if (!IsReviewReport(req, data))
                {
                    continue;
                }

                var studentName = await GetStudentNameAsync(req.UserId);

                summaries.Add(new CoachReportSummary
                {
                    ReportId = req.Id,
                    ClientId = req.UserId,
                    StudentName = studentName,
                    WeekStartDate = req.WeekStartDate,
                    WeekEndDate = req.WeekStartDate.AddDays(6),
                    Status = req.Status,
                    CreatedAt = req.CreatedAt,
                    ReviewedAt = req.ReviewedAt,
                    ActionedAt = req.ActionedAt,
                    CheckInWeight = data?.CheckInWeight,
                    TrainingDaysCount = data?.TrainingDaysCount,
                    RequestType = data?.RequestType ?? "WeeklyReport"
                });
            }

            return summaries;
        }

        public async Task<CoachReportDetailResponse> GetReportDetailAsync(
            Guid coachId,
            Guid reportId)
        {
            var req = await _unitOfWork.PtReviewRequests.GetByIdAsync(reportId)
                ?? throw new Exception("Report not found.");

            await EnsureConnectedAsync(coachId, req.UserId);

            var studentName = await GetStudentNameAsync(req.UserId);
            var reportData = TryParseReportData(req.ReportDataJson);
            EnsureAssignedToCoach(reportData, coachId);
            if (req.Status.Equals("Pending", StringComparison.OrdinalIgnoreCase))
            {
                var liveResult = await _ptReviewService.GetReviewResultAsync(
                    req.UserId,
                    req.Id);
                reportData = liveResult.ReportData as WeeklyReportSnapshot
                    ?? reportData;
            }
            else if (reportData != null)
            {
                reportData.IsFrozen = true;
            }
            if (!IsReviewReport(req, reportData))
            {
                throw new Exception("Weekly report not found.");
            }
            var suggestedChanges = TryParseSuggestedChanges(req.SuggestedChangesJson);

            var existingProposal = (await _unitOfWork.MealPlanProposals.FindAsync(x =>
                    x.ReviewRequestId == req.Id))
                .OrderByDescending(x => x.CreatedAt)
                .FirstOrDefault();

            return new CoachReportDetailResponse
            {
                ReportId = req.Id,
                ClientId = req.UserId,
                StudentName = studentName,
                WeekStartDate = req.WeekStartDate,
                WeekEndDate = req.WeekStartDate.AddDays(6),
                ExpiresAt = req.ExpiresAt,
                Status = req.Status,
                CreatedAt = req.CreatedAt,
                PtComment = req.PtComment ?? string.Empty,
                SuggestedCalorieTarget = req.SuggestedCalorieTarget,
                SuggestedProteinTarget = req.SuggestedProteinTarget,
                SuggestedChanges = suggestedChanges,
                ReportData = reportData,
                ReviewedAt = req.ReviewedAt,
                ActionedAt = req.ActionedAt,
                RequestType = reportData?.RequestType ?? "WeeklyReport",
                CheckInWeight = reportData?.CheckInWeight,
                CheckInBodyFat = reportData?.CheckInBodyFat,
                TrainingDaysCount = reportData?.TrainingDaysCount,
                BodyFeeling = reportData?.BodyFeeling,
                StudentNote = reportData?.StudentNote,
                MealPlanProposal = existingProposal == null
                    ? null
                    : await _proposalService.GetAsync(coachId, existingProposal.Id)
            };
        }

        public async Task<CoachReportDetailResponse> SubmitReviewAsync(
            Guid coachId,
            Guid reportId,
            PtSubmitCoachReviewRequest request)
        {
            var req = await _unitOfWork.PtReviewRequests.GetByIdAsync(reportId)
                ?? throw new Exception("Report not found.");

            await EnsureConnectedAsync(coachId, req.UserId);

            var reportData = TryParseReportData(req.ReportDataJson);
            EnsureAssignedToCoach(reportData, coachId);
            if (!IsReviewReport(req, reportData))
            {
                throw new Exception("This request is not a mid-week or final weekly report.");
            }

            if (req.Status != "Pending")
            {
                throw new Exception("This report has already been reviewed or closed.");
            }

            // Refresh one last time and persist that payload before changing
            // status. Reviewed reports are immutable audit snapshots.
            var liveResult = await _ptReviewService.GetReviewResultAsync(
                req.UserId,
                req.Id);
            reportData = liveResult.ReportData as WeeklyReportSnapshot
                ?? reportData;
            if (reportData != null)
            {
                reportData.IsFrozen = true;
                reportData.IsPartial = reportData.DataThroughDate.HasValue
                    && reportData.DataThroughDate.Value
                        < req.WeekStartDate.AddDays(6);
                req.ReportDataJson = JsonSerializer.Serialize(reportData, JsonOpts);
            }

            req.PtComment = request.Comment;
            req.SuggestedCalorieTarget = request.SuggestedCalorieTarget;
            req.SuggestedProteinTarget = request.SuggestedProteinTarget;

            var proposal = await _proposalService.CreateDraftAsync(coachId, req.Id);
            var adjustments = request.AdjustMealPlanItems ?? new List<MealPlanAdjustmentItem>();
            if (adjustments.Count > 0)
            {
                var proposalItems = proposal.ProposalType.Equals(
                    MealPlanProposalService.NextWeekPlan,
                    StringComparison.OrdinalIgnoreCase)
                    ? proposal.Items.Select((item, index) =>
                        new MealPlanProposalItemRequest
                        {
                            Action = "Add",
                            PlannedDate = item.PlannedDate,
                            MealType = item.MealType,
                            FoodId = item.FoodId,
                            RecipeId = item.RecipeId,
                            QuantityG = item.QuantityG,
                            TargetCalories = item.TargetCalories,
                            Ingredients = item.Ingredients.Select(x =>
                                new MealPlanIngredientPortionRequest
                                {
                                    IngredientId = x.IngredientId,
                                    Quantity = x.Quantity,
                                    Unit = x.Unit
                                }).ToList(),
                            SortOrder = index
                        }).ToList()
                    : new List<MealPlanProposalItemRequest>();

                foreach (var adjustment in adjustments)
                {
                    if (proposal.ProposalType.Equals(
                        MealPlanProposalService.NextWeekPlan,
                        StringComparison.OrdinalIgnoreCase))
                    {
                        var matches = proposalItems.Where(item =>
                            item.PlannedDate == adjustment.PlannedDate &&
                            item.MealType.Equals(
                                adjustment.MealType,
                                StringComparison.OrdinalIgnoreCase)).ToList();
                        if (adjustment.Action.Equals("remove", StringComparison.OrdinalIgnoreCase))
                        {
                            foreach (var match in matches) proposalItems.Remove(match);
                            continue;
                        }
                        if (adjustment.Action.Equals("replace", StringComparison.OrdinalIgnoreCase)
                            && matches.Count > 0)
                        {
                            proposalItems.Remove(matches[0]);
                        }
                    }

                    proposalItems.Add(new MealPlanProposalItemRequest
                    {
                        Action = adjustment.Action,
                        PlannedDate = adjustment.PlannedDate,
                        MealType = adjustment.MealType,
                        ExistingMealPlanItemId = adjustment.ItemId,
                        FoodId = adjustment.FoodId,
                        RecipeId = adjustment.RecipeId,
                        QuantityG = adjustment.QuantityG,
                        TargetCalories = adjustment.TargetCalories,
                        Ingredients = adjustment.Ingredients,
                        SortOrder = proposalItems.Count
                    });
                }

                proposal = await _proposalService.UpdateDraftAsync(
                    coachId,
                    proposal.Id,
                    new UpdateMealPlanProposalRequest
                    {
                        Items = proposalItems
                    });
            }

            if (proposal.ProposalType.Equals(
                    MealPlanProposalService.NextWeekPlan,
                    StringComparison.OrdinalIgnoreCase) &&
                proposal.Items.Count == 0)
            {
                throw new Exception(
                    "Chưa có món để tạo lộ trình tuần kế tiếp. Hãy tạo lộ trình tuần mới trước khi gửi đánh giá.");
            }

            // Mid-week feedback may be submitted without menu changes. Final
            // reports always carry the generated seven-day draft.
            if (proposal.Items.Count > 0)
            {
                await _proposalService.SubmitAsync(coachId, proposal.Id);
            }

            // Legacy SuggestedChanges are deliberately left empty so the old
            // ApplyReview path cannot apply the same changes a second time.
            req.SuggestedChangesJson = "[]";
            req.Status = "Reviewed";
            req.ReviewedAt = DateTime.UtcNow;

            _unitOfWork.PtReviewRequests.Update(req);
            await _unitOfWork.CompleteAsync();

            try
            {
                await _notificationService.SendAsync(new NotificationSendRequest
                {
                    UserId = req.UserId,
                    Type = "weekly_report_reviewed",
                    Title = "PT đã đánh giá báo cáo tuần",
                    Body = "PT đã gửi nhận xét và mục tiêu điều chỉnh. Hãy mở báo cáo để xem và cập nhật kế hoạch.",
                    ActionUrl = $"gymer_weekly_report:{req.Id}"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Failed to notify Gymer {UserId} after weekly report {ReportId} review.",
                    req.UserId,
                    req.Id);
            }

            return await GetReportDetailAsync(coachId, reportId);
        }

        // ─────────────────────────────────────────────────────────────────────
        // Helpers
        // ─────────────────────────────────────────────────────────────────────

        private async Task<List<Guid>> GetConnectedClientIdsAsync(Guid coachId)
        {
            var connections = await _unitOfWork.CoachConnections.FindAsync(c =>
                c.CoachId == coachId &&
                (c.Status == "Connected" || c.Status == "Approved"));
            return connections.Select(c => c.ClientId).Distinct().ToList();
        }

        private async Task EnsureConnectedAsync(Guid coachId, Guid clientId)
        {
            var connections = await _unitOfWork.CoachConnections.FindAsync(c =>
                c.CoachId == coachId
                && c.ClientId == clientId
                && (c.Status == "Connected" || c.Status == "Approved"));
            if (!connections.Any())
            {
                throw new UnauthorizedAccessException(
                    "You do not have access to this student's reports.");
            }
        }

        private async Task<string> GetStudentNameAsync(Guid clientId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(clientId);
            if (user == null) return "Student";
            var profile = await _unitOfWork.Profiles.GetByIdAsync(clientId);
            return profile?.FullName ?? user.Email ?? "Student";
        }

        private static WeeklyReportSnapshot? TryParseReportData(string? json)
        {
            if (string.IsNullOrEmpty(json)) return null;
            try
            {
                return JsonSerializer.Deserialize<WeeklyReportSnapshot>(json, JsonOpts);
            }
            catch
            {
                return null;
            }
        }

        private static bool IsAssignedToCoach(
            WeeklyReportSnapshot? snapshot,
            Guid coachId)
        {
            // Legacy snapshots did not store the target PT. Their existing
            // connection check remains the compatibility fallback.
            return snapshot?.AssignedCoachId is not Guid assignedCoachId
                || assignedCoachId == coachId;
        }

        private static void EnsureAssignedToCoach(
            WeeklyReportSnapshot? snapshot,
            Guid coachId)
        {
            if (!IsAssignedToCoach(snapshot, coachId))
            {
                throw new UnauthorizedAccessException(
                    "This report was sent to another coach.");
            }
        }

        private static bool IsReviewReport(
            PtReviewRequest request,
            WeeklyReportSnapshot? snapshot)
        {
            return (string.IsNullOrWhiteSpace(request.CreatedByRole) ||
                    request.CreatedByRole.Equals(
                        "Gymer",
                        StringComparison.OrdinalIgnoreCase)) &&
                (string.Equals(
                    snapshot?.RequestType,
                    "WeeklyReport",
                    StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(
                    snapshot?.RequestType,
                    "MidWeekCheckIn",
                    StringComparison.OrdinalIgnoreCase));
        }

        private static List<PtSuggestedChangeDto> TryParseSuggestedChanges(string? json)
        {
            if (string.IsNullOrEmpty(json)) return new();
            try
            {
                return JsonSerializer.Deserialize<List<PtSuggestedChangeDto>>(json, JsonOpts)
                    ?? new List<PtSuggestedChangeDto>();
            }
            catch
            {
                return new List<PtSuggestedChangeDto>();
            }
        }

        /// <summary>
        /// Pushes Coach inline meal-plan edits to the Gymer's actual meal plan.
        /// Re-uses the same add / replace / remove semantics as the
        /// token-based Apply flow but uses the exact <see cref="PlannedDate"/>
        /// the Coach specified (no day-of-week translation needed).
        /// </summary>
        private async Task ApplyInlineAdjustmentsAsync(
            Guid clientId,
            List<MealPlanAdjustmentItem> adjustments)
        {
            foreach (var adj in adjustments)
            {
                var targetDate = adj.PlannedDate;
                var mealType = NormalizeMealType(adj.MealType);
                var action = (adj.Action ?? "Replace").Trim().ToLowerInvariant();

                var plans = await _unitOfWork.MealPlanHeaders.FindAsync(h =>
                    h.UserId == clientId
                    && h.StartDate == targetDate
                    && h.IsActive == true);
                var planHeader = plans.OrderByDescending(h => h.UpdatedAt ?? h.CreatedAt).FirstOrDefault();

                if (planHeader == null)
                {
                    planHeader = new MealPlanHeader
                    {
                        Id = Guid.NewGuid(),
                        UserId = clientId,
                        Title = $"Daily plan {targetDate:yyyy-MM-dd}",
                        PlanType = "DAILY",
                        StartDate = targetDate,
                        EndDate = targetDate,
                        TargetCalories = adj.TargetCalories ?? 2000,
                        GeneratedBy = "PT_COACH_INLINE",
                        IsActive = true,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };
                    await _unitOfWork.MealPlanHeaders.AddAsync(planHeader);
                    await _unitOfWork.CompleteAsync();
                }

                var planItems = (await _unitOfWork.MealPlanItems.FindAsync(i =>
                    i.MealPlanId == planHeader.Id)).ToList();

                if (action == "remove")
                {
                    var target = planItems.FirstOrDefault(i =>
                        NormalizeMealType(i.MealType ?? "") == mealType
                        && (adj.ItemId == null || i.Id == adj.ItemId));
                    if (target != null)
                    {
                        _unitOfWork.MealPlanItems.Remove(target);
                    }
                    continue;
                }

                if (action == "add" || action == "replace")
                {
                    var target = action == "replace"
                        ? planItems.FirstOrDefault(i =>
                            NormalizeMealType(i.MealType ?? "") == mealType
                            && (adj.ItemId == null || i.Id == adj.ItemId))
                        : null;

                    if (target != null)
                    {
                        if (adj.FoodId.HasValue)
                        {
                            target.FoodId = adj.FoodId;
                            target.RecipeId = null;
                            var food = await _unitOfWork.Foods.GetByIdAsync(adj.FoodId.Value);
                            if (food != null && food.CaloriesKcal.HasValue)
                            {
                                target.TargetCalories = (int?)food.CaloriesKcal.Value;
                            }
                        }
                        else if (adj.RecipeId.HasValue)
                        {
                            target.RecipeId = adj.RecipeId;
                            target.FoodId = null;
                        }
                        if (adj.TargetCalories.HasValue)
                        {
                            target.TargetCalories = adj.TargetCalories;
                        }
                        _unitOfWork.MealPlanItems.Update(target);
                    }
                    else
                    {
                        var newItem = new MealPlanItem
                        {
                            Id = Guid.NewGuid(),
                            MealPlanId = planHeader.Id,
                            MealType = mealType,
                            FoodId = adj.FoodId,
                            RecipeId = adj.RecipeId,
                            PlannedDate = targetDate,
                            ScheduledTime = mealType switch
                            {
                                "breakfast" => new TimeOnly(7, 30),
                                "lunch" => new TimeOnly(12, 0),
                                "dinner" => new TimeOnly(18, 30),
                                _ => new TimeOnly(15, 0)
                            },
                            TargetCalories = adj.TargetCalories,
                            IsCompleted = false,
                            Origin = "user",
                            CreatedAt = DateTime.UtcNow
                        };
                        if (adj.FoodId.HasValue)
                        {
                            var food = await _unitOfWork.Foods.GetByIdAsync(adj.FoodId.Value);
                            if (food != null && food.CaloriesKcal.HasValue && newItem.TargetCalories == null)
                            {
                                newItem.TargetCalories = (int?)food.CaloriesKcal.Value;
                            }
                        }
                        await _unitOfWork.MealPlanItems.AddAsync(newItem);
                    }
                }
            }

            await _unitOfWork.CompleteAsync();
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
    }
}
