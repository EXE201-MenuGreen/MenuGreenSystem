using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class UpdateMealPlanProposalRequest
    {
        [Required]
        public List<MealPlanProposalItemRequest> Items { get; set; } = new();
    }

    public class MealPlanProposalItemRequest
    {
        [Required]
        public string Action { get; set; } = "Add";

        [Required]
        public DateOnly PlannedDate { get; set; }

        [Required]
        public string MealType { get; set; } = "snack";

        public Guid? ExistingMealPlanItemId { get; set; }
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }

        [Range(typeof(decimal), "0.01", "10000")]
        public decimal? QuantityG { get; set; }

        [Range(1, 10000)]
        public int? TargetCalories { get; set; }

        public List<MealPlanIngredientPortionRequest>? Ingredients { get; set; }

        public int SortOrder { get; set; }
    }
}
