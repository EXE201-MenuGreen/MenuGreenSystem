using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MealPlanResponse
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? PlanType { get; set; }
        public DateOnly? StartDate { get; set; }
        public DateOnly? EndDate { get; set; }
        public int? TargetCalories { get; set; }
        public int? MinCalories { get; set; }
        public int? MaxCalories { get; set; }
        public string? CoachNotes { get; set; }
        public string? GeneratedBy { get; set; }
        public string Status { get; set; } = "Active";
        public DateTime? ApprovedAt { get; set; }
        public bool IsActive { get; set; }
        public int TotalCalories { get; set; }
        public int TotalProteinG { get; set; }
        public int TotalCarbsG { get; set; }
        public int TotalFatG { get; set; }
        public int? TargetProteinG { get; set; }
        public int? TargetCarbsG { get; set; }
        public int? TargetFatG { get; set; }
        public List<MealPlanItemResponse> Items { get; set; } = new();
    }
}
