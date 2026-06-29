using System;
using System.Threading;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace MenuGreen.BusinessLogicLayer.BackgroundJobs
{
    public class NotificationDispatchBackgroundService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<NotificationDispatchBackgroundService> _logger;
        private readonly TimeSpan _interval = TimeSpan.FromMinutes(1);

        public NotificationDispatchBackgroundService(
            IServiceProvider serviceProvider,
            ILogger<NotificationDispatchBackgroundService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("NotificationDispatchBackgroundService started. Dispatching every {Interval}.",
                _interval);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await DispatchAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in NotificationDispatchBackgroundService dispatch loop.");
                }

                await Task.Delay(_interval, stoppingToken);
            }

            _logger.LogInformation("NotificationDispatchBackgroundService stopped.");
        }

        private async Task DispatchAsync(CancellationToken stoppingToken)
        {
            using var scope = _serviceProvider.CreateScope();
            var dispatcher = scope.ServiceProvider.GetRequiredService<INotificationDispatcherService>();

            try
            {
                var result = await dispatcher.DispatchDueNotificationsAsync();

                if (result.TotalProcessed > 0)
                {
                    _logger.LogInformation(
                        "[NotificationDispatch] {Summary} Processed={Total} Sent={Sent} Failed={Failed} Skipped={Skipped}",
                        result.Summary,
                        result.TotalProcessed,
                        result.PushSent,
                        result.PushFailed,
                        result.Skipped);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to dispatch notifications.");
            }
        }
    }
}
