using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class MealPlanProposalService : IMealPlanProposalService
    {
        public const string CurrentWeekAdjustment = "CurrentWeekAdjustment";
        public const string NextWeekPlan = "NextWeekPlan";
        private const string Draft = "Draft";
        private const string Pending = "Pending";
        private const string Applied = "Applied";
        private const string Rejected = "Rejected";
        private const string Expired = "Expired";

        private readonly IUnitOfWork _unitOfWork;
        private readonly ApplicationDbContext _db;
        private readonly INotificationService _notifications;
        private readonly IPortionNutritionCalculator _portionCalculator;

        public MealPlanProposalService(
            IUnitOfWork unitOfWork,
            ApplicationDbContext db,
            INotificationService notifications,
            IPortionNutritionCalculator portionCalculator)
        {
            _unitOfWork = unitOfWork;
            _db = db;
            _notifications = notifications;
            _portionCalculator = portionCalculator;
        }

        public async Task<MealPlanProposalResponse> CreateDraftAsync(
            Guid coachId,
            Guid reviewRequestId)
        {
            var review = await _unitOfWork.PtReviewRequests.GetByIdAsync(reviewRequestId)
                ?? throw new Exception("Không tìm thấy báo cáo.");
            await EnsureConnectedAsync(coachId, review.UserId);

            var requestType = GetRequestType(review.ReportDataJson);
            var proposalType = requestType.Equals("MidWeekCheckIn", StringComparison.OrdinalIgnoreCase)
                ? CurrentWeekAdjustment
                : requestType.Equals("WeeklyReport", StringComparison.OrdinalIgnoreCase)
                    ? NextWeekPlan
                    : throw new Exception("Loại báo cáo này không hỗ trợ tạo đề xuất lộ trình.");

            var existing = (await _unitOfWork.MealPlanProposals.FindAsync(x =>
                    x.ReviewRequestId == reviewRequestId && x.ProposalType == proposalType))
                .FirstOrDefault();
            if (existing != null)
            {
                if (proposalType == NextWeekPlan &&
                    existing.Status.Equals(Draft, StringComparison.OrdinalIgnoreCase))
                {
                    var existingItems = await _unitOfWork.MealPlanProposalItems.FindAsync(
                        x => x.ProposalId == existing.Id);
                    if (!existingItems.Any())
                    {
                        var rebuiltItems = await BuildNextWeekDraftItemsAsync(review, existing);
                        if (rebuiltItems.Count > 0)
                        {
                            await _unitOfWork.MealPlanProposalItems.AddRangeAsync(rebuiltItems);
                            existing.SourcePlanVersion = await GetSourcePlanVersionAsync(
                                review.UserId,
                                existing.PeriodStart,
                                existing.PeriodEnd);
                            existing.UpdatedAt = DateTime.UtcNow;
                            _unitOfWork.MealPlanProposals.Update(existing);
                            await _unitOfWork.CompleteAsync();
                        }
                    }
                }
                return await MapAsync(existing);
            }

            var periodStart = proposalType == CurrentWeekAdjustment
                ? review.WeekStartDate.AddDays(4)
                : review.WeekStartDate.AddDays(7);
            var periodEnd = proposalType == CurrentWeekAdjustment
                ? review.WeekStartDate.AddDays(6)
                : review.WeekStartDate.AddDays(13);

            var proposal = new MealPlanProposal
            {
                Id = Guid.NewGuid(),
                UserId = review.UserId,
                CoachId = coachId,
                ReviewRequestId = review.Id,
                ProposalType = proposalType,
                Status = Draft,
                PeriodStart = periodStart,
                PeriodEnd = periodEnd,
                ExpiresAt = proposalType == CurrentWeekAdjustment
                    ? VietnamMidnightToUtc(periodStart)
                    : null,
                SourcePlanVersion = await GetSourcePlanVersionAsync(
                    review.UserId,
                    proposalType == CurrentWeekAdjustment ? periodStart : review.WeekStartDate,
                    proposalType == CurrentWeekAdjustment ? periodEnd : review.WeekStartDate.AddDays(6)),
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MealPlanProposals.AddAsync(proposal);

            if (proposalType == NextWeekPlan)
            {
                var seedItems = await BuildNextWeekDraftItemsAsync(review, proposal);
                if (seedItems.Count > 0)
                {
                    await _unitOfWork.MealPlanProposalItems.AddRangeAsync(seedItems);
                }
            }

            await _unitOfWork.CompleteAsync();
            return await MapAsync(proposal);
        }

        public async Task<MealPlanProposalResponse> UpdateDraftAsync(
            Guid coachId,
            Guid proposalId,
            UpdateMealPlanProposalRequest request)
        {
            var proposal = await GetCoachProposalAsync(coachId, proposalId);
            if (!proposal.Status.Equals(Draft, StringComparison.OrdinalIgnoreCase))
            {
                throw new Exception("Chỉ có thể sửa đề xuất đang ở trạng thái bản nháp.");
            }

            var validated = new List<MealPlanProposalItem>();
            foreach (var input in request.Items)
            {
                validated.Add(await ValidateAndMapItemAsync(proposal, input));
            }

            var oldItems = await _unitOfWork.MealPlanProposalItems.FindAsync(
                x => x.ProposalId == proposal.Id);
            _unitOfWork.MealPlanProposalItems.RemoveRange(oldItems);
            if (validated.Count > 0)
            {
                await _unitOfWork.MealPlanProposalItems.AddRangeAsync(validated);
            }
            proposal.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.MealPlanProposals.Update(proposal);
            await _unitOfWork.CompleteAsync();
            return await MapAsync(proposal);
        }

        public async Task<MealPlanProposalItemResponse> UpdateItemPortionAsync(
            Guid coachId,
            Guid proposalId,
            Guid itemId,
            UpdateMealPlanProposalItemPortionRequest request)
        {
            var proposal = await GetCoachProposalAsync(coachId, proposalId);
            if (!proposal.Status.Equals(Draft, StringComparison.OrdinalIgnoreCase))
                throw new Exception("Chỉ có thể sửa khẩu phần khi đề xuất còn là bản nháp.");

            var item = await _unitOfWork.MealPlanProposalItems.GetByIdAsync(itemId)
                ?? throw new Exception("Không tìm thấy món trong đề xuất.");
            if (item.ProposalId != proposal.Id || !item.RecipeId.HasValue)
                throw new Exception("Chỉ món có công thức trong đề xuất này mới chỉnh được nguyên liệu.");

            await ApplyRecipeNutritionAsync(item, item.RecipeId.Value, request.Ingredients);
            _unitOfWork.MealPlanProposalItems.Update(item);
            proposal.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.MealPlanProposals.Update(proposal);
            await _unitOfWork.CompleteAsync();

            var mapped = await MapAsync(proposal);
            return mapped.Items.First(x => x.Id == item.Id);
        }

        public async Task<MealPlanProposalResponse> SubmitAsync(Guid coachId, Guid proposalId)
        {
            var proposal = await GetCoachProposalAsync(coachId, proposalId);
            if (!proposal.Status.Equals(Draft, StringComparison.OrdinalIgnoreCase))
            {
                throw new Exception("Đề xuất đã được gửi hoặc xử lý.");
            }

            var items = (await _unitOfWork.MealPlanProposalItems.FindAsync(
                x => x.ProposalId == proposal.Id)).ToList();
            if (items.Count == 0)
            {
                throw new Exception("Đề xuất phải có ít nhất một món.");
            }

            if (proposal.ProposalType == NextWeekPlan)
            {
                var missingDays = Enumerable.Range(0, 7)
                    .Select(offset => proposal.PeriodStart.AddDays(offset))
                    .Where(date => items.All(item => item.PlannedDate != date))
                    .ToList();
                if (missingDays.Count > 0)
                {
                    throw new Exception("Lộ trình tuần mới phải có món cho đủ 7 ngày.");
                }
            }

            proposal.Status = Pending;
            proposal.SubmittedAt = DateTime.UtcNow;
            proposal.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.MealPlanProposals.Update(proposal);
            await _unitOfWork.CompleteAsync();

            await _notifications.SendAsync(new NotificationSendRequest
            {
                UserId = proposal.UserId,
                Type = proposal.ProposalType == CurrentWeekAdjustment
                    ? "midweek_plan_proposal"
                    : "next_week_plan_proposal",
                Title = proposal.ProposalType == CurrentWeekAdjustment
                    ? "PT đề xuất điều chỉnh phần còn lại của tuần"
                    : "Lộ trình tuần mới đang chờ bạn duyệt",
                Body = "Hãy xem trước các món thay đổi và chọn Áp dụng hoặc Từ chối.",
                ActionUrl = $"meal_plan_proposal:{proposal.Id}"
            });

            return await MapAsync(proposal);
        }

        public async Task<MealPlanProposalResponse> GetAsync(Guid actorId, Guid proposalId)
        {
            var proposal = await _unitOfWork.MealPlanProposals.GetByIdAsync(proposalId)
                ?? throw new Exception("Không tìm thấy đề xuất.");
            if (proposal.UserId != actorId && proposal.CoachId != actorId)
            {
                throw new UnauthorizedAccessException("Bạn không có quyền xem đề xuất này.");
            }
            return await MapAsync(proposal);
        }

        public async Task<IEnumerable<MealPlanProposalResponse>> GetMineAsync(
            Guid userId,
            string? status = null)
        {
            var proposals = await _unitOfWork.MealPlanProposals.FindAsync(x =>
                x.UserId == userId &&
                (status == null || x.Status.ToLower() == status.ToLower()));
            var result = new List<MealPlanProposalResponse>();
            foreach (var proposal in proposals.OrderByDescending(x => x.CreatedAt))
            {
                result.Add(await MapAsync(proposal));
            }
            return result;
        }

        public async Task<MealPlanProposalResponse> ApplyAsync(Guid userId, Guid proposalId)
        {
            await using var transaction = await _db.Database.BeginTransactionAsync();
            var proposal = await _db.MealPlanProposals
                .FirstOrDefaultAsync(x => x.Id == proposalId)
                ?? throw new Exception("Không tìm thấy đề xuất.");
            if (proposal.UserId != userId)
            {
                throw new UnauthorizedAccessException("Bạn không có quyền xử lý đề xuất này.");
            }
            if (!proposal.Status.Equals(Pending, StringComparison.OrdinalIgnoreCase))
            {
                throw new Exception("Đề xuất không còn ở trạng thái chờ duyệt.");
            }
            if (proposal.ExpiresAt.HasValue && proposal.ExpiresAt.Value <= DateTime.UtcNow)
            {
                proposal.Status = Expired;
                proposal.ActionedAt = DateTime.UtcNow;
                await _db.SaveChangesAsync();
                await transaction.CommitAsync();
                throw new Exception("Đề xuất giữa tuần đã hết hạn.");
            }

            var items = await _db.MealPlanProposalItems
                .Where(x => x.ProposalId == proposal.Id)
                .OrderBy(x => x.PlannedDate).ThenBy(x => x.SortOrder)
                .ToListAsync();
            if (proposal.ProposalType == CurrentWeekAdjustment)
            {
                await ApplyCurrentWeekAsync(proposal, items);
            }
            else
            {
                await ApplyNextWeekAsync(proposal, items);
            }

            var review = await _db.PtReviewRequests
                .FirstOrDefaultAsync(x => x.Id == proposal.ReviewRequestId);
            if (review != null)
            {
                var healthProfile = await _db.HealthProfiles
                    .FirstOrDefaultAsync(x => x.UserId == userId);
                if (healthProfile != null && review.SuggestedCalorieTarget.HasValue)
                {
                    healthProfile.TargetCalories = review.SuggestedCalorieTarget.Value;
                    if (review.SuggestedProteinTarget.HasValue)
                    {
                        healthProfile.TargetProteinG = review.SuggestedProteinTarget.Value;
                        var remainingCalories = review.SuggestedCalorieTarget.Value
                            - review.SuggestedProteinTarget.Value * 4;
                        if (remainingCalories > 0)
                        {
                            healthProfile.TargetCarbsG = (int)Math.Round(remainingCalories * 0.60 / 4);
                            healthProfile.TargetFatG = (int)Math.Round(remainingCalories * 0.40 / 9);
                        }
                    }
                    else
                    {
                        HealthProfileMetricsCalculator.ApplyMacroTargets(healthProfile);
                    }
                    healthProfile.UpdatedAt = DateTime.UtcNow;
                }

                review.Status = Applied;
                review.ActionedAt = DateTime.UtcNow;
            }

            proposal.Status = Applied;
            proposal.ActionedAt = DateTime.UtcNow;
            proposal.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            await transaction.CommitAsync();
            return await MapAsync(proposal);
        }

        public async Task<MealPlanProposalResponse> RejectAsync(Guid userId, Guid proposalId)
        {
            var proposal = await _unitOfWork.MealPlanProposals.GetByIdAsync(proposalId)
                ?? throw new Exception("Không tìm thấy đề xuất.");
            if (proposal.UserId != userId)
            {
                throw new UnauthorizedAccessException("Bạn không có quyền xử lý đề xuất này.");
            }
            if (!proposal.Status.Equals(Pending, StringComparison.OrdinalIgnoreCase))
            {
                throw new Exception("Đề xuất không còn ở trạng thái chờ duyệt.");
            }
            proposal.Status = Rejected;
            proposal.ActionedAt = DateTime.UtcNow;
            proposal.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.MealPlanProposals.Update(proposal);
            var review = await _unitOfWork.PtReviewRequests.GetByIdAsync(
                proposal.ReviewRequestId);
            if (review != null)
            {
                review.Status = Rejected;
                review.ActionedAt = DateTime.UtcNow;
                _unitOfWork.PtReviewRequests.Update(review);
            }
            await _unitOfWork.CompleteAsync();
            return await MapAsync(proposal);
        }

        public async Task ProcessDeadlineNotificationsAsync(DateTime utcNow)
        {
            var localNow = utcNow.AddHours(7);
            var expectedType = localNow.DayOfWeek switch
            {
                DayOfWeek.Thursday => CurrentWeekAdjustment,
                DayOfWeek.Sunday => NextWeekPlan,
                _ => null
            };
            if (expectedType == null) return;
            var expectedPeriodStart = DateOnly.FromDateTime(localNow).AddDays(1);

            var pending = await _unitOfWork.MealPlanProposals.FindAsync(x =>
                x.Status == Pending &&
                x.ProposalType == expectedType &&
                x.PeriodStart == expectedPeriodStart &&
                x.ReminderSentAt == null);
            foreach (var proposal in pending)
            {
                await _notifications.SendAsync(new NotificationSendRequest
                {
                    UserId = proposal.UserId,
                    Type = "meal_plan_proposal_deadline",
                    Title = "Còn 15 phút để duyệt đề xuất lộ trình",
                    Body = proposal.ProposalType == CurrentWeekAdjustment
                        ? "Đề xuất giữa tuần sẽ hết hạn lúc 00:00. Lộ trình cũ được giữ nếu bạn không xử lý."
                        : "Tuần mới sắp bắt đầu. Hãy xem và duyệt lộ trình PT đã chuẩn bị.",
                    ActionUrl = $"meal_plan_proposal:{proposal.Id}"
                });
                proposal.ReminderSentAt = utcNow;
                proposal.UpdatedAt = utcNow;
                _unitOfWork.MealPlanProposals.Update(proposal);
            }
            await _unitOfWork.CompleteAsync();
        }

        public async Task ExpireOverdueAsync(DateTime utcNow)
        {
            var overdue = await _unitOfWork.MealPlanProposals.FindAsync(x =>
                x.Status == Pending &&
                x.ProposalType == CurrentWeekAdjustment &&
                x.ExpiresAt.HasValue && x.ExpiresAt.Value <= utcNow);
            foreach (var proposal in overdue)
            {
                proposal.Status = Expired;
                proposal.ActionedAt = utcNow;
                proposal.UpdatedAt = utcNow;
                _unitOfWork.MealPlanProposals.Update(proposal);
            }
            await _unitOfWork.CompleteAsync();
        }

        private async Task ApplyCurrentWeekAsync(
            MealPlanProposal proposal,
            List<MealPlanProposalItem> items)
        {
            foreach (var item in items)
            {
                if (item.Action.Equals("Add", StringComparison.OrdinalIgnoreCase))
                {
                    var plan = await GetOrCreateDailyPlanAsync(proposal.UserId, item.PlannedDate);
                    await _db.MealPlanItems.AddAsync(NewMealPlanItem(plan.Id, item));
                    continue;
                }

                var existing = item.ExistingMealPlanItemId.HasValue
                    ? await _db.MealPlanItems.FirstOrDefaultAsync(x =>
                        x.Id == item.ExistingMealPlanItemId.Value &&
                        x.MealPlanHeader != null &&
                        x.MealPlanHeader.UserId == proposal.UserId)
                    : null;
                if (existing == null)
                {
                    throw new Exception("Món nguồn đã thay đổi hoặc không còn tồn tại.");
                }

                if (item.Action.Equals("Remove", StringComparison.OrdinalIgnoreCase))
                {
                    _db.MealPlanItems.Remove(existing);
                }
                else
                {
                    existing.FoodId = item.FoodId;
                    existing.RecipeId = item.RecipeId;
                    existing.MealType = NormalizeMealType(item.MealType);
                    existing.QuantityG = item.QuantityG;
                    existing.TargetCalories = item.TargetCalories;
                    existing.ProteinG = item.ProteinG;
                    existing.CarbsG = item.CarbsG;
                    existing.FatG = item.FatG;
                    existing.IngredientSnapshotJson = item.IngredientSnapshotJson;
                    existing.PlannedDate = item.PlannedDate;
                }
            }
        }

        private async Task ApplyNextWeekAsync(
            MealPlanProposal proposal,
            List<MealPlanProposalItem> items)
        {
            for (var date = proposal.PeriodStart; date <= proposal.PeriodEnd; date = date.AddDays(1))
            {
                var plan = await GetOrCreateDailyPlanAsync(proposal.UserId, date);
                var oldItems = await _db.MealPlanItems
                    .Where(x => x.MealPlanId == plan.Id)
                    .ToListAsync();
                _db.MealPlanItems.RemoveRange(oldItems);
                foreach (var item in items.Where(x => x.PlannedDate == date))
                {
                    await _db.MealPlanItems.AddAsync(NewMealPlanItem(plan.Id, item));
                }
                plan.Status = "Approved";
                plan.ApprovedAt = DateTime.UtcNow;
                plan.UpdatedAt = DateTime.UtcNow;
            }
        }

        private async Task<MealPlanHeader> GetOrCreateDailyPlanAsync(Guid userId, DateOnly date)
        {
            var plan = await _db.MealPlanHeaders
                .Where(x => x.UserId == userId && x.IsActive &&
                    x.StartDate == date && x.EndDate == date)
                .OrderByDescending(x => x.UpdatedAt ?? x.CreatedAt)
                .FirstOrDefaultAsync();
            if (plan != null) return plan;

            plan = new MealPlanHeader
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = $"Lộ trình ngày {date:dd/MM/yyyy}",
                PlanType = "DAILY",
                StartDate = date,
                EndDate = date,
                GeneratedBy = "PT_PROPOSAL",
                Status = "Draft",
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            await _db.MealPlanHeaders.AddAsync(plan);
            return plan;
        }

        private static MealPlanItem NewMealPlanItem(Guid planId, MealPlanProposalItem item) =>
            new()
            {
                Id = Guid.NewGuid(),
                MealPlanId = planId,
                MealType = NormalizeMealType(item.MealType),
                FoodId = item.FoodId,
                RecipeId = item.RecipeId,
                PlannedDate = item.PlannedDate,
                QuantityG = item.QuantityG,
                TargetCalories = item.TargetCalories,
                ProteinG = item.ProteinG,
                CarbsG = item.CarbsG,
                FatG = item.FatG,
                IngredientSnapshotJson = item.IngredientSnapshotJson,
                ScheduledTime = ScheduledTime(item.MealType),
                IsCompleted = false,
                Origin = "coach_proposal",
                CreatedAt = DateTime.UtcNow
            };

        private async Task<MealPlanProposalItem> ValidateAndMapItemAsync(
            MealPlanProposal proposal,
            MealPlanProposalItemRequest input)
        {
            if (input.PlannedDate < proposal.PeriodStart || input.PlannedDate > proposal.PeriodEnd)
            {
                throw new Exception("Ngày điều chỉnh nằm ngoài phạm vi proposal.");
            }
            if (input.FoodId.HasValue && input.RecipeId.HasValue)
            {
                throw new Exception("Mỗi mục chỉ được chọn món ăn hoặc công thức.");
            }

            var action = NormalizeAction(input.Action);
            if (proposal.ProposalType == NextWeekPlan)
            {
                action = "Add";
                if (!input.FoodId.HasValue && !input.RecipeId.HasValue)
                {
                    throw new Exception("Mỗi món trong lộ trình tuần mới phải có món ăn hoặc công thức.");
                }
            }
            else if (action == "Add")
            {
                if (!input.FoodId.HasValue && !input.RecipeId.HasValue)
                {
                    throw new Exception("Thêm món phải chọn món ăn hoặc công thức.");
                }
            }
            else
            {
                if (!input.ExistingMealPlanItemId.HasValue)
                {
                    throw new Exception("Thay/Bỏ phải chọn chính xác món đang có trong lộ trình.");
                }
                var existing = await _unitOfWork.MealPlanItems.GetByIdAsync(
                    input.ExistingMealPlanItemId.Value);
                var header = existing == null
                    ? null
                    : await _unitOfWork.MealPlanHeaders.GetByIdAsync(existing.MealPlanId);
                if (existing == null || header?.UserId != proposal.UserId ||
                    existing.PlannedDate != input.PlannedDate)
                {
                    throw new Exception("Món được chọn không thuộc đúng Gymer hoặc ngày áp dụng.");
                }
                if (action == "Replace" && !input.FoodId.HasValue && !input.RecipeId.HasValue)
                {
                    throw new Exception("Thay món phải chọn món ăn hoặc công thức mới.");
                }
            }

            var mapped = new MealPlanProposalItem
            {
                Id = Guid.NewGuid(),
                ProposalId = proposal.Id,
                Action = action,
                PlannedDate = input.PlannedDate,
                MealType = NormalizeMealType(input.MealType),
                ExistingMealPlanItemId = input.ExistingMealPlanItemId,
                FoodId = action == "Remove" ? null : input.FoodId,
                RecipeId = action == "Remove" ? null : input.RecipeId,
                QuantityG = input.QuantityG,
                TargetCalories = input.TargetCalories,
                SortOrder = input.SortOrder,
                CreatedAt = DateTime.UtcNow
            };

            if (!action.Equals("Remove", StringComparison.OrdinalIgnoreCase))
            {
                if (input.RecipeId.HasValue)
                    await ApplyRecipeNutritionAsync(mapped, input.RecipeId.Value, input.Ingredients);
                else if (input.FoodId.HasValue)
                    await ApplyFoodNutritionAsync(mapped, input.FoodId.Value, input.QuantityG);
            }

            return mapped;
        }

        private async Task<List<MealPlanProposalItem>> BuildNextWeekDraftItemsAsync(
            PtReviewRequest review,
            MealPlanProposal proposal)
        {
            // Prefer a plan the PT has already prepared for next week. When it
            // does not exist, use the current week as the editable baseline.
            var sourceItems = await GetPlanItemsAsync(
                review.UserId,
                proposal.PeriodStart,
                proposal.PeriodEnd);
            var dateOffset = 0;
            if (sourceItems.Count == 0)
            {
                sourceItems = await GetPlanItemsAsync(
                    review.UserId,
                    review.WeekStartDate,
                    review.WeekStartDate.AddDays(6));
                dateOffset = 7;
            }
            var dailyTarget = review.SuggestedCalorieTarget;
            var result = new List<MealPlanProposalItem>();

            foreach (var group in sourceItems
                .Where(x => x.PlannedDate.HasValue)
                .GroupBy(x => x.PlannedDate))
            {
                var currentCalories = group.Sum(x => x.TargetCalories ?? 0);
                var ratio = dailyTarget.HasValue && currentCalories > 0
                    ? (decimal)dailyTarget.Value / currentCalories
                    : 1m;
                foreach (var source in group)
                {
                    var draftItem = new MealPlanProposalItem
                    {
                        Id = Guid.NewGuid(),
                        ProposalId = proposal.Id,
                        Action = "Add",
                        PlannedDate = source.PlannedDate!.Value.AddDays(dateOffset),
                        MealType = NormalizeMealType(source.MealType ?? "snack"),
                        FoodId = source.FoodId,
                        RecipeId = source.RecipeId,
                        SortOrder = MealOrder(source.MealType),
                        CreatedAt = DateTime.UtcNow
                    };

                    var sourceSnapshot = _portionCalculator.Deserialize(source.IngredientSnapshotJson);
                    if (sourceSnapshot != null)
                    {
                        ApplyCalculation(draftItem, _portionCalculator.Scale(sourceSnapshot, ratio));
                    }
                    else if (source.RecipeId.HasValue)
                    {
                        var calculation = await _portionCalculator.CalculateRecipeAsync(source.RecipeId.Value);
                        ApplyCalculation(draftItem, _portionCalculator.Scale(calculation, ratio));
                    }
                    else if (source.FoodId.HasValue)
                    {
                        var baseQuantity = source.QuantityG is > 0 ? source.QuantityG.Value : (decimal?)null;
                        var calculation = await _portionCalculator.CalculateFoodAsync(source.FoodId.Value, baseQuantity);
                        ApplyCalculation(draftItem, _portionCalculator.Scale(calculation, ratio));
                    }
                    else
                    {
                        draftItem.QuantityG = source.QuantityG;
                        draftItem.TargetCalories = source.TargetCalories.HasValue
                            ? (int)Math.Round(source.TargetCalories.Value * ratio)
                            : null;
                        draftItem.ProteinG = source.ProteinG.HasValue ? source.ProteinG * ratio : null;
                        draftItem.CarbsG = source.CarbsG.HasValue ? source.CarbsG * ratio : null;
                        draftItem.FatG = source.FatG.HasValue ? source.FatG * ratio : null;
                    }
                    result.Add(draftItem);
                }
            }
            return result;
        }

        private async Task ApplyRecipeNutritionAsync(
            MealPlanProposalItem item,
            Guid recipeId,
            IReadOnlyCollection<MealPlanIngredientPortionRequest>? ingredients)
        {
            var calculation = await _portionCalculator.CalculateRecipeAsync(recipeId, ingredients);
            ApplyCalculation(item, calculation);
        }

        private async Task ApplyFoodNutritionAsync(
            MealPlanProposalItem item,
            Guid foodId,
            decimal? quantityG)
        {
            var calculation = await _portionCalculator.CalculateFoodAsync(foodId, quantityG);
            ApplyCalculation(item, calculation);
        }

        private void ApplyCalculation(MealPlanProposalItem item, PortionNutritionResponse calculation)
        {
            item.QuantityG = calculation.QuantityG;
            item.TargetCalories = (int)Math.Round(calculation.CaloriesKcal, MidpointRounding.AwayFromZero);
            item.ProteinG = calculation.ProteinG;
            item.CarbsG = calculation.CarbsG;
            item.FatG = calculation.FatG;
            item.IngredientSnapshotJson = calculation.Ingredients.Count == 0
                ? null
                : _portionCalculator.Serialize(calculation);
        }

        private async Task<List<MealPlanItem>> GetPlanItemsAsync(
            Guid userId,
            DateOnly from,
            DateOnly to)
        {
            var plans = (await _unitOfWork.MealPlanHeaders.FindAsync(x =>
                x.UserId == userId && x.IsActive &&
                x.StartDate <= to && x.EndDate >= from)).ToList();
            if (plans.Count == 0) return new List<MealPlanItem>();
            var ids = plans.Select(x => x.Id).ToList();
            return (await _unitOfWork.MealPlanItems.FindAsync(x =>
                ids.Contains(x.MealPlanId) && x.PlannedDate >= from && x.PlannedDate <= to))
                .ToList();
        }

        private async Task<DateTime?> GetSourcePlanVersionAsync(
            Guid userId,
            DateOnly from,
            DateOnly to)
        {
            var plans = await _unitOfWork.MealPlanHeaders.FindAsync(x =>
                x.UserId == userId && x.IsActive &&
                x.StartDate <= to && x.EndDate >= from);
            return plans
                .Select(x => x.UpdatedAt ?? x.CreatedAt)
                .Where(x => x.HasValue)
                .OrderByDescending(x => x)
                .FirstOrDefault();
        }

        private async Task<MealPlanProposalResponse> MapAsync(MealPlanProposal proposal)
        {
            var items = (await _unitOfWork.MealPlanProposalItems.FindAsync(
                x => x.ProposalId == proposal.Id)).OrderBy(x => x.PlannedDate)
                .ThenBy(x => x.SortOrder).ToList();
            var sourceMeals = proposal.ProposalType == CurrentWeekAdjustment
                ? await GetPlanItemsAsync(proposal.UserId, proposal.PeriodStart, proposal.PeriodEnd)
                : new List<MealPlanItem>();

            var foodIds = items.Where(x => x.FoodId.HasValue).Select(x => x.FoodId!.Value)
                .Concat(sourceMeals.Where(x => x.FoodId.HasValue).Select(x => x.FoodId!.Value))
                .Distinct().ToList();
            var recipeIds = items.Where(x => x.RecipeId.HasValue).Select(x => x.RecipeId!.Value)
                .Concat(sourceMeals.Where(x => x.RecipeId.HasValue).Select(x => x.RecipeId!.Value))
                .Distinct().ToList();
            var foods = (await _unitOfWork.Foods.FindAsync(x => foodIds.Contains(x.Id)))
                .ToDictionary(x => x.Id);
            var recipes = (await _unitOfWork.Recipes.FindAsync(x => recipeIds.Contains(x.Id)))
                .ToDictionary(x => x.Id);

            string Name(Guid? foodId, Guid? recipeId) =>
                foodId.HasValue && foods.TryGetValue(foodId.Value, out var food)
                    ? food.NameVi ?? food.NameEn ?? "Món ăn"
                    : recipeId.HasValue && recipes.TryGetValue(recipeId.Value, out var recipe)
                        ? recipe.Title ?? "Công thức"
                        : "Chưa chọn món";

            return new MealPlanProposalResponse
            {
                Id = proposal.Id,
                UserId = proposal.UserId,
                CoachId = proposal.CoachId,
                ReviewRequestId = proposal.ReviewRequestId,
                ProposalType = proposal.ProposalType,
                Status = proposal.Status,
                PeriodStart = proposal.PeriodStart,
                PeriodEnd = proposal.PeriodEnd,
                ExpiresAt = proposal.ExpiresAt,
                ReminderSentAt = proposal.ReminderSentAt,
                CreatedAt = proposal.CreatedAt,
                SubmittedAt = proposal.SubmittedAt,
                ActionedAt = proposal.ActionedAt,
                Items = items.Select(x => new MealPlanProposalItemResponse
                {
                    Id = x.Id,
                    Action = x.Action,
                    PlannedDate = x.PlannedDate,
                    MealType = x.MealType,
                    ExistingMealPlanItemId = x.ExistingMealPlanItemId,
                    FoodId = x.FoodId,
                    RecipeId = x.RecipeId,
                    DisplayName = Name(x.FoodId, x.RecipeId),
                    QuantityG = x.QuantityG,
                    TargetCalories = x.TargetCalories,
                    ProteinG = x.ProteinG,
                    CarbsG = x.CarbsG,
                    FatG = x.FatG,
                    Ingredients = SnapshotIngredients(x.IngredientSnapshotJson),
                    SortOrder = x.SortOrder
                }).ToList(),
                SourceMeals = sourceMeals.Select(x => new ProposalSourceMealResponse
                {
                    MealPlanItemId = x.Id,
                    PlannedDate = x.PlannedDate ?? proposal.PeriodStart,
                    MealType = NormalizeMealType(x.MealType ?? "snack"),
                    FoodId = x.FoodId,
                    RecipeId = x.RecipeId,
                    DisplayName = Name(x.FoodId, x.RecipeId),
                    QuantityG = x.QuantityG,
                    TargetCalories = x.TargetCalories,
                    ProteinG = x.ProteinG,
                    CarbsG = x.CarbsG,
                    FatG = x.FatG,
                    Ingredients = SnapshotIngredients(x.IngredientSnapshotJson)
                }).ToList()
            };
        }

        private List<PortionIngredientResponse> SnapshotIngredients(string? json) =>
            _portionCalculator.Deserialize(json)?.Ingredients ?? new List<PortionIngredientResponse>();

        private async Task<MealPlanProposal> GetCoachProposalAsync(Guid coachId, Guid proposalId)
        {
            var proposal = await _unitOfWork.MealPlanProposals.GetByIdAsync(proposalId)
                ?? throw new Exception("Không tìm thấy đề xuất.");
            if (proposal.CoachId != coachId)
            {
                throw new UnauthorizedAccessException("Bạn không có quyền sửa đề xuất này.");
            }
            await EnsureConnectedAsync(coachId, proposal.UserId);
            return proposal;
        }

        private async Task EnsureConnectedAsync(Guid coachId, Guid userId)
        {
            var connected = await _unitOfWork.CoachConnections.FindAsync(x =>
                x.CoachId == coachId && x.ClientId == userId &&
                (x.Status == "Connected" || x.Status == "Approved"));
            if (!connected.Any())
            {
                throw new UnauthorizedAccessException("PT không còn kết nối với Gymer này.");
            }
        }

        private static string GetRequestType(string json)
        {
            try
            {
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty("requestType", out var camel))
                    return camel.GetString() ?? string.Empty;
                if (doc.RootElement.TryGetProperty("RequestType", out var pascal))
                    return pascal.GetString() ?? string.Empty;
            }
            catch { }
            return string.Empty;
        }

        private static DateTime VietnamMidnightToUtc(DateOnly localDate) =>
            localDate.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc).AddHours(-7);

        private static string NormalizeAction(string action) =>
            action.Trim().ToLowerInvariant() switch
            {
                "add" => "Add",
                "replace" => "Replace",
                "remove" => "Remove",
                _ => throw new Exception("Hành động phải là Add, Replace hoặc Remove.")
            };

        private static string NormalizeMealType(string mealType) =>
            mealType.Trim().ToLowerInvariant() switch
            {
                "breakfast" or "bữa sáng" or "bua sang" => "breakfast",
                "lunch" or "bữa trưa" or "bua trua" => "lunch",
                "dinner" or "bữa tối" or "bua toi" => "dinner",
                "snack" or "bữa phụ" or "bua phu" => "snack",
                _ => throw new Exception("Loại bữa ăn không hợp lệ.")
            };

        private static TimeOnly ScheduledTime(string mealType) =>
            NormalizeMealType(mealType) switch
            {
                "breakfast" => new TimeOnly(7, 30),
                "lunch" => new TimeOnly(12, 0),
                "dinner" => new TimeOnly(18, 30),
                _ => new TimeOnly(15, 0)
            };

        private static int MealOrder(string? mealType) =>
            (mealType ?? string.Empty).Trim().ToLowerInvariant() switch
            {
                "breakfast" => 0,
                "lunch" => 1,
                "snack" => 2,
                "dinner" => 3,
                _ => 4
            };
    }
}
