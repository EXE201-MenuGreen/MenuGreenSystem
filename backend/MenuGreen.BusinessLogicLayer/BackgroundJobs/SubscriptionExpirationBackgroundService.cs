using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace MenuGreen.BusinessLogicLayer.BackgroundJobs
{
    public class SubscriptionExpirationBackgroundService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<SubscriptionExpirationBackgroundService> _logger;
        private readonly int _targetHour = 0;   // 00:01 AM local time
        private readonly int _targetMinute = 1;

        public SubscriptionExpirationBackgroundService(
            IServiceProvider serviceProvider,
            ILogger<SubscriptionExpirationBackgroundService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("SubscriptionExpirationBackgroundService started. Scheduled daily at {Hour:D2}:{Minute:D2}.", _targetHour, _targetMinute);

            while (!stoppingToken.IsCancellationRequested)
            {
                var delay = GetDelayUntilNextRun();
                _logger.LogInformation("Next subscription expiration run in {Delay}.", delay);
                
                try
                {
                    await Task.Delay(delay, stoppingToken);
                    await ExpireSubscriptionsAsync(stoppingToken);
                }
                catch (TaskCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred during subscription expiration processing.");
                    // In case of error, wait 1 minute before trying again to prevent CPU spinning
                    await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
                }
            }

            _logger.LogInformation("SubscriptionExpirationBackgroundService stopped.");
        }

        public async Task ExpireSubscriptionsAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Starting subscription expiration check...");
            using var scope = _serviceProvider.CreateScope();
            var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
            var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

            var now = DateTime.UtcNow;
            var activeSubscriptions = await unitOfWork.UserSubscriptions.FindAsync(
                s => s.Status == "Active" && s.EndDate < now);

            var subscriptionList = activeSubscriptions.ToList();
            if (subscriptionList.Count == 0)
            {
                _logger.LogInformation("No expired subscriptions found.");
                return;
            }

            _logger.LogInformation("Found {Count} expired subscription(s) to process.", subscriptionList.Count);

            foreach (var sub in subscriptionList)
            {
                if (stoppingToken.IsCancellationRequested) break;

                try
                {
                    sub.Status = "Expired";
                    sub.UpdatedAt = now;
                    unitOfWork.UserSubscriptions.Update(sub);

                    var freeRoles = await unitOfWork.Roles.FindAsync(r => r.Name.ToLower() == "free");
                    var freeRole = freeRoles.FirstOrDefault();
                    if (freeRole != null)
                    {
                        var user = await unitOfWork.Users.GetByIdAsync(sub.UserId);
                        if (user != null)
                        {
                            user.RoleId = freeRole.Id;
                            user.UpdatedAt = now;
                            unitOfWork.Users.Update(user);
                        }
                    }

                    // Send alert notification
                    var plan = await unitOfWork.SubscriptionPlans.GetByIdAsync(sub.SubscriptionPlanId);
                    var planName = plan?.Name ?? "VIP";

                    var notifRequest = new NotificationSendRequest
                    {
                        UserId = sub.UserId,
                        Type = "subscription_expired",
                        Title = "Gói đăng ký đã hết hạn",
                        Body = $"Gói {planName} của bạn đã hết hạn. Hãy gia hạn để tiếp tục trải nghiệm đầy đủ các tính năng Pro nhé!",
                        ScheduledAt = now
                    };

                    await notificationService.SendAsync(notifRequest);
                    _logger.LogInformation("Processed expiration for subscription {SubId} of user {UserId}.", sub.Id, sub.UserId);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing expiration for subscription {SubId}.", sub.Id);
                }
            }

            await unitOfWork.CompleteAsync();
            _logger.LogInformation("Subscription expiration process completed successfully.");
        }

        private TimeSpan GetDelayUntilNextRun()
        {
            var nowLocal = DateTime.Now;
            var nextRun = nowLocal.Date.AddHours(_targetHour).AddMinutes(_targetMinute);
            if (nowLocal >= nextRun)
            {
                nextRun = nextRun.AddDays(1);
            }
            return nextRun - nowLocal;
        }
    }
}
