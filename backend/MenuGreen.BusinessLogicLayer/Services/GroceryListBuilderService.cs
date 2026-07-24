using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;

namespace MenuGreen.BusinessLogicLayer.Services
{
    /// <inheritdoc />
    public class GroceryListBuilderService : IGroceryListBuilderService
    {
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
                .Where(item => item.RecipeId.HasValue)
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

        private static GroceryListDayResponse BuildDay(
            Guid mealPlanId,
            DateOnly? plannedDate,
            IList<MealPlanItem> items,
            IDictionary<Guid, List<RecipeIngredient>> ingredientsByRecipe,
            IDictionary<Guid, Recipe> recipesById,
            IDictionary<Guid, Ingredient> ingredientCatalogById)
        {
            // Aggregate ingredient quantity across all items in this day.
            // Phase 1 keeps the same pricing formula as the legacy Items[]
            // view (no servings multiplier) so the per-day total stays
            // consistent with the weekly total the budget check relies on.
            var aggregated = items
                .Where(item => item.RecipeId.HasValue
                    && ingredientsByRecipe.TryGetValue(item.RecipeId.Value, out var _))
                .SelectMany(item => ingredientsByRecipe[item.RecipeId!.Value])
                .GroupBy(ri => new
                {
                    ri.IngredientId,
                    Unit = ri.Unit ?? "unit",
                })
                .Select(group => BuildItem(
                    group.Key.IngredientId,
                    group.Key.Unit,
                    group.Sum(ri => ri.Quantity ?? 0m),
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
            IDictionary<Guid, Ingredient> ingredientCatalogById)
        {
            ingredientCatalogById.TryGetValue(ingredientId, out var ingredient);
            return new GroceryListItemResponse
            {
                IngredientId = ingredientId,
                Name = ingredient?.NameVi ?? "Nguyên liệu",
                Quantity = quantity,
                Unit = unit,
                EstimatedPriceVnd = ingredient?.EstimatedPriceVnd ?? 0,
            };
        }
    }
}
