using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class BudgetAwareGenerateRequest
    {
        public string? MealType { get; set; }
        public int MaxBudgetPerMeal { get; set; }
        public bool ExcludeUserAllergies { get; set; } = true;
    }
}
