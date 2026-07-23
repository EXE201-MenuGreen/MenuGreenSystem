using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace MenuGreen.BusinessLogicLayer.BackgroundJobs
{
    public class GoalDriftDetectionBackgroundService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<GoalDriftDetectionBackgroundService> _logger;
        private readonly int _targetHour = 23;   // 11:30 PM local time
        private readonly int _targetMinute = 30;

        public GoalDriftDetectionBackgroundService(
            IServiceProvider serviceProvider,
            ILogger<GoalDriftDetectionBackgroundService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("GoalDriftDetectionBackgroundService started. Scheduled daily at {Hour:D2}:{Minute:D2}.", _targetHour, _targetMinute);

            while (!stoppingToken.IsCancellationRequested)
            {
                var delay = GetDelayUntilNextRun();
                _logger.LogInformation("Next goal drift scan in {Delay}.", delay);

                try
                {
                    await Task.Delay(delay, stoppingToken);
                    await ScanGoalDriftsAsync(stoppingToken);
                }
                catch (TaskCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred during goal drift scan processing.");
                    await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
                }
            }

            _logger.LogInformation("GoalDriftDetectionBackgroundService stopped.");
        }

        public async Task ScanGoalDriftsAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Starting daily goal drift analysis scanning...");
            using var scope = _serviceProvider.CreateScope();
            var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
            var goalDriftService = scope.ServiceProvider.GetRequiredService<IGoalDriftService>();

            var users = await unitOfWork.Users.FindAsync(u => u.IsActive && u.DeletedAt == null, asNoTracking: true);
            var userList = users.ToList();

            _logger.LogInformation("Scanning nutrition goal drifts for {Count} active users.", userList.Count);

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
                    goalDriftService,
                    stoppingToken
                ));

                await Task.WhenAll(tasks);
            }

            _logger.LogInformation("Daily goal drift scanning completed.");
        }

        private async Task ProcessUserAsync(
            User user,
            IGoalDriftService goalDriftService,
            CancellationToken stoppingToken)
        {
            try
            {
                if (stoppingToken.IsCancellationRequested) return;

                // Recalculates user calorie drift. This automatically triggers notifications
                // and creates GoalDriftAlert entities if it exceeds thresholds.
                var alert = await goalDriftService.RecalculateDriftAsync(user.Id);
                if (alert != null)
                {
                    _logger.LogInformation("Calorie drift detected and recorded for user {UserId}. Drift Value: {DriftVal}%.", user.Id, alert.PercentDeviation);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to recalculate goal drift for user {UserId}.", user.Id);
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
