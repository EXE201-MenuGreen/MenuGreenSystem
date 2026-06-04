using System;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Configuration;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class SepayPaymentStatusCache : ISepayPaymentStatusCache
    {
        private const int DefaultTtlSeconds = 4;
        private const int MinTtlSeconds = 1;
        private const int MaxTtlSeconds = 30;

        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            PropertyNameCaseInsensitive = true
        };

        private readonly IDistributedCache _cache;
        private readonly TimeSpan _ttl;

        public SepayPaymentStatusCache(IDistributedCache cache, IConfiguration configuration)
        {
            _cache = cache;
            _ttl = TimeSpan.FromSeconds(ReadStatusCacheSeconds(configuration));
        }

        public async Task<SepayOrderResponse?> TryGetAsync(
            Guid userId,
            Guid paymentId,
            CancellationToken cancellationToken = default)
        {
            var bytes = await _cache.GetAsync(BuildKey(userId, paymentId), cancellationToken);
            if (bytes == null || bytes.Length == 0)
            {
                return null;
            }

            return JsonSerializer.Deserialize<SepayOrderResponse>(bytes, JsonOptions);
        }

        public Task SetAsync(
            Guid userId,
            Guid paymentId,
            SepayOrderResponse response,
            CancellationToken cancellationToken = default)
        {
            var bytes = JsonSerializer.SerializeToUtf8Bytes(response, JsonOptions);
            var options = new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = _ttl
            };

            return _cache.SetAsync(BuildKey(userId, paymentId), bytes, options, cancellationToken);
        }

        public Task InvalidateAsync(
            Guid userId,
            Guid paymentId,
            CancellationToken cancellationToken = default) =>
            _cache.RemoveAsync(BuildKey(userId, paymentId), cancellationToken);

        private static string BuildKey(Guid userId, Guid paymentId) =>
            $"sepay:status:{userId:N}:{paymentId:N}";

        private static int ReadStatusCacheSeconds(IConfiguration configuration)
        {
            var value = configuration["SePay:StatusCacheSeconds"];
            if (int.TryParse(value, out var seconds) && seconds >= MinTtlSeconds && seconds <= MaxTtlSeconds)
            {
                return seconds;
            }

            return DefaultTtlSeconds;
        }
    }
}
