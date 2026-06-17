namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class BudgetAdherenceResponse
    {
        public int AdherenceScore { get; set; } // 0 - 100
        public int WithinBudgetDays { get; set; }
        public int TotalEvaluatedDays { get; set; }
        public string FeedbackMessage { get; set; } = string.Empty;
    }
}
