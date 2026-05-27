using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class IngredientUpsertRequest
    {
        [Required]
        public string NameVi { get; set; } = string.Empty;

        public string? NameEn { get; set; }
        public string? Category { get; set; }
        public decimal? CaloriesKcal { get; set; }
        public decimal? ProteinG { get; set; }
        public decimal? CarbsG { get; set; }
        public decimal? FatG { get; set; }
        public int? EstimatedPriceVnd { get; set; }
        public string? UnitDefault { get; set; }
        public string? ImageUrl { get; set; }
        public bool? IsActive { get; set; }
    }
}
