using System;
using System.Collections.Generic;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class Recipe
    {
        public Guid Id { get; set; }
        public Guid? FoodId { get; set; }
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
        public string? SourceName { get; set; }
        public string? SourceUrl { get; set; }
        public bool? IsActive { get; set; }
        public DateTime? CreatedAt { get; set; }

        public virtual Food? Food { get; set; }
        public virtual ICollection<RecipeIngredient> RecipeIngredients { get; set; } = new List<RecipeIngredient>();
    }
}
