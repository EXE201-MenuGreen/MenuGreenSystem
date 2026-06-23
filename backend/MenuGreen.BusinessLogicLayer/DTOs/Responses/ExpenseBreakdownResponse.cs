using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class ExpenseBreakdownResponse
    {
        public List<ExpenseCategoryBreakdownDto> Categories { get; set; } = new();
        public List<string> SavingTips { get; set; } = new();
    }

    public class ExpenseCategoryBreakdownDto
    {
        public string Category { get; set; } = string.Empty;
        public int Amount { get; set; }
        public double Percentage { get; set; }
    }
}
