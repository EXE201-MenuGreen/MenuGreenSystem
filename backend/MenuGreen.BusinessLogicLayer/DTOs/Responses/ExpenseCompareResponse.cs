using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class ExpenseCompareResponse
    {
        public DateOnly From { get; set; }
        public DateOnly To { get; set; }
        public int BudgetLimit { get; set; }
        public int PlannedCost { get; set; }
        public int ActualExpense { get; set; }
    }
}
