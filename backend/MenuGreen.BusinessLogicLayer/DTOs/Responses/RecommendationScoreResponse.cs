namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecommendationScoreResponse
    {
        public double CaloriesScore { get; set; }
        public double MacroScore { get; set; }
        public double AllergyScore { get; set; }
        public double BudgetScore { get; set; }
        public double OverallScore { get; set; }
    }
}
