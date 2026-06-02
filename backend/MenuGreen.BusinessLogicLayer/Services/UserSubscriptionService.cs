using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class UserSubscriptionService : IUserSubscriptionService
    {
        private const string SepayPaymentRequiredMessage =
            "Paid subscriptions must use SePay. Subscribe: POST /api/payments/sepay/create-order. Renew: POST /api/payments/sepay/create-renew-order.";

        private readonly IUnitOfWork _unitOfWork;

        public UserSubscriptionService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<UserSubscriptionResponse> SubscribeAsync(Guid userId, SubscribeRequest request)
        {
            var plan = await GetActivePlanAsync(request.SubscriptionPlanId);
            if ((plan.PriceVnd ?? 0) > 0)
            {
                throw new InvalidOperationException(SepayPaymentRequiredMessage);
            }

            var now = DateTime.UtcNow;
            var subscription = new UserSubscription
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                SubscriptionPlanId = plan.Id,
                Status = "Active",
                StartDate = now,
                EndDate = now.AddDays(plan.DurationDays ?? 0),
                CreatedAt = now,
                UpdatedAt = now
            };

            await _unitOfWork.UserSubscriptions.AddAsync(subscription);
            await _unitOfWork.SubscriptionTransactions.AddAsync(
                CreateTransaction(userId, subscription.Id, "Subscribe", 0, request.Note ?? "Free plan", now));
            await _unitOfWork.CompleteAsync();

            return await MapAsync(subscription);
        }

        public Task<UserSubscriptionResponse> RenewAsync(Guid userId, RenewSubscriptionRequest request)
        {
            throw new InvalidOperationException(SepayPaymentRequiredMessage);
        }

        public async Task<UserSubscriptionResponse> CancelAsync(Guid userId, CancelSubscriptionRequest request)
        {
            var subscription = await GetOwnedSubscriptionAsync(userId, request.UserSubscriptionId);
            var now = DateTime.UtcNow;

            subscription.Status = "Cancelled";
            subscription.CancelledAt = now;
            subscription.UpdatedAt = now;

            _unitOfWork.UserSubscriptions.Update(subscription);
            await _unitOfWork.SubscriptionTransactions.AddAsync(
                CreateTransaction(userId, subscription.Id, "Cancel", 0, request.Reason, now));
            await _unitOfWork.CompleteAsync();

            return await MapAsync(subscription);
        }

        public async Task<UserSubscriptionResponse?> GetCurrentAsync(Guid userId)
        {
            var subscriptions = await _unitOfWork.UserSubscriptions.FindAsync(x => x.UserId == userId);
            var current = subscriptions
                .Where(x => x.Status is "Active" or "PendingPayment")
                .OrderByDescending(x => x.CreatedAt)
                .FirstOrDefault();

            return current == null ? null : await MapAsync(current);
        }

        public async Task<IEnumerable<SubscriptionTransactionResponse>> GetHistoryAsync(Guid userId)
        {
            var items = await _unitOfWork.SubscriptionTransactions.FindAsync(x => x.UserId == userId);
            return items.OrderByDescending(x => x.TransactionDate).Select(MapTransaction).ToList();
        }

        private async Task<SubscriptionPlan> GetActivePlanAsync(Guid planId)
        {
            var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(planId);
            if (plan == null || plan.IsActive == false)
            {
                throw new Exception("Subscription plan not found or inactive.");
            }

            return plan;
        }

        private async Task<UserSubscription> GetOwnedSubscriptionAsync(Guid userId, Guid subscriptionId)
        {
            var subscription = await _unitOfWork.UserSubscriptions.GetByIdAsync(subscriptionId);
            if (subscription == null) throw new Exception("User subscription not found.");
            if (subscription.UserId != userId) throw new Exception("Forbidden.");
            return subscription;
        }

        private static SubscriptionTransaction CreateTransaction(
            Guid userId,
            Guid subscriptionId,
            string type,
            int amount,
            string? note,
            DateTime time)
        {
            return new SubscriptionTransaction
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                UserSubscriptionId = subscriptionId,
                TransactionType = type,
                Amount = amount,
                Status = "Success",
                Note = note,
                TransactionDate = time,
                CreatedAt = time
            };
        }

        private async Task<UserSubscriptionResponse> MapAsync(UserSubscription subscription)
        {
            var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(subscription.SubscriptionPlanId);
            return new UserSubscriptionResponse
            {
                Id = subscription.Id,
                UserId = subscription.UserId,
                SubscriptionPlanId = subscription.SubscriptionPlanId,
                SubscriptionPlanName = plan?.Name ?? string.Empty,
                Status = subscription.Status,
                StartDate = subscription.StartDate,
                EndDate = subscription.EndDate,
                CancelledAt = subscription.CancelledAt,
                RenewedAt = subscription.RenewedAt,
                DaysRemaining = Math.Max(0, (subscription.EndDate - DateTime.UtcNow).Days)
            };
        }

        private static SubscriptionTransactionResponse MapTransaction(SubscriptionTransaction transaction)
        {
            return new SubscriptionTransactionResponse
            {
                Id = transaction.Id,
                UserId = transaction.UserId,
                UserSubscriptionId = transaction.UserSubscriptionId,
                TransactionType = transaction.TransactionType,
                Amount = transaction.Amount,
                Status = transaction.Status,
                Note = transaction.Note,
                TransactionDate = transaction.TransactionDate,
                CreatedAt = transaction.CreatedAt
            };
        }
    }
}
