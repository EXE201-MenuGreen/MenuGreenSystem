using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

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
        [MaxLength(200)]
        public string? CustomName { get; set; }
        public DateTime? LoggedAt { get; set; }
        public Guid? MealPlanItemId { get; set; }

        /// <summary>
        /// When recording an actual meal, also add or match it in the daily
        /// meal plan and mark that plan item as completed.
        /// </summary>
        public bool AddToMealPlan { get; set; } = true;

        [Range(0, double.MaxValue, ErrorMessage = "Calories must be positive.")]
        public decimal? CaloriesKcal { get; set; }

        [Range(0, double.MaxValue, ErrorMessage = "Protein must be positive.")]
        public decimal? ProteinG { get; set; }

        [Range(0, double.MaxValue, ErrorMessage = "Carbs must be positive.")]
        public decimal? CarbsG { get; set; }

        [Range(0, double.MaxValue, ErrorMessage = "Fat must be positive.")]
        public decimal? FatG { get; set; }

        // Internal meal-plan completion snapshot. Clients cannot influence
        // catalog data; this value is copied from the approved plan item.
        [JsonIgnore]
        public string? IngredientSnapshotJson { get; set; }
        [JsonIgnore]
        public decimal? ConsumptionRatio { get; set; }

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
