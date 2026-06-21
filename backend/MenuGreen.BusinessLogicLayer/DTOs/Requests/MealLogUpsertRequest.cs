using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MealLogUpsertRequest : IValidatableObject
    {
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }

        [Required]
        public string MealType { get; set; } = string.Empty;

        [Range(0.01, double.MaxValue)]
        public decimal? QuantityG { get; set; }

        [Range(0.01, double.MaxValue)]
        public decimal? Quantity { get; set; }

        public string? Unit { get; set; }

        public string? Notes { get; set; }
        public DateTime? LoggedAt { get; set; }
        public Guid? MealPlanItemId { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (!QuantityG.HasValue && !Quantity.HasValue)
            {
                yield return new ValidationResult(
                    "Either QuantityG or Quantity is required.",
                    new[] { nameof(QuantityG), nameof(Quantity) });
            }

            if (Quantity.HasValue && string.IsNullOrWhiteSpace(Unit))
            {
                yield return new ValidationResult(
                    "Unit is required when Quantity is provided.",
                    new[] { nameof(Unit) });
            }
        }
    }
}
