using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MealTemplateUpsertRequest
    {
        [Required]
        public string Title { get; set; } = string.Empty;

        public string? Description { get; set; }
        public string? MealType { get; set; }
        public bool? IsActive { get; set; }
        public List<MealTemplateItemUpsertRequest> Items { get; set; } = new();
    }

    public class MealTemplateItemUpsertRequest
    {
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }
        [MaxLength(200)]
        public string? CustomName { get; set; }
        [MaxLength(50)]
        public string? SourceType { get; set; }
        public string? MealType { get; set; }

        [Range(0.01, double.MaxValue)]
        public decimal QuantityG { get; set; }

        [Range(0, double.MaxValue)]
        public decimal? CaloriesKcal { get; set; }
        [Range(0, double.MaxValue)]
        public decimal? ProteinG { get; set; }
        [Range(0, double.MaxValue)]
        public decimal? CarbsG { get; set; }
        [Range(0, double.MaxValue)]
        public decimal? FatG { get; set; }

        public List<OfficeScanIngredientRequest> Ingredients { get; set; } = new();

        public string? Notes { get; set; }
        public int SortOrder { get; set; }
    }

    public class MealTemplateLogRequest
    {
        public DateTime? LoggedAt { get; set; }
        public string? MealType { get; set; }
        public List<MealTemplateLogItemQuantityRequest> ItemQuantities { get; set; } = new();
    }

    public class MealTemplateLogItemQuantityRequest
    {
        [Required]
        public Guid MealTemplateItemId { get; set; }

        [Range(0.01, double.MaxValue)]
        public decimal QuantityG { get; set; }
    }
}
