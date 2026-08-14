using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Helpers;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;

namespace MenuGreen.BusinessLogicLayer.Services
{
    /// <inheritdoc />
    public class GroceryListBuilderService : IGroceryListBuilderService
    {
        private readonly IPortionNutritionCalculator _portionCalculator;

        public GroceryListBuilderService(IPortionNutritionCalculator portionCalculator)
        {
            _portionCalculator = portionCalculator;
        }

        /// <inheritdoc />
        public Task<List<GroceryListDayResponse>> BuildDaysAsync(
            Guid mealPlanId,
            IList<MealPlanItem> planItems,
            IList<RecipeIngredient> recipeIngredients,
            IDictionary<Guid, Recipe> recipesById,
            IDictionary<Guid, Ingredient> ingredientCatalogById)
        {
            // Index recipe ingredients by recipeId so each day can look up its own ingredients
            // without re-querying the database.
            var ingredientsByRecipe = recipeIngredients
                .GroupBy(x => x.RecipeId)
                .ToDictionary(g => g.Key, g => g.ToList());

            // Group plan items by planned date. Nullable dates (unscheduled items)
            // get bucketed under a single null key that will sort to the end.
            var days = planItems
                .GroupBy(item => item.PlannedDate)
                .OrderBy(group => group.Key.HasValue ? 0 : 1)
                .ThenBy(group => group.Key)
                .Select(group => BuildDay(
                    mealPlanId,
                    group.Key,
                    group.ToList(),
                    ingredientsByRecipe,
                    recipesById,
                    ingredientCatalogById))
                .ToList();

            return Task.FromResult(days);
        }

        private GroceryListDayResponse BuildDay(
            Guid mealPlanId,
            DateOnly? plannedDate,
            IList<MealPlanItem> items,
            IDictionary<Guid, List<RecipeIngredient>> ingredientsByRecipe,
            IDictionary<Guid, Recipe> recipesById,
            IDictionary<Guid, Ingredient> ingredientCatalogById)
        {
            // The snapshot belongs to the exact meal-plan item and is therefore
            // authoritative after a portion or AI meal was changed. Legacy
            // budget plans do not have snapshots, so fall back to the effective
            // recipe resolved by MealPlanService (including FoodId-linked recipes).
            var lines = new List<GroceryIngredientLine>();
            foreach (var item in items)
            {
                var snapshot = _portionCalculator.Deserialize(item.IngredientSnapshotJson);
                if (snapshot?.Ingredients.Count > 0)
                {
                    lines.AddRange(snapshot.Ingredients.Select(ingredient =>
                        new GroceryIngredientLine(
                            ingredient.IngredientId,
                            ingredient.Name,
                            ingredient.Unit,
                            ingredient.Quantity)));
                    continue;
                }

                if (item.RecipeId.HasValue &&
                    ingredientsByRecipe.TryGetValue(item.RecipeId.Value, out var recipeRows))
                {
                    var servings = ServingsFor(item.RecipeId.Value, recipesById);
                    lines.AddRange(recipeRows.Select(row =>
                        new GroceryIngredientLine(
                            row.IngredientId,
                            string.Empty,
                            row.Unit ?? "unit",
                            (row.Quantity ?? 0m) / servings)));
                }
            }

            var aggregated = lines
                .GroupBy(line => new
                {
                    line.IngredientId,
                    Unit = line.Unit,
                })
                .Select(group => BuildItem(
                    group.Key.IngredientId,
                    group.Key.Unit,
                    group.Sum(line => line.Quantity),
                    group.Select(line => line.Name)
                        .FirstOrDefault(name => !string.IsNullOrWhiteSpace(name)),
                    ingredientCatalogById))
                .OrderBy(item => item.Name)
                .ToList();

            return new GroceryListDayResponse
            {
                PlannedDate = plannedDate ?? default,
                EstimatedTotalVnd = aggregated.Sum(item => item.EstimatedPriceVnd),
                Items = aggregated,
            };
        }

        private static int ServingsFor(Guid recipeId, IDictionary<Guid, Recipe> recipesById)
        {
            if (!recipesById.TryGetValue(recipeId, out var recipe) || recipe == null)
            {
                return 1;
            }
            return Math.Max(1, recipe.Servings ?? 1);
        }

        private static GroceryListItemResponse BuildItem(
            Guid ingredientId,
            string unit,
            decimal quantity,
            string? snapshotName,
            IDictionary<Guid, Ingredient> ingredientCatalogById)
        {
            ingredientCatalogById.TryGetValue(ingredientId, out var ingredient);
            return new GroceryListItemResponse
            {
                IngredientId = ingredientId,
                Name = ingredient?.NameVi ?? snapshotName ?? "Nguyên liệu",
                Quantity = quantity,
                Unit = unit,
                // EstimatedPriceVnd is stored per kg/litre for mass and volume
                // units, and per item for units such as "quả" or "ổ".
                EstimatedPriceVnd = NutritionMath.EstimateIngredientCost(
                    ingredient?.EstimatedPriceVnd ?? 0,
                    quantity,
                    unit),
            };
        }

        private sealed record GroceryIngredientLine(
            Guid IngredientId,
            string Name,
            string Unit,
            decimal Quantity);
    }
}
