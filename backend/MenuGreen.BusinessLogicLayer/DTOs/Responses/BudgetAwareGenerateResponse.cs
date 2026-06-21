using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class BudgetAwareGenerateResponse
    {
        public Guid Id { get; set; }
        public List<RecommendationItemResponse> Items { get; set; } = new();
        public int TotalBudget { get; set; }
        public int Remaining { get; set; }
    }
}
