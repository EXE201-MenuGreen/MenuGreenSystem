using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class IngredientRecipeResponse
    {
        public Guid RecipeId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? PrepTimeMin { get; set; }
        public int? CookTimeMin { get; set; }
        public int? TotalTimeMin { get; set; }
        public int? Servings { get; set; }
        public string? Difficulty { get; set; }
        public string? MealType { get; set; }
        public int? EstimatedPriceVnd { get; set; }
        public string? ImageUrl { get; set; }
        public bool? IsActive { get; set; }
    }
}
