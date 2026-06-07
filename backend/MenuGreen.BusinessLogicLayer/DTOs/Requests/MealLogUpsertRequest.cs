using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MealLogUpsertRequest
    {
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }

        [Required]
        public string MealType { get; set; } = string.Empty;

        [Range(0.01, double.MaxValue)]
        public decimal QuantityG { get; set; }

        public string? Notes { get; set; }
        public DateTime? LoggedAt { get; set; }
        public Guid? MealPlanItemId { get; set; }
    }
}
