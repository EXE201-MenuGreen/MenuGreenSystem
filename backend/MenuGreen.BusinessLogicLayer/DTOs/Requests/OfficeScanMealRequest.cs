using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class OfficeScanMealRequest
    {
        [Required, MaxLength(200)]
        public string CustomName { get; set; } = string.Empty;

        [Required, RegularExpression("^(breakfast|lunch|dinner|snack)$")]
        public string MealType { get; set; } = "lunch";

        public DateOnly PlannedDate { get; set; }
        public TimeOnly? ScheduledTime { get; set; }

        [Range(0.01, double.MaxValue)]
        public decimal QuantityG { get; set; }

        [Range(0, double.MaxValue)]
        public decimal CaloriesKcal { get; set; }

        [Range(0, double.MaxValue)]
        public decimal ProteinG { get; set; }

        [Range(0, double.MaxValue)]
        public decimal CarbsG { get; set; }

        [Range(0, double.MaxValue)]
        public decimal FatG { get; set; }

        public DateTime? LoggedAt { get; set; }
        public bool ReplaceExisting { get; set; }
        public List<OfficeScanIngredientRequest> Ingredients { get; set; } = new();
    }

    public class OfficeScanIngredientRequest
    {
        [Required, MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        [Range(0, double.MaxValue)]
        public decimal Quantity { get; set; }

        [Required, MaxLength(30)]
        public string Unit { get; set; } = "g";

        public bool IsAvailable { get; set; } = true;
    }
}
