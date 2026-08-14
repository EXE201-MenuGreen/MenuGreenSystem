using System;
using System.Collections.Generic;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.DataAccessLayer.Entities;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    /// <summary>
    /// Builds derived views (Days[], ShoppingTrips[]) for the grocery list response.
    /// Kept separate from <see cref="IMealPlanService"/> so the logic can grow
    /// (Phase 2: shopping trip heuristics) without bloating MealPlanService.
    /// </summary>
    public interface IGroceryListBuilderService
    {
        /// <summary>
        /// Group the effective ingredients of each meal-plan item by planned date.
        /// Item snapshots take priority; legacy FoodId items can be supplied with
        /// a linked RecipeId by the caller.
        /// Items with no <c>PlannedDate</c> are merged into a single entry whose
        /// <c>PlannedDate</c> is <c>null</c> and sorted to the end of the result.
        /// </summary>
        Task<List<GroceryListDayResponse>> BuildDaysAsync(
            Guid mealPlanId,
            IList<MealPlanItem> planItems,
            IList<RecipeIngredient> recipeIngredients,
            IDictionary<Guid, Recipe> recipesById,
            IDictionary<Guid, Ingredient> ingredientCatalogById);
    }
}
