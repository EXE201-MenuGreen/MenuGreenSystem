using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class IngredientSearchResponse
    {
        public List<IngredientResponse> Items { get; set; } = new();
        public int TotalCount { get; set; }
    }
}
