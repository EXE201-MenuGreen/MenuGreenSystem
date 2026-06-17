using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface INotificationService
    {
        Task<NotificationSettingResponse> GetSettingsAsync(Guid userId);
        Task<NotificationSettingResponse> UpdateSettingsAsync(Guid userId, NotificationSettingUpsertRequest request);
        Task<IEnumerable<NotificationResponse>> GetNotificationsAsync(Guid userId, bool? unreadOnly = null);
        Task<NotificationResponse> GetByIdAsync(Guid userId, Guid notificationId);
        Task<int> GetUnreadCountAsync(Guid userId);
        Task<NotificationResponse> MarkAsReadAsync(Guid userId, Guid notificationId);
        Task MarkAllAsReadAsync(Guid userId);
        Task DeleteAsync(Guid userId, Guid notificationId);
        Task<int> DeleteBatchAsync(Guid userId, List<Guid> notificationIds);
        Task<int> DeleteByRangeAsync(Guid userId, DateOnly startDate, DateOnly endDate);
        Task<NotificationResponse> ScheduleMealReminderAsync(Guid userId, ScheduleMealReminderRequest request);
        Task<NotificationResponse> SchedulePrepReminderAsync(Guid userId, SchedulePrepReminderRequest request);
        Task<IEnumerable<string>> GetChannelsAsync();
        Task ResetSettingsAsync(Guid userId);
        Task<NotificationResponse> SendAsync(NotificationSendRequest request);
        Task<IEnumerable<NotificationResponse>> SendBulkAsync(IEnumerable<NotificationSendRequest> requests);
        Task<IEnumerable<NotificationResponse>> SendBulkNotificationAsync(NotificationSendBulkRequest request);
        Task<NotificationResponse> SendEventNotificationAsync(NotificationSendEventRequest request);
        Task<NotificationResponse> ScheduleNotificationAsync(NotificationScheduleRequest request);
        Task<int> RetryNotificationsAsync(NotificationRetryRequest request);

        Task<CampaignResponse> CreateCampaignAsync(CampaignUpsertRequest request);
        Task<IEnumerable<CampaignResponse>> GetCampaignsAsync();
        Task<CampaignResponse> GetCampaignByIdAsync(Guid id);
        Task<CampaignResponse> UpdateCampaignAsync(Guid id, CampaignUpsertRequest request);
        Task<CampaignResponse> RunCampaignAsync(Guid id);
        Task<CampaignResponse> PauseCampaignAsync(Guid id);

        Task<ReEngagementAnalyticsResponse> GetReEngagementAnalyticsAsync();

        Task TrackOpenAsync(Guid userId, Guid notificationId, NotificationTrackRequest request);
        Task TrackClickAsync(Guid userId, Guid notificationId, NotificationTrackRequest request);
        Task TrackActionCompleteAsync(Guid userId, Guid notificationId, NotificationTrackRequest request);
        Task<object> GetAnalyticsAsync(Guid userId);
    }
}
