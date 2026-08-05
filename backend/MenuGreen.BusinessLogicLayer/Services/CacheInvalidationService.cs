using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Helpers;
using MenuGreen.BusinessLogicLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class CacheInvalidationService : ICacheInvalidationService
    {
        private readonly ICacheService _cache;

        public CacheInvalidationService(ICacheService cache)
        {
            _cache = cache;
        }

        public async Task InvalidateUserCacheAsync(Guid userId)
        {
            // Invalidate user-specific caches
            await _cache.RemoveAsync(CacheKeys.UserAllergenKeys(userId));
            await _cache.RemoveAsync(CacheKeys.UserSubscription(userId));
            await _cache.RemoveAsync(CacheKeys.UserHealthTargets(userId));
            await _cache.RemoveAsync(CacheKeys.UserFcmTokens(userId));
            await _cache.RemoveAsync(CacheKeys.UserAiContext(userId));
            await _cache.RemoveAsync(CacheKeys.UserAiProfile(userId));

            // Invalidate daily usage caches (today + 7 days)
            var today = DateTime.UtcNow.Date;
            for (int i = 0; i < 7; i++)
            {
                var date = today.AddDays(i);
                await _cache.RemoveAsync(CacheKeys.DailyStarter(userId, date));
                await _cache.RemoveAsync(CacheKeys.MealPlan(userId, date));
                await _cache.RemoveAsync(CacheKeys.CaloriesRemaining(userId, date));
                await _cache.RemoveAsync(CacheKeys.UserSnapshot(userId, date));
                await _cache.RemoveAsync(CacheKeys.UserDailySummary(userId, date));
            }

            await _cache.RemoveAsync(CacheKeys.FeaturedMeals(userId));
        }

        public async Task InvalidateCatalogCacheAsync()
        {
            // For catalog caches, we invalidate by removing known patterns
            // Note: Pattern-based invalidation requires Redis SCAN which is not 
            // directly available via IDistributedCache. For simplicity, catalog 
            // caches have short TTLs (30 min) so they auto-expire.
            // For immediate invalidation, services should call their own invalidation.
            await Task.CompletedTask;
        }

        public async Task InvalidateRecipeCacheAsync(Guid recipeId)
        {
            await _cache.RemoveAsync(CacheKeys.RecipeNutrition(recipeId));
            // Note: Recipe catalog cache invalidation is handled by TTL
        }

        public async Task InvalidateFoodCacheAsync(Guid foodId)
        {
            await _cache.RemoveAsync(CacheKeys.FoodAllergenKeys(foodId));
            // Note: Food catalog cache invalidation is handled by TTL
        }

        public async Task InvalidateAllUserDataAsync(Guid userId)
        {
            await InvalidateUserCacheAsync(userId);
            // Invalidate coach-related caches if this user is a coach
            await _cache.RemoveAsync(CacheKeys.CoachClients(userId));
        }
    }
}
