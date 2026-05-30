using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecipeSearchResponse
    {
        public List<RecipeResponse> Items { get; set; } = new();
        public int TotalCount { get; set; }
    }
}
