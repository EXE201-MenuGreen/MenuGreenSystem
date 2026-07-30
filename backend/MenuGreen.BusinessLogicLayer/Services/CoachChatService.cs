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
    public class CoachChatService : ICoachChatService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICoachChatRealtimeService _realtime;
        private readonly INotificationService _notifications;

        public CoachChatService(
            IUnitOfWork unitOfWork,
            ICoachChatRealtimeService realtime,
            INotificationService notifications)
        {
            _unitOfWork = unitOfWork;
            _realtime = realtime;
            _notifications = notifications;
        }

        public async Task<IEnumerable<CoachChatPartnerResponse>> GetPartnersAsync(
            Guid userId,
            string? scope = null)
        {
            var connections = await GetScopedConnectionsAsync(userId, scope);
            var partnerIds = connections
                .Select(connection =>
                    connection.ClientId == userId ? connection.CoachId : connection.ClientId)
                .Distinct()
                .ToList();
            if (partnerIds.Count == 0) return Array.Empty<CoachChatPartnerResponse>();

            var profiles = (await _unitOfWork.Profiles.FindAsync(profile =>
                partnerIds.Contains(profile.UserId)))
                .ToDictionary(profile => profile.UserId);
            var users = (await _unitOfWork.Users.FindAsync(user =>
                partnerIds.Contains(user.Id)))
                .ToDictionary(user => user.Id);
            var messages = (await _unitOfWork.CoachChatMessages.FindAsync(message =>
                (message.SenderId == userId
                    && partnerIds.Contains(message.ReceiverId))
                || (message.ReceiverId == userId
                    && partnerIds.Contains(message.SenderId))))
                .ToList();

            return partnerIds
                .Select(partnerId =>
                {
                    var conversationMessages = messages
                        .Where(message =>
                            (message.SenderId == userId && message.ReceiverId == partnerId)
                            || (message.SenderId == partnerId && message.ReceiverId == userId))
                        .OrderByDescending(message => message.SentAt)
                        .ToList();
                    var last = conversationMessages.FirstOrDefault();
                    profiles.TryGetValue(partnerId, out var profile);
                    users.TryGetValue(partnerId, out var user);
                    return new CoachChatPartnerResponse
                    {
                        PartnerId = partnerId,
                        FullName = profile?.FullName ?? user?.Email ?? "PT / Gymer",
                        AvatarUrl = profile?.AvatarUrl,
                        LastMessage = last?.Content,
                        LastMessageAt = last?.SentAt,
                        UnreadCount = conversationMessages.Count(message =>
                            message.ReceiverId == userId && message.ReadAt == null)
                    };
                })
                .OrderByDescending(partner => partner.LastMessageAt)
                .ThenBy(partner => partner.FullName)
                .ToList();
        }

        public async Task<IEnumerable<CoachChatMessageResponse>> GetMessagesAsync(
            Guid userId,
            Guid partnerId,
            DateTimeOffset? before,
            int take)
        {
            await EnsureConnectedAsync(userId, partnerId);
            take = Math.Clamp(take, 1, 100);
            var messages = await _unitOfWork.CoachChatMessages.FindAsync(message =>
                ((message.SenderId == userId && message.ReceiverId == partnerId)
                 || (message.SenderId == partnerId && message.ReceiverId == userId))
                && (!before.HasValue || message.SentAt < before.Value));

            return messages
                .OrderByDescending(message => message.SentAt)
                .Take(take)
                .OrderBy(message => message.SentAt)
                .Select(message => Map(message, userId))
                .ToList();
        }

        public async Task<CoachChatMessageResponse> SendMessageAsync(
            Guid userId,
            Guid partnerId,
            string content)
        {
            await EnsureConnectedAsync(userId, partnerId);
            var normalizedContent = (content ?? string.Empty).Trim();
            if (normalizedContent.Length == 0)
                throw new ArgumentException("Tin nhắn không được để trống.");
            if (normalizedContent.Length > 2000)
                throw new ArgumentException("Tin nhắn không được vượt quá 2000 ký tự.");

            var message = new CoachChatMessage
            {
                Id = Guid.NewGuid(),
                SenderId = userId,
                ReceiverId = partnerId,
                Content = normalizedContent,
                SentAt = DateTimeOffset.UtcNow
            };
            await _unitOfWork.CoachChatMessages.AddAsync(message);
            await _unitOfWork.CompleteAsync();

            var senderProfile = (await _unitOfWork.Profiles.FindAsync(profile =>
                profile.UserId == userId)).FirstOrDefault();
            var senderUser = await _unitOfWork.Users.GetByIdAsync(userId, asNoTracking: true);
            var senderName = senderProfile?.FullName ?? senderUser?.Email ?? "PT / Gymer";

            var receiverPayload = Map(message, partnerId);
            await _realtime.SendMessageToUserAsync(partnerId, receiverPayload);
            await _realtime.SendUnreadCountToUserAsync(
                partnerId,
                await GetUnreadCountAsync(partnerId));

            await _notifications.SendAsync(new NotificationSendRequest
            {
                UserId = partnerId,
                Type = "coach_chat_message",
                Title = $"Tin nhắn mới từ {senderName}",
                Body = normalizedContent,
                ActionUrl = $"chat:{userId}",
                ScheduledAt = DateTimeOffset.UtcNow
            });

            return Map(message, userId);
        }

        public async Task<int> MarkConversationReadAsync(Guid userId, Guid partnerId)
        {
            await EnsureConnectedAsync(userId, partnerId);
            var unread = (await _unitOfWork.CoachChatMessages.FindAsync(message =>
                message.SenderId == partnerId
                && message.ReceiverId == userId
                && message.ReadAt == null))
                .ToList();
            if (unread.Count > 0)
            {
                var now = DateTimeOffset.UtcNow;
                foreach (var message in unread)
                {
                    message.ReadAt = now;
                    _unitOfWork.CoachChatMessages.Update(message);
                }
                await _unitOfWork.CompleteAsync();
            }
            await _realtime.SendUnreadCountToUserAsync(
                userId,
                await GetUnreadCountAsync(userId));
            return unread.Count;
        }

        public async Task<int> GetUnreadCountAsync(
            Guid userId,
            string? scope = null)
        {
            var connections = await GetScopedConnectionsAsync(userId, scope);
            var partnerIds = connections
                .Select(connection =>
                    connection.ClientId == userId
                        ? connection.CoachId
                        : connection.ClientId)
                .Distinct()
                .ToList();
            if (partnerIds.Count == 0) return 0;

            return (await _unitOfWork.CoachChatMessages.FindAsync(message =>
                message.ReceiverId == userId
                && partnerIds.Contains(message.SenderId)
                && message.ReadAt == null)).Count();
        }

        private async Task<List<CoachConnection>> GetScopedConnectionsAsync(
            Guid userId,
            string? scope)
        {
            var normalizedScope = (scope ?? string.Empty)
                .Trim()
                .ToLowerInvariant();
            if (normalizedScope == "gymer")
            {
                return (await _unitOfWork.CoachConnections.FindAsync(connection =>
                    connection.Status == "Connected"
                    && connection.ClientId == userId))
                    .ToList();
            }
            if (normalizedScope == "coach")
            {
                return (await _unitOfWork.CoachConnections.FindAsync(connection =>
                    connection.Status == "Connected"
                    && connection.CoachId == userId))
                    .ToList();
            }

            return (await _unitOfWork.CoachConnections.FindAsync(connection =>
                connection.Status == "Connected"
                && (connection.ClientId == userId || connection.CoachId == userId)))
                .ToList();
        }

        private async Task EnsureConnectedAsync(Guid userId, Guid partnerId)
        {
            if (userId == partnerId)
                throw new UnauthorizedAccessException("Không thể tự nhắn tin cho chính mình.");

            var connection = (await _unitOfWork.CoachConnections.FindAsync(item =>
                item.Status == "Connected"
                && ((item.ClientId == userId && item.CoachId == partnerId)
                    || (item.CoachId == userId && item.ClientId == partnerId))))
                .FirstOrDefault();
            if (connection == null)
                throw new UnauthorizedAccessException(
                    "Chỉ PT và Gymer đã kết nối mới có thể nhắn tin.");
        }

        private static CoachChatMessageResponse Map(CoachChatMessage message, Guid viewerId)
        {
            return new CoachChatMessageResponse
            {
                Id = message.Id,
                SenderId = message.SenderId,
                ReceiverId = message.ReceiverId,
                Content = message.Content,
                SentAt = message.SentAt,
                ReadAt = message.ReadAt,
                IsMine = message.SenderId == viewerId
            };
        }
    }
}
