namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AnalyticsTopFoodsResponse
    {
        public List<TopFoodItem> TopFoods { get; set; } = new();
        public List<TopFoodItem> TopFoodsByCalories { get; set; } = new();
        public List<TopFoodItem> TopFoodsByProtein { get; set; } = new();
        public int TotalUniqueFoodsLogged { get; set; }
    }

    public class TopFoodItem
    {
        public int Rank { get; set; }
        public string FoodId { get; set; } = string.Empty;
        public string FoodName { get; set; } = string.Empty;
        public string FoodNameEn { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public int LogCount { get; set; }
        public decimal TotalServings { get; set; }
        public decimal AvgServingSizeG { get; set; }
        public decimal AvgCaloriesPerServing { get; set; }
        public decimal AvgProteinPerServing { get; set; }
        public decimal PercentOfTotalLogs { get; set; }
    }
}
