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
            var notification = await GetOwnedNotificationAsync(userId, notificationId);
            notification.IsRead = true;
            notification.ReadAt = DateTimeOffset.UtcNow;
            _unitOfWork.Notifications.Update(notification);
            await _unitOfWork.CompleteAsync();
        }

        public async Task TrackClickAsync(Guid userId, Guid notificationId, NotificationTrackRequest request)
        {
            var notification = await GetOwnedNotificationAsync(userId, notificationId);
            notification.ClickedAt = DateTimeOffset.UtcNow;
            _unitOfWork.Notifications.Update(notification);
            await _unitOfWork.CompleteAsync();
        }

        public async Task TrackActionCompleteAsync(Guid userId, Guid notificationId, NotificationTrackRequest request)
        {
            var notification = await GetOwnedNotificationAsync(userId, notificationId);
            notification.ActionCompletedAt = DateTimeOffset.UtcNow;
            _unitOfWork.Notifications.Update(notification);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<NotificationResponse> DismissAsync(Guid userId, Guid notificationId)
        {
            var notification = await GetOwnedNotificationAsync(userId, notificationId);
            notification.IsDismissed = true;
            notification.DismissedAt = DateTimeOffset.UtcNow;
            _unitOfWork.Notifications.Update(notification);
            await _unitOfWork.CompleteAsync();
            return MapNotification(notification);
        }

        public async Task<object> GetAnalyticsAsync(Guid userId)
        {
            var notifications = await _unitOfWork.Notifications.FindAsync(x => x.UserId == userId);
            var list = notifications.ToList();
            var sent = list.Count;
            var opened = list.Count(x => x.ReadAt.HasValue);
            var clicked = list.Count(x => x.ClickedAt.HasValue);
            var actionCompleted = list.Count(x => x.ActionCompletedAt.HasValue);
            return new
            {
                Sent = sent,
                Opened = opened,
                Clicked = clicked,
                OpenRate = sent == 0 ? 0 : (double)opened / sent,
                ClickRate = sent == 0 ? 0 : (double)clicked / sent,
                ActionCompletionRate = sent == 0 ? 0 : (double)actionCompleted / sent
            };
        }

        public async Task<IEnumerable<NotificationResponse>> SendBulkNotificationAsync(NotificationSendBulkRequest request)
        {
            var result = new List<NotificationResponse>();
            foreach (var userId in request.UserIds)
            {
                var notification = await CreateNotificationAsync(
                    userId,
                    request.Notification.Type,
                    request.Notification.Title,
                    request.Notification.Body,
                    request.ScheduleAt ?? DateTimeOffset.UtcNow);
                result.Add(notification);
            }
            return result;
        }

        public async Task<NotificationResponse> SendEventNotificationAsync(NotificationSendEventRequest request)
        {
            string title = "Thông báo từ MenuGreen";
            string body = "";

            if (request.EventType == "meal_time")
            {
                var mealType = request.Context != null && request.Context.TryGetValue("mealType", out var mt) ? mt.ToString() : "bữa ăn";
                title = "Đến giờ ăn rồi!";
                body = $"Đã đến giờ ăn {mealType} của bạn. Hãy ghi nhận món ăn nhé!";
            }
            else if (request.EventType == "subscription_expiring")
            {
                var days = request.Context != null && request.Context.TryGetValue("daysUntilExpiry", out var d) ? d.ToString() : "vài";
                title = "Gói đăng ký sắp hết hạn";
                body = $"Gói đăng ký của bạn sẽ hết hạn sau {days} ngày. Gia hạn ngay để không gián đoạn dịch vụ.";
            }
            else if (request.EventType == "weight_reminder")
            {
                title = "Cập nhật cân nặng";
                body = "Hãy dành ít phút ghi nhận cân nặng hôm nay để theo dõi tiến trình nhé!";
            }
            else if (request.EventType == "meal_not_logged")
            {
                title = "Ghi nhận bữa ăn";
                body = "Bạn chưa ghi nhận bữa ăn nào hôm nay. Hãy tiếp tục duy trì thói quen nhé!";
            }
            else
            {
                body = $"Sự kiện {request.EventType} đã xảy ra.";
            }

            return await CreateNotificationAsync(request.UserId, request.EventType, title, body, DateTimeOffset.UtcNow);
        }

        public async Task<NotificationResponse> ScheduleNotificationAsync(NotificationScheduleRequest request)
        {
            return await CreateNotificationAsync(request.UserId, request.Type, request.Title, request.Body, request.ScheduledAt);
        }

        public async Task<int> RetryNotificationsAsync(NotificationRetryRequest request)
        {
            IEnumerable<Notification> notificationsToRetry;
            if (request.NotificationIds != null && request.NotificationIds.Count > 0)
            {
                notificationsToRetry = await _unitOfWork.Notifications.FindAsync(
                    x => request.NotificationIds.Contains(x.Id));
            }
            else
            {
                var now = DateTimeOffset.UtcNow;
                notificationsToRetry = await _unitOfWork.Notifications.FindAsync(
                    x => x.SentAt == null && x.ScheduledAt <= now);
            }

            var count = 0;
            foreach (var notif in notificationsToRetry)
            {
                notif.SentAt = DateTimeOffset.UtcNow;
                _unitOfWork.Notifications.Update(notif);
                count++;
            }

            if (count > 0)
            {
                await _unitOfWork.CompleteAsync();
            }

            return count;
        }

        public async Task<CampaignResponse> CreateCampaignAsync(CampaignUpsertRequest request)
        {
            var campaign = new Campaign
            {
                Id = Guid.NewGuid(),
                Name = request.Name,
                TargetSegment = request.TargetSegment,
                Title = request.Notification.Title,
                Body = request.Notification.Body,
                StartDate = request.Schedule.StartDate,
                EndDate = request.Schedule.EndDate,
                SendTime = request.Schedule.SendTime,
                IsActive = request.IsActive,
                Status = request.IsActive ? "Running" : "Draft",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Campaigns.AddAsync(campaign);
            await _unitOfWork.CompleteAsync();

            return MapCampaign(campaign);
        }

        public async Task<IEnumerable<CampaignResponse>> GetCampaignsAsync()
        {
            var campaigns = await _unitOfWork.Campaigns.GetAllAsync();
            return campaigns.Select(MapCampaign).ToList();
        }

        public async Task<CampaignResponse> GetCampaignByIdAsync(Guid id)
        {
            var campaign = await _unitOfWork.Campaigns.GetByIdAsync(id);
            if (campaign == null) throw new Exception("Campaign not found.");
            return MapCampaign(campaign);
        }

        public async Task<CampaignResponse> UpdateCampaignAsync(Guid id, CampaignUpsertRequest request)
        {
            var campaign = await _unitOfWork.Campaigns.GetByIdAsync(id);
            if (campaign == null) throw new Exception("Campaign not found.");

            campaign.Name = request.Name;
            campaign.TargetSegment = request.TargetSegment;
            campaign.Title = request.Notification.Title;
            campaign.Body = request.Notification.Body;
            campaign.StartDate = request.Schedule.StartDate;
            campaign.EndDate = request.Schedule.EndDate;
            campaign.SendTime = request.Schedule.SendTime;
            campaign.IsActive = request.IsActive;
            campaign.Status = request.IsActive ? "Running" : "Paused";
            campaign.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Campaigns.Update(campaign);
            await _unitOfWork.CompleteAsync();

            return MapCampaign(campaign);
        }

        public async Task<CampaignResponse> RunCampaignAsync(Guid id)
        {
            var campaign = await _unitOfWork.Campaigns.GetByIdAsync(id);
            if (campaign == null) throw new Exception("Campaign not found.");

            campaign.IsActive = true;
            campaign.Status = "Running";
            campaign.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Campaigns.Update(campaign);

            var users = await _unitOfWork.Users.GetAllAsync();
            var targetUsers = new List<User>();

            if (campaign.TargetSegment == "inactive_7_days")
            {
                var threshold = DateTime.UtcNow.AddDays(-7);
                targetUsers = users.Where(u => u.IsActive &&
                    ((u.LastSignInAt.HasValue && u.LastSignInAt.Value <= threshold) ||
                     (!u.LastSignInAt.HasValue && u.CreatedAt <= threshold))).ToList();
            }
            else if (campaign.TargetSegment == "inactive_30_days")
            {
                var threshold = DateTime.UtcNow.AddDays(-30);
                targetUsers = users.Where(u => u.IsActive &&
                    ((u.LastSignInAt.HasValue && u.LastSignInAt.Value <= threshold) ||
                     (!u.LastSignInAt.HasValue && u.CreatedAt <= threshold))).ToList();
            }
            else
            {
                targetUsers = users.Where(u => u.IsActive).ToList();
            }

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var startDate = campaign.StartDate > today ? campaign.StartDate : today;
            var endDate = campaign.EndDate;

            if (startDate <= endDate)
            {
                foreach (var user in targetUsers)
                {
                    var scheduledDateTime = startDate.ToDateTime(campaign.SendTime);
                    var scheduledAt = new DateTimeOffset(scheduledDateTime, TimeSpan.Zero);

                    var notification = new Notification
                    {
                        Id = Guid.NewGuid(),
                        UserId = user.Id,
                        CampaignId = campaign.Id,
                        Title = campaign.Title,
                        Body = campaign.Body,
                        Type = "campaign_re_engagement",
                        IsRead = false,
                        CreatedAt = DateTimeOffset.UtcNow,
                        ScheduledAt = scheduledAt,
                        SentAt = null,
                        ReadAt = null
                    };

                    await _unitOfWork.Notifications.AddAsync(notification);
                }
            }

            await _unitOfWork.CompleteAsync();
            return MapCampaign(campaign);
        }

        public async Task<CampaignResponse> PauseCampaignAsync(Guid id)
        {
            var campaign = await _unitOfWork.Campaigns.GetByIdAsync(id);
            if (campaign == null) throw new Exception("Campaign not found.");

            campaign.IsActive = false;
            campaign.Status = "Paused";
            campaign.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Campaigns.Update(campaign);

            var unsentNotifications = await _unitOfWork.Notifications.FindAsync(
                x => x.CampaignId == campaign.Id && x.SentAt == null);

            foreach (var notif in unsentNotifications)
            {
                _unitOfWork.Notifications.Remove(notif);
            }

            await _unitOfWork.CompleteAsync();
            return MapCampaign(campaign);
        }

        public async Task<ReEngagementAnalyticsResponse> GetReEngagementAnalyticsAsync()
        {
            var notifications = await _unitOfWork.Notifications.FindAsync(
                x => x.CampaignId != null || x.Type == "campaign_re_engagement");

            var list = notifications.ToList();
            var sent = list.Count;
            var opened = list.Count(x => x.ReadAt.HasValue);
            var clicked = list.Count(x => x.ClickedAt.HasValue);
            var actionCompleted = list.Count(x => x.ActionCompletedAt.HasValue);

            return new ReEngagementAnalyticsResponse
            {
                TotalSent = sent,
                TotalOpened = opened,
                TotalClicked = clicked,
                TotalActionCompleted = actionCompleted,
                OpenRate = sent == 0 ? 0 : (double)opened / sent,
                ClickRate = sent == 0 ? 0 : (double)clicked / sent,
                ActionCompletionRate = sent == 0 ? 0 : (double)actionCompleted / sent
            };
        }

        private static CampaignResponse MapCampaign(Campaign campaign)
        {
            return new CampaignResponse
            {
                Id = campaign.Id,
                Name = campaign.Name,
                TargetSegment = campaign.TargetSegment,
                Notification = new NotificationPayload
                {
                    Title = campaign.Title,
                    Body = campaign.Body,
                    Type = "campaign_re_engagement"
                },
                Schedule = new CampaignScheduleDto
                {
                    StartDate = campaign.StartDate,
                    EndDate = campaign.EndDate,
                    SendTime = campaign.SendTime
                },
                IsActive = campaign.IsActive,
                Status = campaign.Status,
                CreatedAt = campaign.CreatedAt,
                UpdatedAt = campaign.UpdatedAt
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
                ReadAt = notification.ReadAt,
                IsDismissed = notification.IsDismissed,
                DismissedAt = notification.DismissedAt,
                ClickedAt = notification.ClickedAt,
                ActionCompletedAt = notification.ActionCompletedAt
            };
        }
    }
}
