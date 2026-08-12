using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MealPlanIngredientPortionRequest
    {
        [Required]
        public Guid IngredientId { get; set; }

        [Range(typeof(decimal), "0.01", "10000")]
        public decimal Quantity { get; set; }

        [Required]
        [StringLength(30)]
        public string Unit { get; set; } = string.Empty;
    }

    public class UpdateMealPlanProposalItemPortionRequest
    {
        [Required]
        [MinLength(1)]
        public System.Collections.Generic.List<MealPlanIngredientPortionRequest> Ingredients { get; set; } = new();
    }
}
