using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.Extensions.Logging;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class NotificationDispatcherService : INotificationDispatcherService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IFcmService _fcmService;
        private readonly INotificationHubService _notificationHubService;
        private readonly ILogger<NotificationDispatcherService> _logger;

        public NotificationDispatcherService(
            IUnitOfWork unitOfWork,
            IFcmService fcmService,
            INotificationHubService notificationHubService,
            ILogger<NotificationDispatcherService> logger)
        {
            _unitOfWork = unitOfWork;
            _fcmService = fcmService;
            _notificationHubService = notificationHubService;
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

        public async Task<NotificationDispatchResult> GetDispatchStatsAsync()
        {
            var now = DateTimeOffset.UtcNow;

            var pendingNotifications = await _unitOfWork.Notifications.FindAsync(
                n => n.SentAt == null
                     && n.ScheduledAt != null
                     && n.ScheduledAt <= now
                     && !n.IsDismissed
                     && (n.Type == null || !n.Type.StartsWith("DISABLED_")));

            var notificationList = pendingNotifications.ToList();

            var totalProcessed = notificationList.Count;
            var skipped = 0;

            foreach (var notification in notificationList)
            {
                var userSettings = (await _unitOfWork.NotificationSettings
                    .FindAsync(s => s.UserId == notification.UserId))
                    .FirstOrDefault();

                if (!(userSettings?.PushEnabled ?? false))
                {
                    skipped++;
                }
            }

            return new NotificationDispatchResult
            {
                TotalProcessed = totalProcessed,
                NotificationsCreated = 0,
                PushSent = 0,
                PushFailed = 0,
                Skipped = skipped,
                Summary = $"Found {totalProcessed} pending notifications: {skipped} would be skipped (push disabled)."
            };
        }

        private async Task<NotificationDispatchResult> DispatchPendingAsync(
            Func<IEnumerable<Notification>, Task>? beforeProcessing)
        {
            var now = DateTimeOffset.UtcNow;

            var pendingNotifications = await _unitOfWork.Notifications.FindAsync(
                n => n.SentAt == null
                     && n.ScheduledAt != null
                     && n.ScheduledAt <= now
                     && !n.IsDismissed
                     && (n.Type == null || !n.Type.StartsWith("DISABLED_")));

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
            var inAppEnabled = userSettings?.InAppEnabled ?? true;

            var notificationResponse = MapNotification(notification);

            // 1. Send via SignalR (In-App) if enabled
            if (inAppEnabled)
            {
                try
                {
                    await _notificationHubService.SendNotificationToUserAsync(notification.UserId, notificationResponse);
                    
                    var unreadCount = (await _unitOfWork.Notifications.FindAsync(x => x.UserId == notification.UserId && !x.IsRead)).Count();
                    await _notificationHubService.SendUnreadCountToUserAsync(notification.UserId, unreadCount);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to send in-app notification via SignalR for user {UserId}", notification.UserId);
                }
            }

            // 2. Send via Push (FCM) if enabled
            if (pushEnabled)
            {
                var fcmResult = await _fcmService.SendToUserAsync(
                    notification.UserId,
                    notification.Title ?? "MenuGreen",
                    notification.Body ?? "",
                    SerializeNotificationData(notification));

                if (fcmResult.SuccessCount > 0)
                {
                    result.PushSent++;
                    _logger.LogInformation(
                        "Push sent for notification {NotificationId}: {SuccessCount}/{Total} success",
                        notification.Id, fcmResult.SuccessCount, fcmResult.SuccessCount + fcmResult.FailureCount);
                }
                else
                {
                    result.PushFailed++;
                    _logger.LogWarning(
                        "Push failed for notification {NotificationId}: {Message}",
                        notification.Id, fcmResult.Message);
                }
            }
            else
            {
                result.Skipped++;
                _logger.LogDebug(
                    "Skipped push for notification {NotificationId}: PushEnabled=false",
                    notification.Id);
            }

            // Mark as sent
            notification.SentAt = DateTimeOffset.UtcNow;
            _unitOfWork.Notifications.Update(notification);
            var repeatInterval = ReminderService.GetRepeatInterval(notification.Type);
            if (repeatInterval.HasValue && notification.ScheduledAt.HasValue)
            {
                var nextAt = notification.ScheduledAt.Value.AddMinutes(repeatInterval.Value);
                while (nextAt <= DateTimeOffset.UtcNow) nextAt = nextAt.AddMinutes(repeatInterval.Value);
                await _unitOfWork.Notifications.AddAsync(new Notification
                {
                    Id = Guid.NewGuid(), UserId = notification.UserId, Title = notification.Title,
                    Body = notification.Body, Type = notification.Type, IsRead = false,
                    CreatedAt = DateTimeOffset.UtcNow, ScheduledAt = nextAt
                });
                result.NotificationsCreated++;
            }
            await _unitOfWork.CompleteAsync();
        }

        private static NotificationResponse MapNotification(Notification notification)
        {
            return new NotificationResponse
            {
                Id = notification.Id,
                UserId = notification.UserId,
                Title = notification.Title,
                Body = notification.Body,
                Type = notification.Type,
                IsRead = notification.IsRead,
                CreatedAt = notification.CreatedAt,
                ScheduledAt = notification.ScheduledAt,
                SentAt = notification.SentAt,
                ReadAt = notification.ReadAt,
                IsDismissed = notification.IsDismissed,
                DismissedAt = notification.DismissedAt,
                ClickedAt = notification.ClickedAt,
                ActionCompletedAt = notification.ActionCompletedAt
            };
        }

        private static string SerializeNotificationData(Notification notification)
        {
            return $"{notification.Type}|{notification.Id}";
        }
    }
}
