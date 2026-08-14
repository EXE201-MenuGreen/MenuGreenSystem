using System;
using System.Collections.Generic;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MealTemplateResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? MealType { get; set; }
        public int UsageCount { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public List<MealTemplateItemResponse> Items { get; set; } = new();
    }

    public class MealTemplateItemResponse
    {
        public Guid Id { get; set; }
        public Guid MealTemplateId { get; set; }
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }
        public string? CustomName { get; set; }
        public string? SourceType { get; set; }
        public string? Name { get; set; }
        public string MealType { get; set; } = "Snack";
        public decimal QuantityG { get; set; }
        public List<OfficeScanIngredientRequest> Ingredients { get; set; } = new();
        public string? Notes { get; set; }
        public int SortOrder { get; set; }
        public decimal CaloriesKcal { get; set; }
        public decimal ProteinG { get; set; }
        public decimal CarbsG { get; set; }
        public decimal FatG { get; set; }
    }

    public class MealTemplateLogResponse
    {
        public Guid MealTemplateId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? MealType { get; set; }
        public DateTime LoggedAt { get; set; }
        public int CreatedMealLogsCount { get; set; }
        public decimal TotalCaloriesKcal { get; set; }
        public decimal TotalProteinG { get; set; }
        public decimal TotalCarbsG { get; set; }
        public decimal TotalFatG { get; set; }
        public List<MealLogResponse> MealLogs { get; set; } = new();
    }
}
