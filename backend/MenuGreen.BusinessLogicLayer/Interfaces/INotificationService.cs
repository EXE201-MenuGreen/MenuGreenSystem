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
    }
}
