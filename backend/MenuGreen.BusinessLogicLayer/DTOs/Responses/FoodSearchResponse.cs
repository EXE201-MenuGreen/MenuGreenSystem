using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class FoodSearchResponse
    {
        public List<FoodResponse> Items { get; set; } = new();
        public int TotalCount { get; set; }
    }
}
