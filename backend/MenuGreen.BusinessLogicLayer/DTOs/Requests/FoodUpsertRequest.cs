using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class FoodUpsertRequest
    {
        [Required]
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
        [Required(ErrorMessage = "Default serving weight is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "Default serving weight must be greater than 0 grams.")]
        public int? DefaultServingG { get; set; }
        public string? ImageUrl { get; set; }
        public bool? IsActive { get; set; }
        public string? Region { get; set; }
    }
}
