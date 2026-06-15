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
        public string MealType { get; set; } = "Breakfast"; // Breakfast, Lunch, Dinner, Snack
    }

    public class DailyStarterSelectMealRequest
    {
        [Required]
        public List<DailyStarterMealItem> Meals { get; set; } = new();
    }
}
