using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace MenuGreen.BusinessLogicLayer.BackgroundJobs
{
    public class DailyStarterBackgroundService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<DailyStarterBackgroundService> _logger;
        private readonly int _targetHour = 1;    // 01:00 AM local time
        private readonly int _targetMinute = 0;

        public DailyStarterBackgroundService(
            IServiceProvider serviceProvider,
            ILogger<DailyStarterBackgroundService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("DailyStarterBackgroundService started. Scheduled daily at {Hour:D2}:{Minute:D2}.", _targetHour, _targetMinute);

            while (!stoppingToken.IsCancellationRequested)
            {
                var delay = GetDelayUntilNextRun();
                _logger.LogInformation("Next daily starter pre-calculation in {Delay}.", delay);

                try
                {
                    await Task.Delay(delay, stoppingToken);
                    await PreCalculateDailyStarterAsync(stoppingToken);
                }
                catch (TaskCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred during daily starter pre-calculation.");
                    await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
                }
            }

            _logger.LogInformation("DailyStarterBackgroundService stopped.");
        }

        public async Task PreCalculateDailyStarterAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Starting daily starter pre-calculation process...");
            using var scope = _serviceProvider.CreateScope();
            var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
            var dailyStarterService = scope.ServiceProvider.GetRequiredService<IDailyStarterService>();
            var featureAccessService = scope.ServiceProvider.GetRequiredService<IFeatureAccessService>();

            var users = await unitOfWork.Users.FindAsync(u => u.IsActive && u.DeletedAt == null);
            var userList = users.ToList();

            _logger.LogInformation("Pre-calculating daily starter dashboard data for {Count} active users.", userList.Count);

            // Process users in parallel batches for better performance
            const int batchSize = 10;
            var batches = userList
                .Select((user, index) => new { user, index })
                .GroupBy(x => x.index / batchSize)
                .Select(g => g.Select(x => x.user).ToList())
                .ToList();

            foreach (var batch in batches)
            {
                if (stoppingToken.IsCancellationRequested) break;

                var tasks = batch.Select(user => ProcessUserAsync(
                    user,
                    dailyStarterService,
                    featureAccessService,
                    stoppingToken
                ));

                await Task.WhenAll(tasks);
            }

            _logger.LogInformation("Daily starter pre-calculation completed.");
        }

        private async Task ProcessUserAsync(
            User user,
            IDailyStarterService dailyStarterService,
            IFeatureAccessService featureAccessService,
            CancellationToken stoppingToken)
        {
            try
            {
                if (!await featureAccessService.HasEntitlementAsync(user.Id, "casual_features"))
                {
                    return;
                }

                // By querying the personalization and daily starter, they are computed and cached (e.g. in Redis)
                // so that when the user logs in the next morning, the API response is extremely fast.
                await dailyStarterService.GetPersonalizationAsync(user.Id);
                await dailyStarterService.GetTodayStarterAsync(user.Id);
                
                _logger.LogDebug("Successfully pre-calculated daily starter for user {UserId}.", user.Id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to pre-calculate daily starter data for user {UserId}.", user.Id);
            }
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
