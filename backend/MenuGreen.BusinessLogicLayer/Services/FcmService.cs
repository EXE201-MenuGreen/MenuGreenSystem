using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Helpers;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.Extensions.Logging;
using FcmNotification = FirebaseAdmin.Messaging.Notification;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class FcmService : IFcmService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ILogger<FcmService> _logger;
        private readonly ICacheService _cache;
        private readonly bool _isFirebaseInitialized;
        private static readonly TimeSpan FcmTokenTtl = TimeSpan.FromMinutes(5);

        public FcmService(IUnitOfWork unitOfWork, ILogger<FcmService> logger, ICacheService cache)
        {
            _unitOfWork = unitOfWork;
            _logger = logger;
            _cache = cache;
            _isFirebaseInitialized = FirebaseApp.DefaultInstance != null;
        }

        public async Task<DeviceTokenResponse> RegisterTokenAsync(Guid userId, DeviceTokenRegisterRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Token))
            {
                throw new ArgumentException("Token is required.");
            }

            var existingToken = (await _unitOfWork.DeviceTokens.FindAsync(
                x => x.Token == request.Token)).FirstOrDefault();

            if (existingToken != null)
            {
                if (existingToken.UserId != userId)
                {
                    throw new InvalidOperationException("This token is already registered by another user.");
                }

                existingToken.LastUsedAt = DateTime.UtcNow;
                existingToken.DeviceType = request.DeviceType;
                existingToken.DeviceName = request.DeviceName;
                existingToken.AppVersion = request.AppVersion;
                existingToken.IsActive = true;
                existingToken.UpdatedAt = DateTime.UtcNow;

                _unitOfWork.DeviceTokens.Update(existingToken);
            }
            else
            {
                var newToken = new DeviceToken
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Token = request.Token,
                    DeviceType = request.DeviceType,
                    DeviceName = request.DeviceName,
                    AppVersion = request.AppVersion,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    LastUsedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                await _unitOfWork.DeviceTokens.AddAsync(newToken);
                existingToken = newToken;
            }

            await _unitOfWork.CompleteAsync();

            // Invalidate FCM token cache
            await _cache.RemoveAsync(CacheKeys.UserFcmTokens(userId));

            return MapToResponse(existingToken);
        }

        public async Task<bool> RemoveTokenAsync(Guid userId, string token)
        {
            var tokens = await _unitOfWork.DeviceTokens.FindAsync(
                x => x.UserId == userId && x.Token == token);

            var tokenEntity = tokens.FirstOrDefault();
            if (tokenEntity == null)
            {
                return false;
            }

            _unitOfWork.DeviceTokens.Remove(tokenEntity);
            await _unitOfWork.CompleteAsync();

            // Invalidate FCM token cache
            await _cache.RemoveAsync(CacheKeys.UserFcmTokens(userId));
            return true;
        }

        public async Task<IEnumerable<DeviceTokenResponse>> GetUserTokensAsync(Guid userId)
        {
            var cacheKey = CacheKeys.UserFcmTokens(userId);
            var cached = await _cache.GetAsync<List<DeviceTokenResponse>>(cacheKey);
            if (cached != null)
            {
                return cached;
            }

            var tokens = await _unitOfWork.DeviceTokens.FindAsync(
                x => x.UserId == userId && x.IsActive);

            var response = tokens.Select(MapToResponse).ToList();
            await _cache.SetAsync(cacheKey, response, FcmTokenTtl);
            return response;
        }

        public async Task<FcmSendResponse> SendToUserAsync(Guid userId, string title, string body, string? data = null)
        {
            // Use cached tokens
            var tokens = (await GetUserTokensAsync(userId)).ToList();

            // Dedupe và loại bỏ token quá cũ: nếu một user đăng nhập trên nhiều
            // thiết bị (hoặc token đã rotate mà token cũ chưa được deactivate),
            // FCM sẽ gửi push đến MỖI token. Điều này khiến user nhận 2+ push
            // cho cùng 1 notification (vẫn chỉ 1 record trong tab Thông báo).
            // - Distinct: tránh trùng token trong DB hiếm gặp.
            // - LastUsedAt > 30 ngày: skip token coi như đã chết (rotation / user
            //   đã logout thiết bị đó).
            var tokenList = tokens
                .Where(t => t.LastUsedAt.HasValue && (DateTime.UtcNow - t.LastUsedAt.Value).TotalDays <= 30)
                .GroupBy(t => t.Token)
                .Select(g => g.OrderByDescending(t => t.LastUsedAt ?? DateTime.MinValue).First())
                .ToList();

            if (tokenList.Count == 0)
            {
                return new FcmSendResponse
                {
                    SuccessCount = 0,
                    FailureCount = 0,
                    Message = "No active device tokens found for user."
                };
            }

            return await SendFcmMessageAsync(tokenList.Select(x => x.Token).ToList(), title, body, data);
        }

        public async Task<FcmSendResponse> SendToUsersAsync(IEnumerable<Guid> userIds, string title, string body, string? data = null)
        {
            var allTokens = new List<DeviceToken>();
            var usersWithoutToken = 0;

            foreach (var userId in userIds)
            {
                var tokens = await _unitOfWork.DeviceTokens.FindAsync(
                    x => x.UserId == userId && x.IsActive);

                // Dedupe token quá cũ và trùng lặp (xem comment ở SendToUserAsync).
                var tokenList = tokens
                    .Where(t => t.LastUsedAt.HasValue && (DateTime.UtcNow - t.LastUsedAt.Value).TotalDays <= 30)
                    .GroupBy(t => t.Token)
                    .Select(g => g.OrderByDescending(t => t.LastUsedAt ?? DateTime.MinValue).First())
                    .ToList();

                if (tokenList.Count == 0)
                {
                    usersWithoutToken++;
                }
                else
                {
                    allTokens.AddRange(tokenList);
                }
            }

            if (allTokens.Count == 0)
            {
                return new FcmSendResponse
                {
                    SuccessCount = 0,
                    FailureCount = usersWithoutToken,
                    Message = "No active device tokens found."
                };
            }

            var distinctTokens = allTokens
                .GroupBy(t => t.Token)
                .Select(g => g.OrderByDescending(t => t.LastUsedAt ?? DateTime.MinValue).First())
                .ToList();

            var result = await SendFcmMessageAsync(distinctTokens.Select(x => x.Token).ToList(), title, body, data);
            result.FailureCount += usersWithoutToken;
            return result;
        }

        public async Task<int> SendTestNotificationAsync()
        {
            if (!_isFirebaseInitialized)
            {
                _logger.LogWarning("Firebase is not initialized. Skipping test notification.");
                return 0;
            }

            try
            {
                var message = new Message
                {
                    Notification = new FcmNotification
                    {
                        Title = "MenuGreen Test",
                        Body = "Push notification is working!"
                    },
                    Topic = "test"
                };

                var messageId = await FirebaseMessaging.DefaultInstance.SendAsync(message);
                _logger.LogInformation("Test notification sent successfully. MessageId: {MessageId}", messageId);
                return 1;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send test notification.");
                return 0;
            }
        }

        private async Task<FcmSendResponse> SendFcmMessageAsync(List<string> tokens, string title, string body, string? data)
        {
            if (!_isFirebaseInitialized)
            {
                _logger.LogWarning("Firebase is not initialized. Message will not be sent.");
                return new FcmSendResponse
                {
                    SuccessCount = 0,
                    FailureCount = tokens.Count,
                    Message = "Firebase is not initialized. Check Firebase credential configuration."
                };
            }

            try
            {
                var messages = tokens.Select(token => new Message
                {
                    Token = token,
                    Notification = new FcmNotification
                    {
                        Title = title,
                        Body = body
                    },
                    Data = string.IsNullOrEmpty(data) ? null : new Dictionary<string, string>
                    {
                        { "custom_data", data }
                    },
                    Android = new AndroidConfig
                    {
                        Priority = Priority.High,
                        Notification = new AndroidNotification
                        {
                            Icon = "ic_notification",
                            Color = "#4CAF50"
                        }
                    }
                }).ToList();

                var batchResponse = await FirebaseMessaging.DefaultInstance.SendEachAsync(messages);

                var successCount = batchResponse.SuccessCount;
                var failureCount = batchResponse.FailureCount;

                foreach (var response in batchResponse.Responses)
                {
                    if (!response.IsSuccess)
                    {
                        _logger.LogWarning("FCM send failed for token: {Error}", response.Exception?.Message);
                    }
                }

                return new FcmSendResponse
                {
                    SuccessCount = successCount,
                    FailureCount = failureCount,
                    Message = $"Sent {successCount} notifications successfully, {failureCount} failed."
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send FCM messages.");
                return new FcmSendResponse
                {
                    SuccessCount = 0,
                    FailureCount = tokens.Count,
                    Message = $"Error sending FCM messages: {ex.Message}"
                };
            }
        }

        private static DeviceTokenResponse MapToResponse(DeviceToken token)
        {
            return new DeviceTokenResponse
            {
                Id = token.Id,
                Token = token.Token,
                DeviceType = token.DeviceType,
                DeviceName = token.DeviceName,
                AppVersion = token.AppVersion,
                IsActive = token.IsActive,
                CreatedAt = token.CreatedAt,
                LastUsedAt = token.LastUsedAt
            };
        }
    }
}
