using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class RecipeUpsertRequest
    {
        public Guid? FoodId { get; set; }

        [Required]
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

        public List<RecipeIngredientUpsertRequest> Ingredients { get; set; } = new();
    }
}
