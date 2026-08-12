using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecipeResponse
    {
        public Guid Id { get; set; }
        public Guid? FoodId { get; set; }
        public int? DefaultServingG { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? PrepTimeMin { get; set; }
        public int? CookTimeMin { get; set; }
        public int? TotalTimeMin { get; set; }
        public int? Servings { get; set; }
        public string? Difficulty { get; set; }
        public string? MealType { get; set; }
        public int? EstimatedPriceVnd { get; set; }
        public string? Instructions { get; set; }
        public string? ImageUrl { get; set; }
        public string? VideoUrl { get; set; }
        public bool? IsActive { get; set; }
        public List<RecipeIngredientResponse> Ingredients { get; set; } = new();
        public List<string> MatchedAllergens { get; set; } = new();
        public string AllergyRiskLevel { get; set; } = "none";
        public bool IsSafeForUser { get; set; } = true;
    }
}
