using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.Extensions.Logging;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class NotificationDispatcherService : INotificationDispatcherService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IFcmService _fcmService;
        private readonly ILogger<NotificationDispatcherService> _logger;

        public NotificationDispatcherService(
            IUnitOfWork unitOfWork,
            IFcmService fcmService,
            ILogger<NotificationDispatcherService> logger)
        {
            _unitOfWork = unitOfWork;
            _fcmService = fcmService;
            _logger = logger;
        }

        public async Task<NotificationDispatchResult> DispatchDueNotificationsAsync()
        {
            return await DispatchPendingAsync(beforeProcessing: null);
        }

        public async Task<NotificationDispatchResult> DispatchAllPendingAsync()
        {
            return await DispatchPendingAsync(beforeProcessing: null);
        }

        private async Task<NotificationDispatchResult> DispatchPendingAsync(
            Func<IEnumerable<Notification>, Task>? beforeProcessing)
        {
            var now = DateTimeOffset.UtcNow;

            var pendingNotifications = await _unitOfWork.Notifications.FindAsync(
                n => n.SentAt == null
                     && n.ScheduledAt != null
                     && n.ScheduledAt <= now
                     && !n.IsDismissed);

            var notificationList = pendingNotifications.ToList();

            if (notificationList.Count == 0)
            {
                return new NotificationDispatchResult
                {
                    TotalProcessed = 0,
                    NotificationsCreated = 0,
                    PushSent = 0,
                    PushFailed = 0,
                    Skipped = 0,
                    Summary = "No pending notifications to dispatch."
                };
            }

            var result = new NotificationDispatchResult
            {
                TotalProcessed = notificationList.Count
            };

            foreach (var notification in notificationList)
            {
                try
                {
                    await DispatchSingleAsync(notification, result);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex,
                        "Failed to dispatch notification {NotificationId} for user {UserId}",
                        notification.Id, notification.UserId);
                    result.Skipped++;
                }
            }

            result.Summary = $"Processed {result.TotalProcessed}: " +
                             $"{result.PushSent} sent, {result.PushFailed} failed, {result.Skipped} skipped.";

            return result;
        }

        private async Task DispatchSingleAsync(Notification notification,
            NotificationDispatchResult result)
        {
            var userSettings = (await _unitOfWork.NotificationSettings
                .FindAsync(s => s.UserId == notification.UserId))
                .FirstOrDefault();

            var pushEnabled = userSettings?.PushEnabled ?? false;

            if (!pushEnabled)
            {
                notification.SentAt = DateTimeOffset.UtcNow;
                _unitOfWork.Notifications.Update(notification);
                await _unitOfWork.CompleteAsync();
                result.Skipped++;
                _logger.LogDebug(
                    "Skipped push for notification {NotificationId}: PushEnabled=false",
                    notification.Id);
                return;
            }

            var fcmResult = await _fcmService.SendToUserAsync(
                notification.UserId,
                notification.Title ?? "MenuGreen",
                notification.Body ?? "",
                SerializeNotificationData(notification));

            if (fcmResult.SuccessCount > 0)
            {
                notification.SentAt = DateTimeOffset.UtcNow;
                _unitOfWork.Notifications.Update(notification);
                await _unitOfWork.CompleteAsync();
                result.PushSent++;

                _logger.LogInformation(
                    "Push sent for notification {NotificationId}: {SuccessCount}/{Total} success",
                    notification.Id, fcmResult.SuccessCount, fcmResult.SuccessCount + fcmResult.FailureCount);
            }
            else
            {
                notification.SentAt = DateTimeOffset.UtcNow;
                _unitOfWork.Notifications.Update(notification);
                await _unitOfWork.CompleteAsync();
                result.PushFailed++;

                _logger.LogWarning(
                    "Push failed for notification {NotificationId}: {Message}",
                    notification.Id, fcmResult.Message);
            }
        }

        private static string SerializeNotificationData(Notification notification)
        {
            return $"{notification.Type}|{notification.Id}";
        }
    }
}
