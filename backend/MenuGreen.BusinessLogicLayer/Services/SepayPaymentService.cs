using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.Extensions.Configuration;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class SepayPaymentService : ISepayPaymentService
    {
        private const string DefaultPaymentCodePrefix = "DH";
        private static readonly JsonSerializerOptions WebhookJsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        private readonly IUnitOfWork _unitOfWork;
        private readonly IConfiguration _configuration;
        private readonly ISepayPaymentStatusCache _statusCache;
        private readonly SepayWebhookHmacValidator _hmacValidator;
        private readonly SepayQrUrlBuilder _qrUrlBuilder;
        private readonly SepayWebhookPaymentVerifier _webhookVerifier;

        public SepayPaymentService(
            IUnitOfWork unitOfWork,
            IConfiguration configuration,
            ISepayPaymentStatusCache statusCache,
            SepayWebhookHmacValidator hmacValidator,
            SepayQrUrlBuilder qrUrlBuilder,
            SepayWebhookPaymentVerifier webhookVerifier)
        {
            _unitOfWork = unitOfWork;
            _configuration = configuration;
            _statusCache = statusCache;
            _hmacValidator = hmacValidator;
            _qrUrlBuilder = qrUrlBuilder;
            _webhookVerifier = webhookVerifier;
        }

        public async Task<SepayOrderResponse> CreateOrderAsync(Guid userId, CreateSepayOrderRequest request)
        {
            var plan = await GetActivePlanAsync(request.SubscriptionPlanId);
            await EnsureNoPendingSepayPaymentAsync(userId);

            var amount = plan.PriceVnd ?? 0;
            if (amount <= 0)
            {
                throw new Exception("This plan is free. Use POST /api/UserSubscription/subscribe instead.");
            }

            var now = DateTime.UtcNow;
            var pendingSubscription = new UserSubscription
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                SubscriptionPlanId = plan.Id,
                Status = "PendingPayment",
                StartDate = now,
                EndDate = now,
                CreatedAt = now,
                UpdatedAt = now
            };

            var providerOrderCode = await GenerateUniqueProviderOrderCodeAsync();
            var payment = BuildPendingPayment(userId, pendingSubscription.Id, amount, providerOrderCode);

            await _unitOfWork.UserSubscriptions.AddAsync(pendingSubscription);
            await _unitOfWork.Payments.AddAsync(payment);
            await _unitOfWork.CompleteAsync();

            return MapOrder(payment);
        }

        public async Task<SepayOrderResponse> CreateRenewOrderAsync(Guid userId, CreateRenewSepayOrderRequest request)
        {
            var subscription = await _unitOfWork.UserSubscriptions.GetByIdAsync(request.UserSubscriptionId);
            if (subscription == null || subscription.UserId != userId)
            {
                throw new Exception("User subscription not found.");
            }

            if (subscription.Status != "Active")
            {
                throw new Exception("Only active subscriptions can be renewed via SePay.");
            }

            var plan = await GetActivePlanAsync(subscription.SubscriptionPlanId);
            await EnsureNoPendingSepayPaymentAsync(userId);

            var amount = plan.PriceVnd ?? 0;
            if (amount <= 0)
            {
                throw new Exception("This plan is free and cannot be renewed via SePay.");
            }

            var providerOrderCode = await GenerateUniqueProviderOrderCodeAsync();
            var payment = BuildPendingPayment(userId, subscription.Id, amount, providerOrderCode);
            await _unitOfWork.Payments.AddAsync(payment);
            await _unitOfWork.CompleteAsync();

            return MapOrder(payment);
        }

        public async Task<SepayOrderResponse> GetOrderStatusAsync(Guid userId, Guid paymentId)
        {
            var cached = await _statusCache.TryGetAsync(userId, paymentId);
            if (cached != null)
            {
                return cached;
            }

            var payment = await _unitOfWork.Payments.GetByIdAsync(paymentId);
            if (payment == null || payment.UserId != userId || payment.Provider != "SEPAY")
            {
                throw new Exception("SePay payment not found.");
            }

            var previousStatus = payment.Status;
            payment = await PaymentExpiryHelper.RefreshPendingExpiryAsync(payment, _unitOfWork);

            if (!string.Equals(previousStatus, payment.Status, StringComparison.OrdinalIgnoreCase))
            {
                await _statusCache.InvalidateAsync(userId, paymentId);
            }

            var response = MapOrder(payment);
            await _statusCache.SetAsync(userId, paymentId, response);
            return response;
        }

        public async Task<SepayPendingOrdersListResponse> GetPendingOrdersAsync(Guid userId)
        {
            var pendingPayments = await RefreshUserPendingSepayPaymentsAsync(userId);
            var items = new List<SepayPendingOrderResponse>();

            foreach (var payment in pendingPayments.OrderByDescending(x => x.CreatedAt))
            {
                items.Add(await MapPendingOrderAsync(payment));
            }

            return new SepayPendingOrdersListResponse { Items = items };
        }

        public async Task CancelOrderAsync(Guid userId, Guid paymentId)
        {
            var payment = await _unitOfWork.Payments.GetByIdAsync(paymentId);
            if (payment == null || payment.UserId != userId)
            {
                throw new Exception("Payment order not found.");
            }

            if (payment.Provider != "SEPAY")
            {
                throw new Exception("Only SePay payments can be cancelled via this endpoint.");
            }

            if (payment.Status == "PAID")
            {
                throw new Exception("Cannot cancel a payment that has already been paid.");
            }

            payment.Status = "CANCELLED";
            payment.UpdatedAt = DateTimeOffset.UtcNow;
            _unitOfWork.Payments.Update(payment);

            // Also cancel the associated pending subscription if exists
            if (payment.UserSubscriptionId.HasValue)
            {
                var subscription = await _unitOfWork.UserSubscriptions.GetByIdAsync(payment.UserSubscriptionId.Value);
                if (subscription != null && subscription.Status == "PendingPayment")
                {
                    subscription.Status = "Cancelled";
                    subscription.UpdatedAt = DateTime.UtcNow;
                    _unitOfWork.UserSubscriptions.Update(subscription);
                }
            }

            await _unitOfWork.CompleteAsync();
            await _statusCache.InvalidateAsync(userId, paymentId);
        }

        public async Task<SepayWebhookResultResponse> ProcessWebhookAsync(
            string rawBody,
            string? signature,
            string? timestamp,
            string? authorizationHeader)
        {
            _hmacValidator.Validate(rawBody, signature, timestamp, authorizationHeader);

            var payload = JsonSerializer.Deserialize<SepayIncomingWebhookPayload>(rawBody, WebhookJsonOptions)
                ?? throw new Exception("Invalid SePay webhook payload.");

            if (payload.Id <= 0)
            {
                throw new Exception("Invalid SePay transaction id.");
            }

            if (!string.Equals(payload.TransferType, "in", StringComparison.OrdinalIgnoreCase))
            {
                return new SepayWebhookResultResponse
                {
                    Processed = true,
                    IsDuplicate = false,
                    Message = "Outgoing transfer ignored."
                };
            }

            var transactionCode = payload.Id.ToString();
            var transferContent = ResolveTransferContent(payload);
            var transferAmount = payload.TransferAmount;

            var existing = await _unitOfWork.SepayTransactions.FindAsync(x => x.TransactionCode == transactionCode);
            if (existing.Any())
            {
                return new SepayWebhookResultResponse
                {
                    Processed = true,
                    IsDuplicate = true,
                    Message = "Duplicate transaction ignored."
                };
            }

            var providerOrderCode = ResolveProviderOrderCode(payload, transferContent);
            if (string.IsNullOrWhiteSpace(providerOrderCode))
            {
                throw new Exception("Transfer content does not contain a valid payment code.");
            }

            var candidatePayments = await _unitOfWork.Payments.FindAsync(
                x => x.Provider == "SEPAY" && x.ProviderOrderCode == providerOrderCode);
            var payment = candidatePayments.OrderByDescending(x => x.CreatedAt).FirstOrDefault();
            if (payment == null)
            {
                throw new Exception("Payment order not found by transfer content.");
            }

            if (payment.Status == "PAID")
            {
                await _statusCache.InvalidateAsync(payment.UserId, payment.Id);
                return new SepayWebhookResultResponse
                {
                    Processed = true,
                    IsDuplicate = true,
                    Message = "Payment already marked as paid.",
                    PaymentId = payment.Id,
                    UserSubscriptionId = payment.UserSubscriptionId,
                    UserPremiumProgramId = payment.UserPremiumProgramId
                };
            }

            payment = await PaymentExpiryHelper.RefreshPendingExpiryAsync(payment, _unitOfWork);
            if (payment.Status == "EXPIRED")
            {
                throw new Exception("Payment order has expired.");
            }

            if (payment.Status != "PENDING")
            {
                throw new Exception($"Payment is not processable in status '{payment.Status}'.");
            }

            _webhookVerifier.Verify(payment, payload, transferContent, transferAmount);

            var transactionTime = ParseSepayTransactionDate(payload.TransactionDate);

            var sepayTransaction = new SepayTransaction
            {
                Id = Guid.NewGuid(),
                PaymentId = payment.Id,
                TransactionCode = transactionCode,
                BankAccount = payload.AccountNumber,
                TransferAmount = transferAmount,
                TransferContent = transferContent,
                TransactionTime = transactionTime,
                Status = "CONFIRMED",
                RawPayloadJson = rawBody,
                CreatedAt = DateTimeOffset.UtcNow
            };

            payment.Status = "PAID";
            payment.PaidAt = transactionTime;
            payment.UpdatedAt = DateTimeOffset.UtcNow;
            _unitOfWork.Payments.Update(payment);
            await _unitOfWork.SepayTransactions.AddAsync(sepayTransaction);

            if (payment.UserSubscriptionId.HasValue)
            {
                await ActivateSubscriptionAfterPaymentAsync(payment);
            }
            else if (payment.UserPremiumProgramId.HasValue)
            {
                await ActivatePremiumProgramAfterPaymentAsync(payment);
            }

            try
            {
                await _unitOfWork.CompleteAsync();
            }
            catch (Exception ex) when (DbExceptionHelper.IsUniqueConstraintViolation(ex))
            {
                await _statusCache.InvalidateAsync(payment.UserId, payment.Id);
                return new SepayWebhookResultResponse
                {
                    Processed = true,
                    IsDuplicate = true,
                    Message = "Duplicate transaction ignored (database constraint).",
                    PaymentId = payment.Id,
                    UserSubscriptionId = payment.UserSubscriptionId,
                    UserPremiumProgramId = payment.UserPremiumProgramId
                };
            }

            await _statusCache.InvalidateAsync(payment.UserId, payment.Id);

            return new SepayWebhookResultResponse
            {
                Processed = true,
                IsDuplicate = false,
                Message = "Webhook processed successfully.",
                PaymentId = payment.Id,
                UserSubscriptionId = payment.UserSubscriptionId,
                UserPremiumProgramId = payment.UserPremiumProgramId
            };
        }

        private async Task ActivatePremiumProgramAfterPaymentAsync(Payment payment)
        {
            var userProgram = await _unitOfWork.UserPremiumPrograms.GetByIdAsync(payment.UserPremiumProgramId!.Value)
                ?? throw new Exception("User premium program registration not found.");

            userProgram.Status = "Paid";
            userProgram.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.UserPremiumPrograms.Update(userProgram);
        }

        private async Task ActivateSubscriptionAfterPaymentAsync(Payment payment)
        {
            var subscription = await _unitOfWork.UserSubscriptions.GetByIdAsync(payment.UserSubscriptionId!.Value)
                ?? throw new Exception("User subscription not found.");

            var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(subscription.SubscriptionPlanId)
                ?? throw new Exception("Subscription plan not found.");

            var now = DateTime.UtcNow;
            var durationDays = plan.DurationDays is > 0
                ? plan.DurationDays.Value
                : string.Equals(plan.FeatureGroup, "office", StringComparison.OrdinalIgnoreCase) ||
                  string.Equals(plan.Name, "Office", StringComparison.OrdinalIgnoreCase)
                    ? 1
                    : 36500;
            var isRenewal = subscription.Status == "Active";

            if (isRenewal)
            {
                var baseDate = subscription.EndDate > now ? subscription.EndDate : now;
                subscription.EndDate = baseDate.AddDays(durationDays);
                subscription.RenewedAt = now;
            }
            else
            {
                subscription.Status = "Active";
                subscription.StartDate = now;
                subscription.EndDate = now.AddDays(durationDays);
                subscription.RenewedAt = now;
            }

            subscription.UpdatedAt = now;
            _unitOfWork.UserSubscriptions.Update(subscription);

            await _unitOfWork.SubscriptionTransactions.AddAsync(new SubscriptionTransaction
            {
                Id = Guid.NewGuid(),
                UserId = subscription.UserId,
                UserSubscriptionId = subscription.Id,
                TransactionType = isRenewal ? "Renew" : "Subscribe",
                Amount = payment.AmountVnd,
                Status = "Success",
                Note = "Paid via SePay webhook",
                TransactionDate = now,
                CreatedAt = now
            });
        }

        private async Task<string> GenerateUniqueProviderOrderCodeAsync()
        {
            const int maxAttempts = 12;
            var prefix = ReadPaymentCodePrefix();
            var suffixLength = ReadPaymentCodeSuffixLength();

            for (var attempt = 0; attempt < maxAttempts; attempt++)
            {
                var code = SepayPaymentCodeHelper.Generate(prefix, suffixLength);
                var existing = await _unitOfWork.Payments.FindAsync(x => x.ProviderOrderCode == code);
                if (!existing.Any())
                {
                    return code;
                }
            }

            throw new Exception("Could not generate a unique SePay payment code. Please try again.");
        }

        private Payment BuildPendingPayment(
            Guid userId,
            Guid userSubscriptionId,
            int amountVnd,
            string providerOrderCode)
        {
            var expiredAt = DateTimeOffset.UtcNow.AddMinutes(ReadOrderExpiryMinutes());

            return new Payment
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                UserSubscriptionId = userSubscriptionId,
                AmountVnd = amountVnd,
                Status = "PENDING",
                PaymentMethod = "SEPAY",
                Provider = "SEPAY",
                ProviderOrderCode = providerOrderCode,
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow,
                ExpiredAt = expiredAt
            };
        }

        private async Task EnsureNoPendingSepayPaymentAsync(Guid userId)
        {
            var stillPending = await RefreshUserPendingSepayPaymentsAsync(userId);

            if (stillPending.Any())
            {
                throw new Exception("You already have a pending SePay payment. Complete or wait for it to expire before creating a new order.");
            }
        }

        private async Task<IReadOnlyList<Payment>> RefreshUserPendingSepayPaymentsAsync(Guid userId)
        {
            var pendingPayments = (await _unitOfWork.Payments.FindAsync(
                x => x.UserId == userId && x.Provider == "SEPAY" && x.Status == "PENDING")).ToList();

            var changed = false;
            foreach (var pending in pendingPayments)
            {
                if (!PaymentExpiryHelper.IsExpired(pending))
                {
                    continue;
                }

                PaymentExpiryHelper.MarkExpired(pending);
                _unitOfWork.Payments.Update(pending);
                changed = true;
            }

            if (changed)
            {
                await _unitOfWork.CompleteAsync();
            }

            return (await _unitOfWork.Payments.FindAsync(
                x => x.UserId == userId && x.Provider == "SEPAY" && x.Status == "PENDING")).ToList();
        }

        private async Task<SepayPendingOrderResponse> MapPendingOrderAsync(Payment payment)
        {
            var order = MapOrder(payment);
            var subscription = payment.UserSubscriptionId.HasValue
                ? await _unitOfWork.UserSubscriptions.GetByIdAsync(payment.UserSubscriptionId.Value)
                : null;

            var planName = string.Empty;
            var planId = Guid.Empty;
            var orderType = "Subscribe";

            if (subscription != null)
            {
                planId = subscription.SubscriptionPlanId;
                orderType = string.Equals(subscription.Status, "PendingPayment", StringComparison.OrdinalIgnoreCase)
                    ? "Subscribe"
                    : "Renew";

                var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(subscription.SubscriptionPlanId);
                planName = plan?.Name ?? string.Empty;
            }

            return new SepayPendingOrderResponse
            {
                PaymentId = order.PaymentId,
                UserSubscriptionId = order.UserSubscriptionId,
                SubscriptionPlanId = planId,
                SubscriptionPlanName = planName,
                OrderType = orderType,
                AmountVnd = order.AmountVnd,
                Status = order.Status,
                ProviderOrderCode = order.ProviderOrderCode,
                TransferContent = order.TransferContent,
                TransferMemo = order.TransferMemo,
                QrImageUrl = order.QrImageUrl,
                Receiver = order.Receiver,
                CreatedAt = payment.CreatedAt,
                ExpiredAt = order.ExpiredAt
            };
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

        private SepayOrderResponse MapOrder(Payment payment)
        {
            var qr = _qrUrlBuilder.Build(payment.AmountVnd, payment.ProviderOrderCode);

            return new SepayOrderResponse
            {
                PaymentId = payment.Id,
                UserSubscriptionId = payment.UserSubscriptionId ?? Guid.Empty,
                AmountVnd = payment.AmountVnd,
                Status = payment.Status,
                ProviderOrderCode = payment.ProviderOrderCode,
                TransferContent = payment.ProviderOrderCode,
                TransferMemo = qr.TransferMemo,
                QrImageUrl = qr.QrImageUrl,
                Receiver = new DTOs.Responses.SepayReceiverInfo
                {
                    BankName = qr.Receiver.BankName,
                    AccountNumber = qr.Receiver.AccountNumber,
                    AccountHolderName = qr.Receiver.AccountHolderName
                },
                ExpiredAt = payment.ExpiredAt ?? payment.CreatedAt.AddMinutes(ReadOrderExpiryMinutes())
            };
        }

        private int ReadOrderExpiryMinutes()
        {
            var value = _configuration["SePay:OrderExpiryMinutes"];
            if (int.TryParse(value, out var minutes) && minutes >= 5 && minutes <= 120)
            {
                return minutes;
            }

            return 30;
        }

        private string? ResolveProviderOrderCode(SepayIncomingWebhookPayload payload, string transferContent)
        {
            var prefix = ReadPaymentCodePrefix();
            var minSuffix = ReadPaymentCodeSuffixMinLength();
            var maxSuffix = ReadPaymentCodeSuffixMaxLength();

            if (!string.IsNullOrWhiteSpace(payload.Code))
            {
                var fromCode = SepayPaymentCodeHelper.TryExtract(payload.Code, prefix, minSuffix, maxSuffix);
                if (!string.IsNullOrWhiteSpace(fromCode))
                {
                    return fromCode;
                }
            }

            return SepayPaymentCodeHelper.TryExtract(transferContent, prefix, minSuffix, maxSuffix);
        }

        private static string ResolveTransferContent(SepayIncomingWebhookPayload payload)
        {
            if (!string.IsNullOrWhiteSpace(payload.Content))
            {
                return payload.Content.Trim();
            }

            if (!string.IsNullOrWhiteSpace(payload.Code))
            {
                return payload.Code.Trim();
            }

            return payload.ReferenceCode?.Trim() ?? string.Empty;
        }

        private static DateTimeOffset ParseSepayTransactionDate(string? transactionDate)
        {
            if (string.IsNullOrWhiteSpace(transactionDate))
            {
                return DateTimeOffset.UtcNow;
            }

            if (DateTime.TryParseExact(
                    transactionDate.Trim(),
                    "yyyy-MM-dd HH:mm:ss",
                    CultureInfo.InvariantCulture,
                    DateTimeStyles.None,
                    out var vietnamLocal))
            {
                // SePay sends Vietnam local time; Npgsql requires UTC offset for timestamptz.
                return new DateTimeOffset(vietnamLocal, TimeSpan.FromHours(7)).ToUniversalTime();
            }

            return DateTimeOffset.UtcNow;
        }

        private string ReadPaymentCodePrefix()
        {
            var prefix = _configuration["SePay:PaymentCodePrefix"]?.Trim();
            return string.IsNullOrWhiteSpace(prefix) ? DefaultPaymentCodePrefix : prefix.ToUpperInvariant();
        }

        private int ReadPaymentCodeSuffixLength()
        {
            var value = _configuration["SePay:PaymentCodeSuffixLength"];
            if (int.TryParse(value, out var length))
            {
                return SepayPaymentCodeHelper.ClampSuffixLength(length);
            }

            return SepayPaymentCodeHelper.DefaultSuffixLength;
        }

        private int ReadPaymentCodeSuffixMinLength()
        {
            var value = _configuration["SePay:PaymentCodeSuffixMinLength"];
            if (int.TryParse(value, out var length))
            {
                return SepayPaymentCodeHelper.ClampSuffixLength(length);
            }

            return SepayPaymentCodeHelper.DefaultSuffixMinLength;
        }

        private int ReadPaymentCodeSuffixMaxLength()
        {
            var value = _configuration["SePay:PaymentCodeSuffixMaxLength"];
            if (int.TryParse(value, out var length))
            {
                return SepayPaymentCodeHelper.ClampSuffixLength(length);
            }

            return SepayPaymentCodeHelper.DefaultSuffixMaxLength;
        }
    }
}
