using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class DailyStarterMealItem
    {
        [Required]
        public Guid FoodId { get; set; }

        [Required]
        [RegularExpression("^(Breakfast|Lunch|Dinner|Snack)$", ErrorMessage = "MealType must be Breakfast, Lunch, Dinner, or Snack.")]
        public string MealType { get; set; } = "Breakfast"; // Breakfast, Lunch, Dinner, Snack
    }

    public class DailyStarterSelectMealRequest
    {
        [Required]
        [MinLength(1)]
        [MaxLength(4)]
        public List<DailyStarterMealItem> Meals { get; set; } = new();
    }
}
