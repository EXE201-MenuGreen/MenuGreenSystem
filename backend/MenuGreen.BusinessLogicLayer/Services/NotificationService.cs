using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class NotificationService : INotificationService
    {
        private readonly IUnitOfWork _unitOfWork;

        public NotificationService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<NotificationSettingResponse> GetSettingsAsync(Guid userId)
        {
            var settings = await EnsureSettingsAsync(userId);
            return MapSettings(settings);
        }

        public async Task<NotificationSettingResponse> UpdateSettingsAsync(Guid userId, NotificationSettingUpsertRequest request)
        {
            var settings = await EnsureSettingsAsync(userId);
            settings.MealReminderEnabled = request.MealReminderEnabled;
            settings.MealReminderOffsetMinutes = request.MealReminderOffsetMinutes;
            settings.PrepReminderEnabled = request.PrepReminderEnabled;
            settings.PrepReminderOffsetMinutes = request.PrepReminderOffsetMinutes;
            settings.InAppEnabled = request.InAppEnabled;
            settings.PushEnabled = request.PushEnabled;
            settings.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.NotificationSettings.Update(settings);
            await _unitOfWork.CompleteAsync();
            return MapSettings(settings);
        }

        public async Task<IEnumerable<NotificationResponse>> GetNotificationsAsync(Guid userId, bool? unreadOnly = null)
        {
            var notifications = await _unitOfWork.Notifications.FindAsync(x => x.UserId == userId);
            if (unreadOnly == true)
            {
                notifications = notifications.Where(x => !x.IsRead);
            }

            return notifications.OrderByDescending(x => x.CreatedAt).Select(MapNotification).ToList();
        }

        public async Task<NotificationResponse> GetByIdAsync(Guid userId, Guid notificationId)
        {
            var notification = await GetOwnedNotificationAsync(userId, notificationId);
            return MapNotification(notification);
        }

        public async Task<int> GetUnreadCountAsync(Guid userId)
        {
            var notifications = await _unitOfWork.Notifications.FindAsync(x => x.UserId == userId && !x.IsRead);
            return notifications.Count();
        }

        public async Task<NotificationResponse> MarkAsReadAsync(Guid userId, Guid notificationId)
        {
            var notification = await GetOwnedNotificationAsync(userId, notificationId);
            notification.IsRead = true;
            notification.ReadAt = DateTimeOffset.UtcNow;
            _unitOfWork.Notifications.Update(notification);
            await _unitOfWork.CompleteAsync();
            return MapNotification(notification);
        }

        public async Task MarkAllAsReadAsync(Guid userId)
        {
            var notifications = await _unitOfWork.Notifications.FindAsync(x => x.UserId == userId && !x.IsRead);
            foreach (var notification in notifications)
            {
                notification.IsRead = true;
                notification.ReadAt = DateTimeOffset.UtcNow;
                _unitOfWork.Notifications.Update(notification);
            }

            await _unitOfWork.CompleteAsync();
        }

        public async Task DeleteAsync(Guid userId, Guid notificationId)
        {
            var notification = await GetOwnedNotificationAsync(userId, notificationId);
            _unitOfWork.Notifications.Remove(notification);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<int> DeleteBatchAsync(Guid userId, List<Guid> notificationIds)
        {
            if (notificationIds == null || notificationIds.Count == 0)
            {
                return 0;
            }

            var notifications = await _unitOfWork.Notifications.FindAsync(
                x => x.UserId == userId && notificationIds.Contains(x.Id));

            var notificationList = notifications.ToList();
            
            foreach (var notification in notificationList)
            {
                _unitOfWork.Notifications.Remove(notification);
            }

            await _unitOfWork.CompleteAsync();
            return notificationList.Count;
        }

        public async Task<int> DeleteByRangeAsync(Guid userId, DateOnly startDate, DateOnly endDate)
        {
            var startDateTime = startDate.ToDateTime(TimeOnly.MinValue);
            var endDateTime = endDate.ToDateTime(TimeOnly.MaxValue);

            var notifications = await _unitOfWork.Notifications.FindAsync(
                x => x.UserId == userId && 
                x.CreatedAt >= startDateTime && 
                x.CreatedAt <= endDateTime);

            var notificationList = notifications.ToList();
            
            foreach (var notification in notificationList)
            {
                _unitOfWork.Notifications.Remove(notification);
            }

            await _unitOfWork.CompleteAsync();
            return notificationList.Count;
        }

        public async Task<NotificationResponse> ScheduleMealReminderAsync(Guid userId, ScheduleMealReminderRequest request)
        {
            var settings = await EnsureSettingsAsync(userId);
            if (!settings.MealReminderEnabled) throw new Exception("Meal reminder is disabled.");

            var scheduledAt = new DateTimeOffset(request.MealTime).AddMinutes(-settings.MealReminderOffsetMinutes);
            return await CreateNotificationAsync(userId, "MEAL_REMINDER", request.Title ?? "Meal reminder", request.Body ?? $"Meal time at {request.MealTime:HH:mm}.", scheduledAt);
        }

        public async Task<NotificationResponse> SchedulePrepReminderAsync(Guid userId, SchedulePrepReminderRequest request)
        {
            var settings = await EnsureSettingsAsync(userId);
            if (!settings.PrepReminderEnabled) throw new Exception("Prep reminder is disabled.");

            var scheduledAt = new DateTimeOffset(request.CookingTime).AddMinutes(-settings.PrepReminderOffsetMinutes);
            return await CreateNotificationAsync(userId, "PREP_REMINDER", request.Title ?? "Prep reminder", request.Body ?? $"Prepare ingredients before cooking at {request.CookingTime:HH:mm}.", scheduledAt);
        }

        public Task<IEnumerable<string>> GetChannelsAsync()
        {
            IEnumerable<string> channels = new[] { "in-app", "push", "email" };
            return Task.FromResult(channels);
        }

        public async Task ResetSettingsAsync(Guid userId)
        {
            var settings = await EnsureSettingsAsync(userId);
            settings.MealReminderEnabled = true;
            settings.MealReminderOffsetMinutes = 30;
            settings.PrepReminderEnabled = true;
            settings.PrepReminderOffsetMinutes = 20;
            settings.InAppEnabled = true;
            settings.PushEnabled = false;
            settings.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.NotificationSettings.Update(settings);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<NotificationResponse> SendAsync(NotificationSendRequest request)
        {
            return await CreateNotificationAsync(request.UserId, request.Type, request.Title, request.Body, request.ScheduledAt ?? DateTimeOffset.UtcNow);
        }

        public async Task<IEnumerable<NotificationResponse>> SendBulkAsync(IEnumerable<NotificationSendRequest> requests)
        {
            var result = new List<NotificationResponse>();
            foreach (var request in requests)
            {
                result.Add(await SendAsync(request));
            }
            return result;
        }

        public async Task TrackOpenAsync(Guid userId, Guid notificationId, NotificationTrackRequest request)
        {
            await MarkAsReadAsync(userId, notificationId);
        }

        public Task TrackClickAsync(Guid userId, Guid notificationId, NotificationTrackRequest request)
        {
            return Task.CompletedTask;
        }

        public Task TrackActionCompleteAsync(Guid userId, Guid notificationId, NotificationTrackRequest request)
        {
            return Task.CompletedTask;
        }

        public async Task<object> GetAnalyticsAsync(Guid userId)
        {
            var notifications = await _unitOfWork.Notifications.FindAsync(x => x.UserId == userId);
            var list = notifications.ToList();
            var sent = list.Count;
            var opened = list.Count(x => x.ReadAt.HasValue);
            var clicked = 0;
            return new
            {
                Sent = sent,
                Opened = opened,
                Clicked = clicked,
                OpenRate = sent == 0 ? 0 : (double)opened / sent,
                ClickRate = sent == 0 ? 0 : (double)clicked / sent,
                ActionCompletionRate = 0d
            };
        }

        private async Task<NotificationSetting> EnsureSettingsAsync(Guid userId)
        {
            var settings = (await _unitOfWork.NotificationSettings.FindAsync(x => x.UserId == userId)).FirstOrDefault();
            if (settings != null) return settings;

            settings = new NotificationSetting
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                MealReminderEnabled = true,
                MealReminderOffsetMinutes = 30,
                PrepReminderEnabled = true,
                PrepReminderOffsetMinutes = 20,
                InAppEnabled = true,
                PushEnabled = false,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.NotificationSettings.AddAsync(settings);
            await _unitOfWork.CompleteAsync();
            return settings;
        }

        private async Task<NotificationResponse> CreateNotificationAsync(Guid userId, string type, string title, string body, DateTimeOffset scheduledAt)
        {
            var notification = new Notification
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Type = type,
                Title = title,
                Body = body,
                IsRead = false,
                CreatedAt = DateTimeOffset.UtcNow,
                ScheduledAt = scheduledAt,
                SentAt = null,
                ReadAt = null
            };

            await _unitOfWork.Notifications.AddAsync(notification);
            await _unitOfWork.CompleteAsync();
            return MapNotification(notification);
        }

        private async Task<Notification> GetOwnedNotificationAsync(Guid userId, Guid notificationId)
        {
            var notification = await _unitOfWork.Notifications.GetByIdAsync(notificationId);
            if (notification == null) throw new Exception("Notification not found.");
            if (notification.UserId != userId) throw new Exception("Forbidden.");
            return notification;
        }

        private static NotificationSettingResponse MapSettings(NotificationSetting settings)
        {
            return new NotificationSettingResponse
            {
                UserId = settings.UserId,
                MealReminderEnabled = settings.MealReminderEnabled,
                MealReminderOffsetMinutes = settings.MealReminderOffsetMinutes,
                PrepReminderEnabled = settings.PrepReminderEnabled,
                PrepReminderOffsetMinutes = settings.PrepReminderOffsetMinutes,
                InAppEnabled = settings.InAppEnabled,
                PushEnabled = settings.PushEnabled
            };
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
                ReadAt = notification.ReadAt
            };
        }
    }
}
