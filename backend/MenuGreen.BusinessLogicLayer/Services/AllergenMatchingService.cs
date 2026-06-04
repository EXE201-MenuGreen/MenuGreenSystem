using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class AllergenMatchingService : IAllergenMatchingService
    {
        private readonly ApplicationDbContext _db;

        public AllergenMatchingService(ApplicationDbContext db)
        {
            _db = db;
        }

        public async Task<HashSet<string>> GetUserAllergenKeysAsync(Guid userId)
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

            var tags = await _db.FoodAllergenTags.AsNoTracking()
                .Where(t => ids.Contains(t.FoodId))
                .ToListAsync();

            foreach (var tag in tags)
            {
                if (result.TryGetValue(tag.FoodId, out var set))
                    set.Add(tag.AllergenKey);
            }

            var legacy = await _db.FoodAllergies.AsNoTracking()
                .Include(fa => fa.Allergy)
                .Where(fa => ids.Contains(fa.FoodId))
                .ToListAsync();

            foreach (var row in legacy)
            {
                var key = AllergenCatalog.NormalizeToKey(row.Allergy?.Name);
                if (key != null && result.TryGetValue(row.FoodId, out var set))
                    set.Add(key);
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
