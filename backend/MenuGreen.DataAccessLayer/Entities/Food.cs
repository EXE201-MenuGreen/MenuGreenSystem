using System;
using System.Collections.Generic;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class Food
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
        public DateTime? CreatedAt { get; set; }

        public virtual ICollection<Recipe> Recipes { get; set; } = new List<Recipe>();
    }
}
