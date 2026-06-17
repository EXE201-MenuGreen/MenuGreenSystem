using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecipeIngredientSubstituteResponse
    {
        public Guid RecipeId { get; set; }
        public Guid OriginalIngredientId { get; set; }
        public string OriginalIngredientName { get; set; } = string.Empty;
        public double OriginalQuantity { get; set; }
        public string OriginalUnit { get; set; } = string.Empty;

        public List<RecipeSubstituteOptionDto> Options { get; set; } = new();
    }

    public class RecipeSubstituteOptionDto
    {
        public Guid IngredientId { get; set; }
        public string IngredientName { get; set; } = string.Empty;
        public double SuggestedQuantity { get; set; }
        public string Unit { get; set; } = string.Empty;
        public int PriceDifferenceVnd { get; set; }
    }
}
