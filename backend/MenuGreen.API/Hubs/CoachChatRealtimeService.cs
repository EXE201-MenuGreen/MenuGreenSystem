using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.SignalR;

namespace MenuGreen.API.Hubs
{
    public class CoachChatRealtimeService : ICoachChatRealtimeService
    {
        private readonly IHubContext<NotificationHub> _hubContext;

        public CoachChatRealtimeService(IHubContext<NotificationHub> hubContext)
        {
            _hubContext = hubContext;
        }

        public Task SendMessageToUserAsync(Guid userId, CoachChatMessageResponse message)
        {
            return _hubContext.Clients.User(userId.ToString())
                .SendAsync("ReceiveChatMessage", message);
        }

        public Task SendUnreadCountToUserAsync(Guid userId, int count)
        {
            return _hubContext.Clients.User(userId.ToString())
                .SendAsync("ReceiveChatUnreadCount", count);
        }
    }
}
