# Redis/Valkey Caching Documentation - MenuGreen

## Overview

Hệ thống đã tích hợp Redis (Valkey) cache sử dụng AWS ElastiCache với fallback sang DistributedMemoryCache khi Redis không khả dụng.

## Configuration

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `REDIS_URL` | Full Redis connection string | `redis://menugreen-redis-p9zkb6.serverless.apse1.cache.amazonaws.com:6379` |
| `REDIS_HOST` | Redis host only | `menugreen-redis-p9zkb6.serverless.apse1.cache.amazonaws.com` |
| `REDIS_PORT` | Redis port | `6379` |

### appsettings.json

```json
{
  "Redis": {
    "ConnectionString": "your-redis-connection-string"
  }
}
```

### Fallback Behavior

```csharp
// Program.cs - Lines 54-69
if (!string.IsNullOrWhiteSpace(redisConnection))
{
    builder.Services.AddStackExchangeRedisCache(options =>
    {
        options.Configuration = redisConnection;
        options.InstanceName = "MenuGreen:";
    });
}
else
{
    builder.Services.AddDistributedMemoryCache(); // Fallback
}
```

Khi `REDIS_URL` không được set, hệ thống tự động dùng `DistributedMemoryCache` (in-memory cache). Điều này hữu ích trong môi trường development.

---

## Cache Service Architecture

### Files Structure

```
backend/MenuGreen.BusinessLogicLayer/
├── Interfaces/
│   ├── ICacheService.cs              # Cache service interface
│   └── ICacheInvalidationService.cs # Cache invalidation interface
├── Services/
│   ├── RedisCacheService.cs          # Redis implementation
│   └── CacheInvalidationService.cs  # Cache invalidation implementation
└── Helpers/
    └── CacheKeyBuilder.cs            # Centralized cache key definitions
```

### ICacheService Interface

```csharp
public interface ICacheService
{
    Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken = default);
    Task SetAsync<T>(string key, T value, TimeSpan ttl, CancellationToken cancellationToken = default);
    Task RemoveAsync(string key, CancellationToken cancellationToken = default);
    Task<T> GetOrSetAsync<T>(string key, Func<Task<T>> factory, TimeSpan ttl);
    Task<bool> ExistsAsync(string key, CancellationToken cancellationToken = default);
}
```

### CacheKeyBuilder - Centralized Keys

Tất cả cache keys được định nghĩa tập trung trong `CacheKeyBuilder.cs`:

```csharp
public static class CacheKeys
{
    // User caches
    public static string UserAllergenKeys(Guid userId) => $"user:{userId}:allergen-keys:v1";
    public static string UserSubscription(Guid userId) => $"user:{userId}:subscription:active:v1";
    public static string UserHealthTargets(Guid userId) => $"user:{userId}:health-targets:v1";
    public static string UserFcmTokens(Guid userId) => $"user:{userId}:fcm-tokens:v1";

    // Food/Recipe caches
    public static string FoodAllergenKeys(Guid foodId) => $"food:{foodId}:allergen-keys:v1";
    public static string RecipeNutrition(Guid recipeId) => $"recipe:{recipeId}:nutrition:v1";

    // Daily usage caches
    public static string DailyStarter(Guid userId, DateTime date) => $"user:{userId}:daily-starter:{date:yyyy-MM-dd}:v1";
    public static string MealPlan(Guid userId, DateTime date) => $"user:{userId}:mealplan:{date:yyyy-MM-dd}:v1";

    // Catalog caches
    public static string SubscriptionPlans() => $"subscription:plans:active:v1";
}
```

---

## Implemented Caches

### 1. User Allergen Keys Cache

**Service:** `AllergenMatchingService`
**TTL:** 15 minutes
**Key Pattern:** `user:{userId}:allergen-keys:v1`

```csharp
public async Task<HashSet<string>> GetUserAllergenKeysAsync(Guid userId)
{
    var cacheKey = CacheKeys.UserAllergenKeys(userId);
    var cached = await _cache.GetAsync<UserAllergenCacheEntry>(cacheKey);
    if (cached != null) return cached.Keys;

    var keys = await QueryUserAllergenKeysAsync(userId);
    await _cache.SetAsync(cacheKey, new UserAllergenCacheEntry { Keys = keys }, UserAllergenTtl);
    return keys;
}
```

### 2. Food Allergen Keys Cache

**Service:** `AllergenMatchingService`
**TTL:** 30 minutes
**Key Pattern:** `food:{foodId}:allergen-keys:v1`

### 3. Food Catalog Cache

**Service:** `CatalogService`
**TTL:** 30 minutes
**Key Pattern:** `food:catalog:v1:{keyword}:{category}:{minCal}:{maxCal}`

### 4. Recipe Nutrition Cache

**Service:** `RecipeService`
**TTL:** 60 minutes
**Key Pattern:** `recipe:{recipeId}:nutrition:v1`

```csharp
public async Task<RecipeNutritionResponse> GetNutritionAsync(Guid recipeId)
{
    var cacheKey = CacheKeys.RecipeNutrition(recipeId);
    var cached = await _cache.GetAsync<RecipeNutritionResponse>(cacheKey);
    if (cached != null) return cached;

    // ... compute nutrition ...
    await _cache.SetAsync(cacheKey, result, NutritionTtl);
    return result;
}
```

### 5. Subscription Plans Cache

**Service:** `SubscriptionPlanService`
**TTL:** 24 hours
**Key Pattern:** `subscription:plans:active:v1`

### 6. User Subscription Cache

**Service:** `UserSubscriptionService`
**TTL:** 5 minutes
**Key Pattern:** `user:{userId}:subscription:active:v1`

### 7. User Health Targets Cache

**Service:** `HealthProfileService`
**TTL:** 15 minutes
**Key Pattern:** `user:{userId}:health-targets:v1`

### 8. FCM Tokens Cache

**Service:** `FcmService`
**TTL:** 5 minutes
**Key Pattern:** `user:{userId}:fcm-tokens:v1`

### 9. Daily Starter Cache

**Service:** `DailyStarterService`
**TTL:** 5 minutes
**Key Pattern:** `user:{userId}:daily-starter:{yyyy-MM-dd}:v1`

### 10. Featured Meals Cache

**Service:** `DailyStarterService`
**TTL:** 10 minutes
**Key Pattern:** `user:{userId}:featured-meals:v1`

### 11. Meal Plan Cache

**Service:** `MealPlanService`
**TTL:** 5 minutes
**Key Pattern:** `user:{userId}:mealplan:{yyyy-MM-dd}:v1`

---

## Cache TTL Summary

| Cache Type | TTL | Auto-Invalidation |
|------------|-----|-------------------|
| Subscription Plans | 24 hours | On create/update/delete |
| Recipe Nutrition | 60 minutes | On recipe update |
| Food Catalog | 30 minutes | On food CRUD |
| Food Allergen Keys | 30 minutes | On allergen set update |
| User Allergen Keys | 15 minutes | On user allergy update |
| User Health Targets | 15 minutes | On health profile update |
| Featured Meals | 10 minutes | Daily |
| User Subscription | 5 minutes | On subscribe/cancel/renew |
| FCM Tokens | 5 minutes | On token register/remove |
| Daily Starter | 5 minutes | Daily |
| Meal Plan | 5 minutes | On meal plan change |

---

## Cache Invalidation

### CacheInvalidationService

```csharp
public interface ICacheInvalidationService
{
    Task InvalidateUserCacheAsync(Guid userId);
    Task InvalidateCatalogCacheAsync();
    Task InvalidateRecipeCacheAsync(Guid recipeId);
    Task InvalidateFoodCacheAsync(Guid foodId);
    Task InvalidateAllUserDataAsync(Guid userId);
}
```

### Usage Examples

```csharp
// After user updates health profile
await _cache.RemoveAsync(CacheKeys.UserHealthTargets(userId));

// After user subscribes/cancels subscription
await _cache.RemoveAsync(CacheKeys.UserSubscription(userId));

// After recipe is updated
await _cache.RemoveAsync(CacheKeys.RecipeNutrition(recipeId));

// After food allergen tags are updated
await _cache.RemoveAsync(CacheKeys.FoodAllergenKeys(foodId));
```

---

## Health Check

Redis health check được tích hợp vào `/health` endpoint:

```csharp
// Program.cs - Lines 400-412
var healthCheckRedisConnection = Environment.GetEnvironmentVariable("REDIS_URL");

if (!string.IsNullOrWhiteSpace(healthCheckRedisConnection))
{
    builder
        .Services.AddHealthChecks()
        .AddRedis(healthCheckRedisConnection, name: "redis", tags: new[] { "cache", "ready" });
}
```

**Response Example:**
```json
{
  "status": "Healthy",
  "checks": [
    { "name": "self", "status": "Healthy", "duration": 0.5 },
    { "name": "postgresql", "status": "Healthy", "duration": 15.2 },
    { "name": "redis", "status": "Healthy", "duration": 3.1 }
  ]
}
```

---

## Testing Cache

### Test Cache Hit/Miss

```bash
# SSH vào server
ssh -i ~/.ssh/LightsailDefaultKey-ap-southeast-1.pem ubuntu@menugreen-api

# Check Redis keys
docker exec menugreen_api redis-cli KEYS "MenuGreen:*"

# Check specific key
docker exec menugreen_api redis-cli GET "MenuGreen:user:{userId}:allergen-keys:v1"

# Check TTL
docker exec menugreen_api redis-cli TTL "MenuGreen:user:{userId}:allergen-keys:v1"
```

### Check Health Endpoint

```bash
curl https://api.menugreen.food/health
```

---

## Monitoring

### Prometheus Metrics

Redis cache metrics được expose qua Prometheus endpoint `/metrics`:

- `distcache_cache_hits_total`
- `distcache_cache_misses_total`
- `distcache_cache_gets_total`
- `distcache_cache_sets_total`

---

## Troubleshooting

### 1. Cache Not Working

1. Check `REDIS_URL` environment variable is set
2. Verify Redis connection: `curl https://api.menugreen.food/health | jq .checks`
3. Check logs: `docker logs menugreen_api | grep -i redis`

### 2. Stale Data

1. Check if TTL expired
2. Manually invalidate cache if needed
3. Review invalidation logic in services

### 3. Redis Connection Timeout

1. Check VPC peering is configured
2. Verify security group allows port 6379
3. Test connection: `telnet menugreen-redis-xxx.amazonaws.com 6379`

---

## Development vs Production

| Environment | Cache Backend | Notes |
|-------------|--------------|-------|
| Development | DistributedMemoryCache | No Redis setup needed |
| Production | Redis (Valkey) | AWS ElastiCache |

Set `REDIS_URL` environment variable để enable Redis cache.

---

## Future Improvements

1. **Pattern-based invalidation:** Implement Redis SCAN for bulk invalidation
2. **Cache warming:** Pre-populate caches on startup for high-traffic data
3. **Cache metrics dashboard:** Grafana dashboard for cache hit/miss rates
4. **Distributed locking:** Prevent cache stampede with distributed locks
