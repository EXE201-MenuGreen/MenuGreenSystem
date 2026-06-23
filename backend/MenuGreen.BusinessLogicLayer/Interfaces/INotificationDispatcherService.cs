using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface INotificationDispatcherService
    {
        Task<NotificationDispatchResult> DispatchDueNotificationsAsync();
        Task<NotificationDispatchResult> DispatchAllPendingAsync();
    }

    public class NotificationDispatchResult
    {
        public int TotalProcessed { get; set; }
        public int NotificationsCreated { get; set; }
        public int PushSent { get; set; }
        public int PushFailed { get; set; }
        public int Skipped { get; set; }
        public string Summary { get; set; } = string.Empty;
    }
}
