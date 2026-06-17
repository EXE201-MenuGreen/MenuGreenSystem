using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class BudgetStatusResponse
    {
        public Guid MealPlanId { get; set; }
        public int BudgetLimit { get; set; }
        public int PlannedCost { get; set; }
        public string Status { get; set; } = string.Empty; // WithinBudget, ExceededBudget
        public int ExceededAmount { get; set; }
    }
}
