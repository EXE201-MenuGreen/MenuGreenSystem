using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class IngredientSubstituteDetailResponse
    {
        public Guid Id { get; set; }
        public string NameVi { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public double SimilarityScore { get; set; }
        public double ConversionRatio { get; set; }
        public int? EstimatedPriceVnd { get; set; }
        public string Explanation { get; set; } = string.Empty;
    }
}
