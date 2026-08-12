using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Helpers;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Context;
using Microsoft.EntityFrameworkCore;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class PortionNutritionCalculator : IPortionNutritionCalculator
    {
        private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
        private readonly ApplicationDbContext _db;

        public PortionNutritionCalculator(ApplicationDbContext db)
        {
            _db = db;
        }

        public async Task<PortionNutritionResponse> CalculateRecipeAsync(
            Guid recipeId,
            IReadOnlyCollection<MealPlanIngredientPortionRequest>? portions = null)
        {
            var recipe = await _db.Recipes.AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == recipeId)
                ?? throw new InvalidOperationException("Không tìm thấy công thức.");

            var rows = await _db.RecipeIngredients.AsNoTracking()
                .Include(x => x.Ingredient)
                .Where(x => x.RecipeId == recipeId)
                .ToListAsync();
            if (rows.Count == 0)
            {
                if (recipe.FoodId.HasValue)
                {
                    var fallback = await CalculateFoodAsync(recipe.FoodId.Value);
                    fallback.RecipeId = recipeId;
                    return fallback;
                }
                throw new InvalidOperationException("Công thức chưa có định lượng nguyên liệu.");
            }

            var duplicate = portions?
                .GroupBy(x => x.IngredientId)
                .FirstOrDefault(x => x.Count() > 1);
            if (duplicate != null)
                throw new InvalidOperationException("Mỗi nguyên liệu chỉ được gửi một lần.");

            var requested = portions?.ToDictionary(x => x.IngredientId);
            if (requested != null)
            {
                var allowed = rows.Select(x => x.IngredientId).ToHashSet();
                if (requested.Keys.Any(id => !allowed.Contains(id)))
                    throw new InvalidOperationException("Có nguyên liệu không thuộc công thức đã chọn.");
            }

            var servings = Math.Max(1, recipe.Servings ?? 1);
            var result = new PortionNutritionResponse { RecipeId = recipeId };
            decimal measurableWeight = 0;

            foreach (var row in rows)
            {
                var ingredient = row.Ingredient;
                if (ingredient == null) continue;

                var baseQuantity = (row.Quantity ?? 0m) / servings;
                var unit = row.Unit ?? ingredient.UnitDefault ?? "g";
                var quantity = baseQuantity;
                if (requested != null && requested.TryGetValue(row.IngredientId, out var input))
                {
                    if (!SameUnit(unit, input.Unit))
                        throw new InvalidOperationException($"Đơn vị của {ingredient.NameVi} phải là {unit}.");
                    quantity = input.Quantity;
                }

                if (quantity <= 0)
                    throw new InvalidOperationException($"Định lượng {ingredient.NameVi} phải lớn hơn 0.");

                var ratio = NutritionMath.IngredientNutritionRatio(quantity, unit);
                var line = new PortionIngredientResponse
                {
                    IngredientId = row.IngredientId,
                    Name = ingredient.NameVi,
                    BaseQuantity = Round(baseQuantity),
                    Quantity = Round(quantity),
                    Unit = unit,
                    CaloriesKcal = Round((ingredient.CaloriesKcal ?? 0m) * ratio),
                    ProteinG = Round((ingredient.ProteinG ?? 0m) * ratio),
                    CarbsG = Round((ingredient.CarbsG ?? 0m) * ratio),
                    FatG = Round((ingredient.FatG ?? 0m) * ratio)
                };
                result.Ingredients.Add(line);
                result.CaloriesKcal += line.CaloriesKcal;
                result.ProteinG += line.ProteinG;
                result.CarbsG += line.CarbsG;
                result.FatG += line.FatG;
                if (IsMassOrVolume(unit)) measurableWeight += quantity;
            }

            if (measurableWeight <= 0 && recipe.FoodId.HasValue)
            {
                var food = await _db.Foods.AsNoTracking().FirstOrDefaultAsync(x => x.Id == recipe.FoodId.Value);
                measurableWeight = food?.DefaultServingG ?? 0;
            }

            result.QuantityG = Round(measurableWeight > 0 ? measurableWeight : 100m);
            RoundTotals(result);
            return result;
        }

        public async Task<PortionNutritionResponse> CalculateFoodAsync(Guid foodId, decimal? quantityG = null)
        {
            var food = await _db.Foods.AsNoTracking().FirstOrDefaultAsync(x => x.Id == foodId)
                ?? throw new InvalidOperationException("Không tìm thấy món ăn.");
            var quantity = quantityG is > 0 ? quantityG.Value : food.DefaultServingG ?? 100m;
            var ratio = NutritionMath.ServingNutritionRatio(quantity, food.DefaultServingG);
            return new PortionNutritionResponse
            {
                FoodId = foodId,
                QuantityG = Round(quantity),
                CaloriesKcal = Round((food.CaloriesKcal ?? 0m) * ratio),
                ProteinG = Round((food.ProteinG ?? 0m) * ratio),
                CarbsG = Round((food.CarbsG ?? 0m) * ratio),
                FatG = Round((food.FatG ?? 0m) * ratio)
            };
        }

        public PortionNutritionResponse Scale(PortionNutritionResponse source, decimal ratio)
        {
            if (ratio <= 0) throw new ArgumentOutOfRangeException(nameof(ratio));
            var scaled = new PortionNutritionResponse
            {
                Version = source.Version,
                RecipeId = source.RecipeId,
                FoodId = source.FoodId,
                QuantityG = Round(source.QuantityG * ratio),
                CaloriesKcal = Round(source.CaloriesKcal * ratio),
                ProteinG = Round(source.ProteinG * ratio),
                CarbsG = Round(source.CarbsG * ratio),
                FatG = Round(source.FatG * ratio),
                Ingredients = source.Ingredients.Select(x => new PortionIngredientResponse
                {
                    IngredientId = x.IngredientId,
                    Name = x.Name,
                    BaseQuantity = x.BaseQuantity,
                    Quantity = Round(x.Quantity * ratio),
                    Unit = x.Unit,
                    CaloriesKcal = Round(x.CaloriesKcal * ratio),
                    ProteinG = Round(x.ProteinG * ratio),
                    CarbsG = Round(x.CarbsG * ratio),
                    FatG = Round(x.FatG * ratio)
                }).ToList()
            };
            return scaled;
        }

        public PortionNutritionResponse? Deserialize(string? json)
        {
            if (string.IsNullOrWhiteSpace(json)) return null;
            try { return JsonSerializer.Deserialize<PortionNutritionResponse>(json, JsonOptions); }
            catch (JsonException) { return null; }
        }

        public string Serialize(PortionNutritionResponse value) =>
            JsonSerializer.Serialize(value, JsonOptions);

        private static bool SameUnit(string left, string right) =>
            string.Equals(NormalizeUnit(left), NormalizeUnit(right), StringComparison.Ordinal);

        private static bool IsMassOrVolume(string unit) =>
            NormalizeUnit(unit) is "g" or "ml";

        private static string NormalizeUnit(string unit) => unit.Trim().ToLowerInvariant() switch
        {
            "gram" or "grams" => "g",
            "milliliter" or "milliliters" => "ml",
            _ => unit.Trim().ToLowerInvariant()
        };

        private static decimal Round(decimal value) => Math.Round(value, 2, MidpointRounding.AwayFromZero);

        private static void RoundTotals(PortionNutritionResponse result)
        {
            result.CaloriesKcal = Round(result.CaloriesKcal);
            result.ProteinG = Round(result.ProteinG);
            result.CarbsG = Round(result.CarbsG);
            result.FatG = Round(result.FatG);
        }
    }
}
