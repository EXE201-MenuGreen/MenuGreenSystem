using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.SignalR;

namespace MenuGreen.API.Hubs
{
    public class NotificationHubService : INotificationHubService
    {
        private readonly IHubContext<NotificationHub> _hubContext;

        public NotificationHubService(IHubContext<NotificationHub> hubContext)
        {
            _hubContext = hubContext;
        }

        public async Task SendNotificationToUserAsync(Guid userId, NotificationResponse notification)
        {
            await _hubContext.Clients.User(userId.ToString()).SendAsync("ReceiveNotification", notification);
        }

        public async Task SendUnreadCountToUserAsync(Guid userId, int count)
        {
            await _hubContext.Clients.User(userId.ToString()).SendAsync("ReceiveUnreadCount", count);
        }
    }
}
