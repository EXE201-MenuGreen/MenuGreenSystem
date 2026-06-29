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
    public class StreakResetBackgroundService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<StreakResetBackgroundService> _logger;
        private readonly int _targetHour = 8;    // 08:00 AM local time
        private readonly int _targetMinute = 0;

        public StreakResetBackgroundService(
            IServiceProvider serviceProvider,
            ILogger<StreakResetBackgroundService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("StreakResetBackgroundService started. Scheduled daily at {Hour:D2}:{Minute:D2}.", _targetHour, _targetMinute);

            while (!stoppingToken.IsCancellationRequested)
            {
                var delay = GetDelayUntilNextRun();
                _logger.LogInformation("Next streak break check run in {Delay}.", delay);

                try
                {
                    await Task.Delay(delay, stoppingToken);
                    await CheckBrokenStreaksAsync(stoppingToken);
                }
                catch (TaskCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred during streak break check processing.");
                    await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
                }
            }

            _logger.LogInformation("StreakResetBackgroundService stopped.");
        }

        public async Task CheckBrokenStreaksAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Starting streak check...");
            using var scope = _serviceProvider.CreateScope();
            var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
            var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

            var users = await unitOfWork.Users.FindAsync(u => u.IsActive && u.DeletedAt == null);
            var userList = users.ToList();

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var yesterday = today.AddDays(-1);

            foreach (var user in userList)
            {
                if (stoppingToken.IsCancellationRequested) break;

                try
                {
                    var mealLogs = await unitOfWork.MealLogs.FindAsync(x => x.UserId == user.Id);
                    var loggedDates = mealLogs
                        .Where(x => x.LoggedAt.HasValue)
                        .Select(x => DateOnly.FromDateTime(x.LoggedAt!.Value))
                        .Distinct()
                        .OrderBy(x => x)
                        .ToList();

                    if (!loggedDates.Any()) continue;

                    // If they logged yesterday or today, their streak is active
                    var lastLogDate = loggedDates.Last();
                    if (lastLogDate == today || lastLogDate == yesterday)
                    {
                        continue;
                    }

                    // Otherwise, their streak is broken. Let's see how long the streak was up to the day before lastLogDate
                    // We calculate the streak starting from lastLogDate backwards:
                    int streak = 1;
                    for (int i = loggedDates.Count - 2; i >= 0; i--)
                    {
                        if (loggedDates[i + 1].DayNumber - loggedDates[i].DayNumber == 1)
                        {
                            streak++;
                        }
                        else
                        {
                            break;
                        }
                    }

                    // If they had a streak of at least 2 days and it is now broken (since they didn't log yesterday)
                    // and we haven't notified them today yet:
                    if (streak >= 2)
                    {
                        var now = DateTime.UtcNow;
                        var notifRequest = new NotificationSendRequest
                        {
                            UserId = user.Id,
                            Type = "streak_broken",
                            Title = "Chuỗi ngày ghi chép bị gián đoạn",
                            Body = $"Chuỗi ghi chép liên tiếp {streak} ngày của bạn đã bị ngắt do hôm qua chưa log bữa ăn. Hãy ghi lại bữa ăn hôm nay để bắt đầu chuỗi ngày mới nhé!",
                            ScheduledAt = now
                        };

                        await notificationService.SendAsync(notifRequest);
                        _logger.LogInformation("Sent streak broken notification to user {UserId}. Broken streak length was {Streak} days.", user.Id, streak);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing streak check for user {UserId}.", user.Id);
                }
            }

            _logger.LogInformation("Streak check completed.");
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
