using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface INotificationHubService
    {
        Task SendNotificationToUserAsync(Guid userId, NotificationResponse notification);
        Task SendUnreadCountToUserAsync(Guid userId, int count);
    }
}
