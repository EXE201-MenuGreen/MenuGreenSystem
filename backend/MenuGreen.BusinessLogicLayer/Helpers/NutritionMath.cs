using System;

namespace MenuGreen.BusinessLogicLayer.Helpers
{
    public static class NutritionMath
    {
        public static decimal IngredientNutritionRatio(decimal quantity, string? unit)
        {
            var normalized = (unit ?? string.Empty).Trim().ToLowerInvariant();
            return normalized is "g" or "gram" or "grams" or "ml" or "milliliter" or "milliliters"
                ? quantity / 100m
                : quantity;
        }

        public static int EstimateIngredientCost(int unitPriceVnd, decimal quantity, string? unit)
        {
            if (unitPriceVnd <= 0 || quantity <= 0) return 0;

            var normalized = (unit ?? string.Empty).Trim().ToLowerInvariant();
            var cost = normalized is "g" or "gram" or "grams" or "ml" or "milliliter" or "milliliters"
                ? unitPriceVnd * quantity / 1000m
                : unitPriceVnd * quantity;

            return (int)Math.Round(cost, MidpointRounding.AwayFromZero);
        }
    }
}
