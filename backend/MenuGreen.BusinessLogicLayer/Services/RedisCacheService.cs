using System;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.Extensions.Caching.Distributed;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class RedisCacheService : ICacheService
    {
        private readonly IDistributedCache _cache;
        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            PropertyNameCaseInsensitive = true
        };

        public RedisCacheService(IDistributedCache cache)
        {
            _cache = cache;
        }

        public async Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken = default) where T : class
        {
            var bytes = await _cache.GetAsync(key, cancellationToken);
            if (bytes == null || bytes.Length == 0)
            {
                return null;
            }

            return JsonSerializer.Deserialize<T>(bytes, JsonOptions);
        }

        public Task SetAsync<T>(string key, T value, TimeSpan ttl, CancellationToken cancellationToken = default) where T : class
        {
            var options = new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = ttl
            };
            var bytes = JsonSerializer.SerializeToUtf8Bytes(value, JsonOptions);
            return _cache.SetAsync(key, bytes, options, cancellationToken);
        }

        public async Task SetAsync<T>(string key, T value, CacheEntryOptions options, CancellationToken cancellationToken = default) where T : class
        {
            var bytes = JsonSerializer.SerializeToUtf8Bytes(value, JsonOptions);
            var distOptions = ConvertOptions(options);
            await _cache.SetAsync(key, bytes, distOptions, cancellationToken);
        }

        public Task RemoveAsync(string key, CancellationToken cancellationToken = default)
        {
            return _cache.RemoveAsync(key, cancellationToken);
        }

        public async Task<T> GetOrSetAsync<T>(
            string key,
            Func<Task<T>> factory,
            TimeSpan ttl,
            CancellationToken cancellationToken = default) where T : class
        {
            return await GetOrSetAsync(key, _ => factory(), ttl, cancellationToken);
        }

        public async Task<T> GetOrSetAsync<T>(
            string key,
            Func<CancellationToken, Task<T>> factory,
            TimeSpan ttl,
            CancellationToken cancellationToken = default) where T : class
        {
            var cached = await GetAsync<T>(key, cancellationToken);
            if (cached != null)
            {
                return cached;
            }

            var value = await factory(cancellationToken);
            await SetAsync(key, value, ttl, cancellationToken);
            return value;
        }

        public async Task<bool> ExistsAsync(string key, CancellationToken cancellationToken = default)
        {
            var bytes = await _cache.GetAsync(key, cancellationToken);
            return bytes != null && bytes.Length > 0;
        }

        private static DistributedCacheEntryOptions ConvertOptions(CacheEntryOptions options)
        {
            return new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = options.AbsoluteExpirationRelativeToNow,
                AbsoluteExpiration = options.AbsoluteExpiration,
                SlidingExpiration = options.SlidingExpiration
            };
        }
    }
}
