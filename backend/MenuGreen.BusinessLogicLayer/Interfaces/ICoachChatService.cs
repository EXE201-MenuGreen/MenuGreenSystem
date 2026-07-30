using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface ICoachChatService
    {
        Task<IEnumerable<CoachChatPartnerResponse>> GetPartnersAsync(
            Guid userId,
            string? scope = null);
        Task<IEnumerable<CoachChatMessageResponse>> GetMessagesAsync(
            Guid userId,
            Guid partnerId,
            DateTimeOffset? before,
            int take);
        Task<CoachChatMessageResponse> SendMessageAsync(
            Guid userId,
            Guid partnerId,
            string content);
        Task<int> MarkConversationReadAsync(Guid userId, Guid partnerId);
        Task<int> GetUnreadCountAsync(Guid userId, string? scope = null);
    }
}
