using System;

namespace MenuGreen.BusinessLogicLayer.Helpers
{
    public static class NutritionMath
    {
        /// <summary>
        /// Returns the multiplier for nutrition values stored for one default
        /// food serving. Legacy rows without a serving weight are treated as
        /// a 100g basis, matching the historical behavior.
        /// </summary>
        public static decimal ServingNutritionRatio(
            decimal quantityG,
            int? defaultServingG)
        {
            var basisG = defaultServingG is > 0 ? defaultServingG.Value : 100;
            return quantityG / basisG;
        }

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
