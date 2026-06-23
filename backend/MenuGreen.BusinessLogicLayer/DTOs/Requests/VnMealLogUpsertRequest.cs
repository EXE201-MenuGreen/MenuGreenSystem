using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class VnMealLogUpsertRequest
    {
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }

        [Required(ErrorMessage = "Meal type is required.")]
        public string MealType { get; set; } = string.Empty;

        [Range(0.01, double.MaxValue, ErrorMessage = "Quantity must be greater than 0.")]
        public decimal Quantity { get; set; }

        [Required(ErrorMessage = "Unit is required.")]
        public string Unit { get; set; } = "gram";

        public string? Notes { get; set; }
        public DateTime? LoggedAt { get; set; }
        public Guid? MealPlanItemId { get; set; }
    }
}
