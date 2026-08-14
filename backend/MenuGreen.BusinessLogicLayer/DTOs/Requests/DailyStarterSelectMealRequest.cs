using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class DailyStarterMealItem : IValidatableObject
    {
        public Guid? FoodId { get; set; }

        [StringLength(200)]
        public string? CustomName { get; set; }

        [Range(typeof(decimal), "0", "10000")]
        public decimal? CaloriesKcal { get; set; }

        [Range(typeof(decimal), "0", "1000")]
        public decimal? ProteinG { get; set; }

        [Range(typeof(decimal), "0", "1000")]
        public decimal? CarbsG { get; set; }

        [Range(typeof(decimal), "0", "1000")]
        public decimal? FatG { get; set; }

        [Range(typeof(decimal), "0.01", "10000")]
        public decimal? QuantityG { get; set; }

        [Required]
        [RegularExpression("^(Breakfast|Lunch|Dinner|Snack)$", ErrorMessage = "MealType must be Breakfast, Lunch, Dinner, or Snack.")]
        public string MealType { get; set; } = "Breakfast"; // Breakfast, Lunch, Dinner, Snack

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (!FoodId.HasValue && string.IsNullOrWhiteSpace(CustomName))
            {
                yield return new ValidationResult(
                    "FoodId or CustomName is required.",
                    new[] { nameof(FoodId), nameof(CustomName) });
            }

            if (!FoodId.HasValue && !CaloriesKcal.HasValue)
            {
                yield return new ValidationResult(
                    "CaloriesKcal is required for a custom meal.",
                    new[] { nameof(CaloriesKcal) });
            }
        }
    }

    public class DailyStarterSelectMealRequest
    {
        [Required]
        [MinLength(1)]
        [MaxLength(4)]
        public List<DailyStarterMealItem> Meals { get; set; } = new();
    }
}
