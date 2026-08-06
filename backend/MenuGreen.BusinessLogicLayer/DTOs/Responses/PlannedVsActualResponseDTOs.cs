using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class PlannedVsActualSummaryResponse
    {
        public DateOnly From { get; set; }
        public DateOnly To { get; set; }
        public PlannedNutrition TotalPlanned { get; set; } = new();
        public ActualNutrition TotalActual { get; set; } = new();
        public List<PlannedVsActualDto> Details { get; set; } = new();
    }

    public class PlannedVsActualDto
    {
        public DateOnly Date { get; set; }
        public PlannedNutrition Planned { get; set; } = new();
        public ActualNutrition Actual { get; set; } = new();
    }

    public class PlannedNutrition
    {
        public decimal CaloriesKcal { get; set; }
        public decimal ProteinG { get; set; }
        public decimal CarbsG { get; set; }
        public decimal FatG { get; set; }
        public decimal CostVnd { get; set; }
    }

    public class ActualNutrition
    {
        public decimal CaloriesKcal { get; set; }
        public decimal ProteinG { get; set; }
        public decimal CarbsG { get; set; }
        public decimal FatG { get; set; }
        public decimal CostVnd { get; set; }
    }

    public class AdherenceScoreResponse
    {
        public DateOnly From { get; set; }
        public DateOnly To { get; set; }
        public double OverallScore { get; set; } // Scale 0-100
        public double MealCompletionRate { get; set; } // Scale 0-100
        public double CalorieDeviationScore { get; set; } // Scale 0-100
        public double MacroDeviationScore { get; set; } // Scale 0-100
        public double UnplannedPenaltyScore { get; set; } // Scale 0-100
        public int CompletedMealsCount { get; set; }
        public int PlannedMealsCount { get; set; }
        public int SkippedMealsCount { get; set; }
        public int UnplannedMealsCount { get; set; }
        public string Rating { get; set; } = string.Empty; // EXCELLENT, GOOD, FAIR, POOR
        public string Feedback { get; set; } = string.Empty;
    }

    public class DriftAnalysisResponse
    {
        public DateOnly From { get; set; }
        public DateOnly To { get; set; }
        
        public int SkippedMealsCount { get; set; }
        public List<SkippedMealDetail> SkippedMeals { get; set; } = new();

        public int UnplannedIntakeCount { get; set; }
        public List<UnplannedIntakeDetail> UnplannedIntakes { get; set; } = new();

        public int SubstitutedItemsCount { get; set; }
        public List<SubstitutedItemDetail> SubstitutedItems { get; set; } = new();

        public int PortionMismatchesCount { get; set; }
        public List<PortionMismatchDetail> PortionMismatches { get; set; } = new();
    }

    public class SkippedMealDetail
    {
        public Guid MealPlanItemId { get; set; }
        public DateOnly Date { get; set; }
        public string MealType { get; set; } = string.Empty;
        public string ItemName { get; set; } = string.Empty;
        public int TargetCalories { get; set; }
    }

    public class UnplannedIntakeDetail
    {
        public Guid MealLogId { get; set; }
        public DateTime LoggedAt { get; set; }
        public string MealType { get; set; } = string.Empty;
        public string ItemName { get; set; } = string.Empty;
        public decimal CaloriesKcal { get; set; }
    }

    public class SubstitutedItemDetail
    {
        public Guid MealPlanItemId { get; set; }
        public Guid MealLogId { get; set; }
        public DateOnly Date { get; set; }
        public string MealType { get; set; } = string.Empty;
        public string PlannedItemName { get; set; } = string.Empty;
        public int PlannedCalories { get; set; }
        public string ActualItemName { get; set; } = string.Empty;
        public decimal ActualCalories { get; set; }
    }

    public class PortionMismatchDetail
    {
        public Guid MealPlanItemId { get; set; }
        public Guid MealLogId { get; set; }
        public DateOnly Date { get; set; }
        public string MealType { get; set; } = string.Empty;
        public string ItemName { get; set; } = string.Empty;
        public int PlannedCalories { get; set; }
        public decimal ActualCalories { get; set; }
        public decimal PercentDeviation { get; set; } // +20% or -15%
    }

    public class RecommendationResponse
    {
        public List<string> Insights { get; set; } = new();
        public List<string> ActionableSteps { get; set; } = new();
        public string SummaryMessage { get; set; } = string.Empty;
    }

    public class RecalibrationResponse
    {
        public decimal PreviousTargetCalories { get; set; }
        public decimal NewTargetCalories { get; set; }
        public decimal PreviousTargetProteinG { get; set; }
        public decimal NewTargetProteinG { get; set; }
        public decimal PreviousTargetCarbsG { get; set; }
        public decimal NewTargetCarbsG { get; set; }
        public decimal PreviousTargetFatG { get; set; }
        public decimal NewTargetFatG { get; set; }
        public string RecalibrationReason { get; set; } = string.Empty;
        public decimal WeightChangeKg { get; set; }
        public bool IsUpdated { get; set; }
    }
}
