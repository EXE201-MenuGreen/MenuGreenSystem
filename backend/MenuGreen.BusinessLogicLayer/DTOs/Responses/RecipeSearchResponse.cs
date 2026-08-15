using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecipeSearchResponse
    {
        public List<RecipeResponse> Items { get; set; } = new();
        public int TotalCount { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; }
        public int TotalPages => PageSize > 0
            ? (int)System.Math.Ceiling((double)TotalCount / PageSize)
            : 0;
    }
}
