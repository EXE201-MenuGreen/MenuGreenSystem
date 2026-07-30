using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface ICoachChatRealtimeService
    {
        Task SendMessageToUserAsync(Guid userId, CoachChatMessageResponse message);
        Task SendUnreadCountToUserAsync(Guid userId, int count);
    }
}
