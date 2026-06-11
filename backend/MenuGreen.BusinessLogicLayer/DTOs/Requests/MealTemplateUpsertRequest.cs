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

        [Range(0.01, double.MaxValue)]
        public decimal QuantityG { get; set; }

        public string? Notes { get; set; }
        public int SortOrder { get; set; }
    }

    public class MealTemplateLogRequest
    {
        public DateTime? LoggedAt { get; set; }
        public string? MealType { get; set; }
    }
}
