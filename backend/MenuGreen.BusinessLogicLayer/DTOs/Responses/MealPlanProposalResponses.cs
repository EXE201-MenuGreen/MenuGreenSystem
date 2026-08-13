using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MealPlanProposalResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid CoachId { get; set; }
        public Guid ReviewRequestId { get; set; }
        public string ProposalType { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateOnly PeriodStart { get; set; }
        public DateOnly PeriodEnd { get; set; }
        public DateTime? ExpiresAt { get; set; }
        public DateTime? ReminderSentAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? SubmittedAt { get; set; }
        public DateTime? ActionedAt { get; set; }
        public List<MealPlanProposalItemResponse> Items { get; set; } = new();
        public List<ProposalSourceMealResponse> SourceMeals { get; set; } = new();
    }

    public class MealPlanProposalItemResponse
    {
        public Guid Id { get; set; }
        public string Action { get; set; } = string.Empty;
        public DateOnly PlannedDate { get; set; }
        public string MealType { get; set; } = string.Empty;
        public Guid? ExistingMealPlanItemId { get; set; }
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }
        public string DisplayName { get; set; } = string.Empty;
        public decimal? QuantityG { get; set; }
        public int? TargetCalories { get; set; }
        public decimal? ProteinG { get; set; }
        public decimal? CarbsG { get; set; }
        public decimal? FatG { get; set; }
        public List<PortionIngredientResponse> Ingredients { get; set; } = new();
        public int SortOrder { get; set; }
    }

    public class ProposalSourceMealResponse
    {
        public Guid MealPlanItemId { get; set; }
        public DateOnly PlannedDate { get; set; }
        public string MealType { get; set; } = string.Empty;
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }
        public string DisplayName { get; set; } = string.Empty;
        public decimal? QuantityG { get; set; }
        public int? TargetCalories { get; set; }
        public decimal? ProteinG { get; set; }
        public decimal? CarbsG { get; set; }
        public decimal? FatG { get; set; }
        public List<PortionIngredientResponse> Ingredients { get; set; } = new();
    }
}
