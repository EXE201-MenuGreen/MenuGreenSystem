using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.DataAccessLayer.Context;
using Microsoft.EntityFrameworkCore;

namespace MenuGreen.BusinessLogicLayer.Helpers
{
    public static class RecipeIngredientLoader
    {
        public static async Task<List<RecipeIngredientResponse>> LoadAsync(ApplicationDbContext db, Guid recipeId)
        {
            var items = await db.RecipeIngredients
                .AsNoTracking()
                .Include(x => x.Ingredient)
                .Where(x => x.RecipeId == recipeId)
                .ToListAsync();

            return items.Select(x => new RecipeIngredientResponse
            {
                IngredientId = x.IngredientId,
                IngredientName = x.Ingredient?.NameVi ?? string.Empty,
                Quantity = x.Quantity ?? 0,
                Unit = x.Unit ?? string.Empty,
                NutritionBasisQuantity = IsMassOrVolume(x.Unit ?? x.Ingredient?.UnitDefault) ? 100m : 1m,
                CaloriesKcal = x.Ingredient?.CaloriesKcal ?? 0,
                ProteinG = x.Ingredient?.ProteinG ?? 0,
                CarbsG = x.Ingredient?.CarbsG ?? 0,
                FatG = x.Ingredient?.FatG ?? 0,
                Notes = x.Notes
            }).ToList();
        }

        private static bool IsMassOrVolume(string? unit) =>
            (unit ?? string.Empty).Trim().ToLowerInvariant() is
                "g" or "gram" or "grams" or "ml" or "milliliter" or "milliliters";
    }
}
