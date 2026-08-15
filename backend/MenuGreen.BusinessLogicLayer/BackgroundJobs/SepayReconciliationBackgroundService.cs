using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace MenuGreen.BusinessLogicLayer.BackgroundJobs
{
    public class SepayReconciliationBackgroundService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<SepayReconciliationBackgroundService> _logger;
        private readonly IConfiguration _configuration;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly TimeSpan _interval = TimeSpan.FromMinutes(15); // Run every 15 minutes

        public SepayReconciliationBackgroundService(
            IServiceProvider serviceProvider,
            IConfiguration configuration,
            ILogger<SepayReconciliationBackgroundService> logger,
            IHttpClientFactory httpClientFactory)
        {
            _serviceProvider = serviceProvider;
            _configuration = configuration;
            _logger = logger;
            _httpClientFactory = httpClientFactory;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("SepayReconciliationBackgroundService started. Running every {Interval}.", _interval);

            try
            {
                while (!stoppingToken.IsCancellationRequested)
                {
                    try
                    {
                        await ReconcilePaymentsAsync(stoppingToken);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error occurred during SePay payment reconciliation.");
                    }

                    await Task.Delay(_interval, stoppingToken);
                }
            }
            catch (OperationCanceledException)
            {
                // Normal shutdown, ignore
            }

            _logger.LogInformation("SepayReconciliationBackgroundService stopped.");
        }

        public async Task ReconcilePaymentsAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Starting SePay payment reconciliation scan... ");
            using var scope = _serviceProvider.CreateScope();
            var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
            var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

            // 1. Get all pending SePay payments
            var pendingPayments = await unitOfWork.Payments.FindAsync(
                p => p.Provider == "SEPAY" && p.Status == "Pending" && p.ProviderOrderCode != null);

            var pendingList = pendingPayments.ToList();
            if (pendingList.Count == 0)
            {
                _logger.LogInformation("No pending SePay payments to reconcile.");
                return;
            }

            _logger.LogInformation("Found {Count} pending SePay payment(s) to check.", pendingList.Count);

            var sepayApiKey = _configuration["Sepay:ApiKey"];
            var hasRealApiKey = !string.IsNullOrEmpty(sepayApiKey) && sepayApiKey != "mock_key";

            List<SepayTransactionDto> remoteTransactions = new();

            if (hasRealApiKey)
            {
                // In production: pull transaction history from SePay API
                try
                {
                    using var client = _httpClientFactory.CreateClient(nameof(SepayReconciliationBackgroundService));
                    client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", sepayApiKey);
                    var response = await client.GetAsync("https://api.sepay.vn/v1/tb/transactions", stoppingToken);
                    if (response.IsSuccessStatusCode)
                    {
                        var result = await response.Content.ReadFromJsonAsync<SepayTransactionListApiResponse>(cancellationToken: stoppingToken);
                        if (result?.Transactions != null)
                        {
                            remoteTransactions = result.Transactions;
                        }
                    }
                    else
                    {
                        _logger.LogWarning("Failed to fetch transaction history from SePay API. Status: {StatusCode}", response.StatusCode);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred while calling SePay API.");
                }
            }

            // 2. Loop through each pending payment and attempt matching
            foreach (var payment in pendingList)
            {
                if (stoppingToken.IsCancellationRequested) break;

                try
                {
                    var orderCode = payment.ProviderOrderCode!;
                    bool isPaid = false;
                    string? transactionNo = null;

                    // Match logic:
                    // A. Match via SePay API if we pulled transactions
                    var matchingRemote = remoteTransactions.FirstOrDefault(t => 
                        !string.IsNullOrEmpty(t.TransactionContent) && 
                        t.TransactionContent.Contains(orderCode, StringComparison.OrdinalIgnoreCase));

                    if (matchingRemote != null)
                    {
                        isPaid = true;
                        transactionNo = matchingRemote.Id.ToString();
                    }
                    else
                    {
                        // B. Fallback/Local match: check if a SepayTransaction record was created in our database
                        // but failed to link due to webhook execution errors.
                        var localTx = (await unitOfWork.SepayTransactions.FindAsync(tx => 
                            tx.TransferContent != null && 
                            tx.TransferContent.Contains(orderCode))).FirstOrDefault();

                        if (localTx != null)
                        {
                            isPaid = true;
                            transactionNo = localTx.TransactionCode ?? localTx.Id.ToString();
                        }
                    }

                    // C. Development fallback: auto-complete expired test orders after 10 mins (only for local mock testing if enabled)
                    var isDevMode = _configuration["Environment"] == "Development" || _configuration["ASPNETCORE_ENVIRONMENT"] == "Development";
                    if (!isPaid && isDevMode && _configuration.GetValue<bool>("Sepay:AutoApprovePendingInDev"))
                    {
                        var elapsed = DateTime.UtcNow - payment.CreatedAt;
                        if (elapsed > TimeSpan.FromMinutes(10))
                        {
                            isPaid = true;
                            transactionNo = "MOCK_TX_" + Guid.NewGuid().ToString("N").Substring(0, 10).ToUpper();
                            _logger.LogInformation("Dev Mode: Auto-approving expired pending payment {PaymentId} for testing.", payment.Id);
                        }
                    }

                    if (isPaid)
                    {
                        // 3. Process payment success
                        _logger.LogInformation("Matching payment found for order {OrderCode}. Processing upgrade...", orderCode);
                        
                        payment.Status = "Success";
                        payment.PaidAt = DateTime.UtcNow;
                        unitOfWork.Payments.Update(payment);

                        // Upgrade user subscription
                        if (payment.UserSubscriptionId.HasValue)
                        {
                            var subscription = await unitOfWork.UserSubscriptions.GetByIdAsync(payment.UserSubscriptionId.Value);
                            if (subscription != null)
                            {
                                var plan = await unitOfWork.SubscriptionPlans.GetByIdAsync(subscription.SubscriptionPlanId);
                                var durationDays = plan?.DurationDays is > 0
                                    ? plan.DurationDays.Value
                                    : string.Equals(plan?.FeatureGroup, "office", StringComparison.OrdinalIgnoreCase) ||
                                      string.Equals(plan?.Name, "Office", StringComparison.OrdinalIgnoreCase)
                                        ? 1
                                        : 30;

                                subscription.Status = "Active";
                                subscription.StartDate = DateTime.UtcNow;
                                subscription.EndDate = DateTime.UtcNow.AddDays(durationDays);
                                subscription.UpdatedAt = DateTime.UtcNow;
                                unitOfWork.UserSubscriptions.Update(subscription);

                                // Create transaction record
                                var tx = new SubscriptionTransaction
                                {
                                    Id = Guid.NewGuid(),
                                    UserId = payment.UserId,
                                    UserSubscriptionId = subscription.Id,
                                    TransactionType = "Reconciliation_Upgrade",
                                    Amount = payment.AmountVnd,
                                    Status = "Success",
                                    Note = $"Reconciliation payment order {orderCode}",
                                    TransactionDate = DateTime.UtcNow,
                                    CreatedAt = DateTime.UtcNow
                                };
                                await unitOfWork.SubscriptionTransactions.AddAsync(tx);

                                // Upgrade user role to Office when purchasing an Office plan
                                if (string.Equals(plan?.FeatureGroup, "office", StringComparison.OrdinalIgnoreCase) ||
                                    string.Equals(plan?.Name, "Office", StringComparison.OrdinalIgnoreCase))
                                {
                                    var user = await unitOfWork.Users.GetByIdAsync(subscription.UserId);
                                    if (user != null)
                                    {
                                        var officeRole = (await unitOfWork.Roles.FindAsync(r => r.Name == "Office")).FirstOrDefault();
                                        if (officeRole != null && user.RoleId != officeRole.Id)
                                        {
                                            user.RoleId = officeRole.Id;
                                            user.UpdatedAt = DateTime.UtcNow;
                                            unitOfWork.Users.Update(user);
                                        }
                                    }
                                }

                                // Notify user
                                var notifRequest = new NotificationSendRequest
                                {
                                    UserId = payment.UserId,
                                    Type = "payment_reconciled",
                                    Title = "Thanh toán đối soát thành công",
                                    Body = $"Giao dịch đơn hàng {orderCode} của bạn đã được đối soát thành công. Tài khoản đã nâng cấp lên gói {plan?.Name ?? "VIP"}!",
                                    ScheduledAt = DateTime.UtcNow
                                };
                                await notificationService.SendAsync(notifRequest);
                            }
                        }

                        await unitOfWork.CompleteAsync();
                        _logger.LogInformation("Successfully reconciled and upgraded user subscription for payment {PaymentId}.", payment.Id);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing reconciliation for payment {PaymentId}.", payment.Id);
                }
            }

            _logger.LogInformation("SePay payment reconciliation scan finished.");
        }
    }

    public class SepayTransactionListApiResponse
    {
        public List<SepayTransactionDto>? Transactions { get; set; }
    }

    public class SepayTransactionDto
    {
        public long Id { get; set; }
        public string? TransactionDate { get; set; }
        public string? AccountNumber { get; set; }
        public decimal AmountIn { get; set; }
        public decimal AmountOut { get; set; }
        public string? TransactionContent { get; set; }
        public string? ReferenceNumber { get; set; }
    }
}
