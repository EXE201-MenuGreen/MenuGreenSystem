using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Helpers;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class AdminMembershipService : IAdminMembershipService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INotificationService _notificationService;
        private readonly ICacheService _cache;

        public AdminMembershipService(
            IUnitOfWork unitOfWork,
            INotificationService notificationService,
            ICacheService cache)
        {
            _unitOfWork = unitOfWork;
            _notificationService = notificationService;
            _cache = cache;
        }

        public async Task<AdminUserMembershipResponse> GetAsync(Guid userId)
        {
            await EnsureUserAsync(userId);
            return await BuildResponseAsync(userId);
        }

        public async Task<AdminUserMembershipResponse> GrantAsync(
            Guid adminUserId,
            Guid userId,
            AdminGrantMembershipRequest request)
        {
            var user = await EnsureUserAsync(userId);
            if (!user.IsActive) throw new InvalidOperationException("Cannot grant a plan to a locked account.");

            var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(request.SubscriptionPlanId)
                ?? throw new InvalidOperationException("Subscription plan not found.");
            if (plan.IsActive == false) throw new InvalidOperationException("Subscription plan is inactive.");
            if (IsBaselineFreePlan(plan))
                throw new InvalidOperationException("The Free plan is available by default and must not be granted as a subscription.");

            var now = DateTime.UtcNow;
            var existing = await _unitOfWork.UserSubscriptions.FindAsync(x =>
                x.UserId == userId && x.SubscriptionPlanId == plan.Id);
            if (existing.Any(x =>
                (string.Equals(x.Status, "Active", StringComparison.OrdinalIgnoreCase) && x.EndDate > now) ||
                string.Equals(x.Status, "PendingPayment", StringComparison.OrdinalIgnoreCase)))
            {
                throw new InvalidOperationException("The account already has this plan active or pending payment.");
            }

            var startDate = NormalizeUtc(request.StartDate ?? now);
            if (startDate < now.AddDays(-1))
                throw new InvalidOperationException("Start date cannot be more than one day in the past.");

            var subscription = new UserSubscription
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                SubscriptionPlanId = plan.Id,
                Status = "Active",
                StartDate = startDate,
                EndDate = startDate.AddDays(request.DurationDays),
                CreatedAt = now,
                UpdatedAt = now
            };

            await _unitOfWork.UserSubscriptions.AddAsync(subscription);
            await _unitOfWork.SubscriptionTransactions.AddAsync(new SubscriptionTransaction
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                UserSubscriptionId = subscription.Id,
                UserSubscription = subscription,
                TransactionType = "AdminGrant",
                Amount = 0,
                Status = "Success",
                Note = BuildTransactionNote(adminUserId, request.Note),
                TransactionDate = now,
                CreatedAt = now
            });
            await AddAuditAsync(adminUserId, "AdminGrantMembership", subscription.Id, new
            {
                TargetUserId = userId,
                PlanId = plan.Id,
                PlanName = plan.Name,
                request.DurationDays,
                StartDate = startDate,
                request.Note
            });
            await _unitOfWork.CompleteAsync();
            await AfterMembershipChangedAsync(userId, "Gói dịch vụ đã được cấp", $"Quản trị viên đã cấp gói {plan.Name} cho tài khoản của bạn.");
            return await BuildResponseAsync(userId);
        }

        public async Task<AdminUserMembershipResponse> ExtendAsync(
            Guid adminUserId,
            Guid userId,
            Guid subscriptionId,
            AdminExtendMembershipRequest request)
        {
            await EnsureUserAsync(userId);
            var subscription = await GetOwnedSubscriptionAsync(userId, subscriptionId);
            if (string.Equals(subscription.Status, "Cancelled", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(subscription.Status, "PendingPayment", StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Cancelled or pending subscriptions cannot be extended.");
            }

            var now = DateTime.UtcNow;
            var baseDate = subscription.EndDate > now ? subscription.EndDate : now;
            subscription.EndDate = baseDate.AddDays(request.DurationDays);
            subscription.Status = "Active";
            subscription.RenewedAt = now;
            subscription.UpdatedAt = now;
            _unitOfWork.UserSubscriptions.Update(subscription);

            await _unitOfWork.SubscriptionTransactions.AddAsync(new SubscriptionTransaction
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                UserSubscriptionId = subscription.Id,
                TransactionType = "AdminExtend",
                Amount = 0,
                Status = "Success",
                Note = BuildTransactionNote(adminUserId, request.Note),
                TransactionDate = now,
                CreatedAt = now
            });
            await AddAuditAsync(adminUserId, "AdminExtendMembership", subscription.Id, new
            {
                TargetUserId = userId,
                request.DurationDays,
                NewEndDate = subscription.EndDate,
                request.Note
            });
            await _unitOfWork.CompleteAsync();
            await AfterMembershipChangedAsync(userId, "Gói dịch vụ đã được gia hạn", $"Gói của bạn được gia hạn thêm {request.DurationDays} ngày.");
            return await BuildResponseAsync(userId);
        }

        public async Task<AdminUserMembershipResponse> RevokeAsync(
            Guid adminUserId,
            Guid userId,
            Guid subscriptionId,
            AdminRevokeMembershipRequest request)
        {
            await EnsureUserAsync(userId);
            var subscription = await GetOwnedSubscriptionAsync(userId, subscriptionId);
            if (string.Equals(subscription.Status, "Cancelled", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Subscription is already cancelled.");

            var now = DateTime.UtcNow;
            subscription.Status = "Cancelled";
            subscription.CancelledAt = now;
            subscription.UpdatedAt = now;
            _unitOfWork.UserSubscriptions.Update(subscription);

            var pendingPayments = await _unitOfWork.Payments.FindAsync(x =>
                x.UserSubscriptionId == subscription.Id && x.Status == "PENDING" && x.Provider == "SEPAY");
            foreach (var payment in pendingPayments)
            {
                payment.Status = "CANCELLED";
                payment.UpdatedAt = DateTimeOffset.UtcNow;
                _unitOfWork.Payments.Update(payment);
            }

            await _unitOfWork.SubscriptionTransactions.AddAsync(new SubscriptionTransaction
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                UserSubscriptionId = subscription.Id,
                TransactionType = "AdminRevoke",
                Amount = 0,
                Status = "Success",
                Note = BuildTransactionNote(adminUserId, request.Reason),
                TransactionDate = now,
                CreatedAt = now
            });
            await AddAuditAsync(adminUserId, "AdminRevokeMembership", subscription.Id, new
            {
                TargetUserId = userId,
                request.Reason
            });
            await _unitOfWork.CompleteAsync();
            await AfterMembershipChangedAsync(userId, "Gói dịch vụ đã bị thu hồi", "Quản trị viên đã thu hồi một gói dịch vụ khỏi tài khoản của bạn.");
            return await BuildResponseAsync(userId);
        }

        private async Task<User> EnsureUserAsync(Guid userId) =>
            await _unitOfWork.Users.GetByIdAsync(userId)
                ?? throw new InvalidOperationException("Account not found.");

        private async Task<UserSubscription> GetOwnedSubscriptionAsync(Guid userId, Guid subscriptionId)
        {
            var subscription = await _unitOfWork.UserSubscriptions.GetByIdAsync(subscriptionId)
                ?? throw new InvalidOperationException("Subscription not found.");
            if (subscription.UserId != userId) throw new UnauthorizedAccessException("Subscription does not belong to this account.");
            return subscription;
        }

        private async Task<AdminUserMembershipResponse> BuildResponseAsync(Guid userId)
        {
            var subscriptions = (await _unitOfWork.UserSubscriptions.FindAsync(x => x.UserId == userId))
                .OrderByDescending(x => x.CreatedAt)
                .ToList();
            var plans = (await _unitOfWork.SubscriptionPlans.GetAllAsync()).ToDictionary(x => x.Id);
            var snapshots = subscriptions.Select(subscription =>
            {
                plans.TryGetValue(subscription.SubscriptionPlanId, out var plan);
                return new SubscriptionAccessSnapshot(
                    subscription.Status,
                    subscription.StartDate,
                    subscription.EndDate,
                    plan?.FeatureGroup,
                    plan?.Name);
            });
            var access = FeatureAccessResolver.Resolve(snapshots, DateTime.UtcNow);
            var items = subscriptions.Select(subscription =>
            {
                plans.TryGetValue(subscription.SubscriptionPlanId, out var plan);
                return new AdminMembershipItemResponse
                {
                    SubscriptionId = subscription.Id,
                    PlanId = subscription.SubscriptionPlanId,
                    PlanName = plan?.Name ?? string.Empty,
                    FeatureGroup = plan?.FeatureGroup ?? string.Empty,
                    Status = subscription.Status,
                    StartDate = subscription.StartDate,
                    EndDate = subscription.EndDate,
                    CancelledAt = subscription.CancelledAt,
                    RenewedAt = subscription.RenewedAt,
                    DaysRemaining = Math.Max(0, (int)Math.Ceiling((subscription.EndDate - DateTime.UtcNow).TotalDays))
                };
            }).ToList();

            return new AdminUserMembershipResponse
            {
                UserId = userId,
                Tier = access.Tier,
                Entitlements = access.Entitlements,
                FeatureGroups = access.FeatureGroups,
                ExpiresAt = access.ExpiresAt,
                Memberships = items
            };
        }

        private async Task AddAuditAsync(Guid adminUserId, string action, Guid subscriptionId, object metadata)
        {
            await _unitOfWork.ActivityLogs.AddAsync(new ActivityLog
            {
                Id = Guid.NewGuid(),
                UserId = adminUserId,
                Action = action,
                EntityType = "UserSubscription",
                EntityId = subscriptionId,
                Metadata = JsonSerializer.Serialize(metadata),
                CreatedAt = DateTimeOffset.UtcNow
            });
        }

        private async Task AfterMembershipChangedAsync(Guid userId, string title, string body)
        {
            await _cache.RemoveAsync(CacheKeys.UserSubscription(userId));
            try
            {
                await _notificationService.SendAsync(new NotificationSendRequest
                {
                    UserId = userId,
                    Type = "admin_membership_changed",
                    Title = title,
                    Body = body,
                    ScheduledAt = DateTimeOffset.UtcNow
                });
            }
            catch
            {
                // Membership changes must not fail because notification delivery failed.
            }
        }

        private static bool IsBaselineFreePlan(SubscriptionPlan plan)
        {
            var group = plan.FeatureGroup?.Trim();
            var name = plan.Name?.Trim();
            return string.Equals(group, "basic", StringComparison.OrdinalIgnoreCase)
                || string.Equals(group, "free", StringComparison.OrdinalIgnoreCase)
                || string.Equals(name, "Cơ bản", StringComparison.OrdinalIgnoreCase)
                || string.Equals(name, "Basic", StringComparison.OrdinalIgnoreCase)
                || string.Equals(name, "Free", StringComparison.OrdinalIgnoreCase);
        }

        private static DateTime NormalizeUtc(DateTime value) =>
            value.Kind == DateTimeKind.Utc ? value : value.ToUniversalTime();

        private static string BuildTransactionNote(Guid adminUserId, string? note) =>
            $"Admin {adminUserId}: {(string.IsNullOrWhiteSpace(note) ? "No note" : note.Trim())}";
    }
}
