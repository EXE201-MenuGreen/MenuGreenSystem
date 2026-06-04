using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class FoodResponse
    {
        public Guid Id { get; set; }
        public string NameVi { get; set; } = string.Empty;
        public string? NameEn { get; set; }
        public string? Category { get; set; }
        public string? Description { get; set; }
        public decimal? CaloriesKcal { get; set; }
        public decimal? ProteinG { get; set; }
        public decimal? CarbsG { get; set; }
        public decimal? FatG { get; set; }
        public decimal? FiberG { get; set; }
        public int? EstimatedPriceVnd { get; set; }
        public int? DefaultServingG { get; set; }
        public string? ImageUrl { get; set; }
        public bool? IsActive { get; set; }

        /// <summary>Mã chuẩn (peanut, dairy, …).</summary>
        public List<string> AllergenKeys { get; set; } = new();

        /// <summary>Nhãn tiếng Việt trên món.</summary>
        public List<string> AllergenLabelsVi { get; set; } = new();

        /// <summary>Dị ứng user trùng với món (nhãn VI).</summary>
        public List<string> MatchedAllergens { get; set; } = new();

        /// <summary>none | caution | high</summary>
        public string AllergyRiskLevel { get; set; } = "none";

        public bool IsSafeForUser { get; set; } = true;
    }
}
