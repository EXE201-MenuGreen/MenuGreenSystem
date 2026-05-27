using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class RecipeIngredientUpsertRequest
    {
        [Required]
        public Guid IngredientId { get; set; }

        [Required]
        public decimal Quantity { get; set; }

        [Required]
        public string Unit { get; set; } = string.Empty;

        public string? Notes { get; set; }
    }
}
