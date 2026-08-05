using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Helpers;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class AllergenMatchingService : IAllergenMatchingService
    {
        private readonly ApplicationDbContext _db;
        private readonly ICacheService _cache;
        private static readonly TimeSpan UserAllergenTtl = TimeSpan.FromMinutes(15);
        private static readonly TimeSpan FoodAllergenTtl = TimeSpan.FromMinutes(30);

        public AllergenMatchingService(ApplicationDbContext db, ICacheService cache)
        {
            _db = db;
            _cache = cache;
        }

        public async Task<HashSet<string>> GetUserAllergenKeysAsync(Guid userId)
        {
            var cacheKey = CacheKeys.UserAllergenKeys(userId);
            var cached = await _cache.GetAsync<UserAllergenCacheEntry>(cacheKey);
            if (cached != null)
            {
                return cached.Keys;
            }

            var keys = await QueryUserAllergenKeysAsync(userId);
            await _cache.SetAsync(cacheKey, new UserAllergenCacheEntry { Keys = keys }, UserAllergenTtl);
            return keys;
        }

        private async Task<HashSet<string>> QueryUserAllergenKeysAsync(Guid userId)
        {
            var names = await _db.Allergies.AsNoTracking()
                .Where(a => a.UserId == userId && a.IsActive)
                .Select(a => a.Name)
                .ToListAsync();

            var keys = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var name in names)
            {
                var key = AllergenCatalog.NormalizeToKey(name);
                if (!string.IsNullOrEmpty(key)) keys.Add(key);
            }

            return keys;
        }

        public async Task<Dictionary<Guid, HashSet<string>>> GetFoodAllergenKeysAsync(IEnumerable<Guid> foodIds)
        {
            var ids = foodIds.Distinct().ToList();
            var result = ids.ToDictionary(id => id, _ => new HashSet<string>(StringComparer.OrdinalIgnoreCase));
            if (ids.Count == 0) return result;

            var cachedDict = new Dictionary<Guid, HashSet<string>>();
            var uncachedIds = new List<Guid>();

            foreach (var id in ids)
            {
                var cacheKey = CacheKeys.FoodAllergenKeys(id);
                var cached = await _cache.GetAsync<FoodAllergenCacheEntry>(cacheKey);
                if (cached != null)
                {
                    cachedDict[id] = cached.Keys;
                }
                else
                {
                    uncachedIds.Add(id);
                }
            }

            foreach (var kvp in cachedDict)
            {
                if (result.ContainsKey(kvp.Key))
                    result[kvp.Key] = kvp.Value;
            }

            if (uncachedIds.Count > 0)
            {
                var dbTags = await _db.FoodAllergenTags.AsNoTracking()
                    .Where(t => uncachedIds.Contains(t.FoodId))
                    .ToListAsync();

                var dbLegacy = await _db.FoodAllergies.AsNoTracking()
                    .Include(fa => fa.Allergy)
                    .Where(fa => uncachedIds.Contains(fa.FoodId))
                    .ToListAsync();

                foreach (var id in uncachedIds)
                {
                    var keys = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                    var tagKeys = dbTags.Where(t => t.FoodId == id).Select(t => t.AllergenKey);
                    foreach (var k in tagKeys) keys.Add(k);

                    var legacyKeys = dbLegacy.Where(fa => fa.FoodId == id)
                        .Select(fa => AllergenCatalog.NormalizeToKey(fa.Allergy?.Name))
                        .Where(k => k != null);
                    foreach (var k in legacyKeys) keys.Add(k!);

                    result[id] = keys;
                    await _cache.SetAsync(CacheKeys.FoodAllergenKeys(id), new FoodAllergenCacheEntry { Keys = keys }, FoodAllergenTtl);
                }
            }

            return result;
        }

        public async Task<HashSet<string>> GetFoodAllergenKeysAsync(Guid foodId)
        {
            var map = await GetFoodAllergenKeysAsync(new[] { foodId });
            return map.TryGetValue(foodId, out var keys) ? keys : new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        }

        public async Task<IReadOnlyList<string>> GetFoodAllergenKeysListAsync(Guid foodId)
        {
            var keys = await GetFoodAllergenKeysAsync(foodId);
            return keys.OrderBy(k => k).ToList();
        }

        public async Task SetFoodAllergenKeysAsync(Guid foodId, IEnumerable<string> allergenKeys)
        {
            var normalized = allergenKeys
                .Select(k => AllergenCatalog.NormalizeToKey(k) ?? k?.Trim().ToLowerInvariant())
                .Where(k => !string.IsNullOrWhiteSpace(k) && AllergenCatalog.AllKeys.Any(ak => string.Equals(ak, k, StringComparison.OrdinalIgnoreCase)))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            var existing = await _db.FoodAllergenTags.Where(t => t.FoodId == foodId).ToListAsync();
            _db.FoodAllergenTags.RemoveRange(existing);

            foreach (var key in normalized)
            {
                _db.FoodAllergenTags.Add(new FoodAllergenTag
                {
                    FoodId = foodId,
                    AllergenKey = key!
                });
            }

            await _db.SaveChangesAsync();

            await _cache.RemoveAsync(CacheKeys.FoodAllergenKeys(foodId));
        }

        public async Task InvalidateUserAllergenCacheAsync(Guid userId)
        {
            await _cache.RemoveAsync(CacheKeys.UserAllergenKeys(userId));
        }

        public async Task InvalidateFoodAllergenCacheAsync(Guid foodId)
        {
            await _cache.RemoveAsync(CacheKeys.FoodAllergenKeys(foodId));
        }

        private class UserAllergenCacheEntry
        {
            public HashSet<string> Keys { get; set; } = new();
        }

        private class FoodAllergenCacheEntry
        {
            public HashSet<string> Keys { get; set; } = new();
        }

        public async Task<AllergenRiskResult> EvaluateFoodRiskAsync(Guid foodId, Guid? userId)
        {
            if (!userId.HasValue)
                return SafeResult();

            var userKeys = await GetUserAllergenKeysAsync(userId.Value);
            if (userKeys.Count == 0)
                return SafeResult();

            var foodKeys = await GetFoodAllergenKeysAsync(foodId);
            var matched = userKeys.Where(foodKeys.Contains).ToHashSet(StringComparer.OrdinalIgnoreCase);
            return ToRiskResult(matched);
        }

        public async Task<Dictionary<Guid, AllergenRiskResult>> EvaluateFoodRiskBatchAsync(IEnumerable<Guid> foodIds, Guid? userId)
        {
            var ids = foodIds.Distinct().ToList();
            var result = ids.ToDictionary(id => id, _ => SafeResult());
            if (ids.Count == 0 || !userId.HasValue)
                return result;

            var userKeys = await GetUserAllergenKeysAsync(userId.Value);
            if (userKeys.Count == 0)
                return result;

            var foodAllergenMap = await GetFoodAllergenKeysAsync(ids);
            foreach (var (foodId, foodKeys) in foodAllergenMap)
            {
                var matched = userKeys.Where(foodKeys.Contains).ToHashSet(StringComparer.OrdinalIgnoreCase);
                result[foodId] = ToRiskResult(matched);
            }

            return result;
        }

        public async Task<AllergenRiskResult> EvaluateRecipeRiskAsync(
            Guid? foodId,
            IEnumerable<string> ingredientNamesVi,
            Guid? userId)
        {
            if (!userId.HasValue)
                return SafeResult();

            var userKeys = await GetUserAllergenKeysAsync(userId.Value);
            if (userKeys.Count == 0)
                return SafeResult();

            var matched = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            if (foodId.HasValue)
            {
                var foodKeys = await GetFoodAllergenKeysAsync(foodId.Value);
                foreach (var uk in userKeys.Where(foodKeys.Contains))
                    matched.Add(uk);
            }

            var fromIngredients = AllergenCatalog.MatchUserKeysInTexts(ingredientNamesVi, userKeys);
            foreach (var k in fromIngredients)
                matched.Add(k);

            return ToRiskResult(matched);
        }

        public async Task<AllergenRiskResult> EvaluateIngredientRiskAsync(string nameVi, string? nameEn, Guid? userId)
        {
            if (!userId.HasValue)
                return SafeResult();

            var userKeys = await GetUserAllergenKeysAsync(userId.Value);
            if (userKeys.Count == 0)
                return SafeResult();

            var texts = new List<string>();
            if (!string.IsNullOrWhiteSpace(nameVi)) texts.Add(nameVi);
            if (!string.IsNullOrWhiteSpace(nameEn)) texts.Add(nameEn);

            var matched = AllergenCatalog.MatchUserKeysInTexts(texts, userKeys);
            return ToRiskResult(matched.ToHashSet(StringComparer.OrdinalIgnoreCase));
        }

        private static AllergenRiskResult SafeResult() => new()
        {
            AllergyRiskLevel = AllergenCatalog.RiskNone,
            IsSafeForUser = true
        };

        private static AllergenRiskResult ToRiskResult(HashSet<string> matchedKeys)
        {
            var labels = AllergenCatalog.ToDisplayNamesVi(matchedKeys).ToList();
            var risk = AllergenCatalog.ComputeRiskLevel(matchedKeys.Count > 0);
            return new AllergenRiskResult
            {
                MatchedAllergens = labels,
                AllergyRiskLevel = risk,
                IsSafeForUser = AllergenCatalog.IsSafeForUser(risk)
            };
        }
    }
}
