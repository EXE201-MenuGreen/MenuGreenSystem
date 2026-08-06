using System;
using System.Threading;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace MenuGreen.BusinessLogicLayer.BackgroundJobs
{
    public class MealPlanProposalDeadlineBackgroundService : BackgroundService
    {
        private readonly IServiceProvider _services;
        private readonly ILogger<MealPlanProposalDeadlineBackgroundService> _logger;

        public MealPlanProposalDeadlineBackgroundService(
            IServiceProvider services,
            ILogger<MealPlanProposalDeadlineBackgroundService> logger)
        {
            _services = services;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                var utcNow = DateTime.UtcNow;
                var localNow = utcNow.AddHours(7);
                var nextLocalRun = NextRun(localNow);
                var delay = nextLocalRun - localNow;
                try
                {
                    await Task.Delay(delay, stoppingToken);
                    await ProcessAsync(DateTime.UtcNow, stoppingToken);
                }
                catch (TaskCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Meal-plan proposal deadline job failed.");
                    await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
                }
            }
        }

        public async Task ProcessAsync(DateTime utcNow, CancellationToken cancellationToken = default)
        {
            using var scope = _services.CreateScope();
            var service = scope.ServiceProvider.GetRequiredService<IMealPlanProposalService>();
            var localNow = utcNow.AddHours(7);
            if (localNow.Hour == 23 && localNow.Minute >= 45)
            {
                await service.ProcessDeadlineNotificationsAsync(utcNow);
            }
            await service.ExpireOverdueAsync(utcNow);
        }

        private static DateTime NextRun(DateTime localNow)
        {
            var midnight = localNow.Date.AddDays(1);
            var reminder = localNow.Date.AddHours(23).AddMinutes(45);
            if (localNow < reminder) return reminder;
            if (localNow < midnight) return midnight;
            return localNow.Date.AddDays(1).AddHours(23).AddMinutes(45);
        }
    }
}
