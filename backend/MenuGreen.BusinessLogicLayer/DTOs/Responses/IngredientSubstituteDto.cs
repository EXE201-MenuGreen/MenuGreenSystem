using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class IngredientSubstituteDto
    {
        public Guid OriginalIngredientId { get; set; }
        public string OriginalIngredientName { get; set; } = string.Empty;
        public List<SubstituteOptionDto> Substitutes { get; set; } = new();
    }

    public class SubstituteOptionDto
    {
        public Guid Id { get; set; }
        public string NameVi { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public double ConversionRatio { get; set; }
        public int? EstimatedPriceVnd { get; set; }
        public double CaloriesKcal { get; set; }
    }
}
