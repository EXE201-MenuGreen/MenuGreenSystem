using System;
using System.Collections.Generic;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    /// <summary>
    /// Phase 8: Response for PersonalProgram (Coach -> Gymer direction).
    /// Returned to Gymer via GET /api/PtReview/my-personal-programs.
    /// </summary>
    public class PersonalProgramResponse
    {
        public Guid Id { get; set; }
        public Guid ClientId { get; set; }
        public string ClientName { get; set; } = string.Empty;

        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }

        public int DurationWeeks { get; set; }
        public DateOnly WeekStartDate { get; set; }

        public int TargetCaloriesDaily { get; set; }
        public int? MinCalories { get; set; }
        public int? MaxCalories { get; set; }
        public int TargetProteinG { get; set; }
        public int TargetCarbsG { get; set; }
        public int TargetFatG { get; set; }

        public string? CoachComment { get; set; }
        public List<PtSuggestedChangeDto> SuggestedChanges { get; set; } = new();
        public Guid? MealPlanId { get; set; }
        public string PlanType { get; set; } = "DAILY";
        public DateOnly StartDate { get; set; }
        public DateOnly EndDate { get; set; }
        public List<PersonalProgramMealDto> Meals { get; set; } = new();

        public string Status { get; set; } = "Pending"; // Pending, Accepted, Rejected
        public DateTime CreatedAt { get; set; }
        public DateTime? AcceptedAt { get; set; }
    }

    /// <summary>
    /// Phase 8: Coach views the list of PersonalPrograms they have sent to clients.
    /// </summary>
    public class CoachSentProgramResponse
    {
        public Guid Id { get; set; }
        public Guid ClientId { get; set; }
        public string ClientName { get; set; } = string.Empty;

        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int DurationWeeks { get; set; }
        public DateOnly WeekStartDate { get; set; }

        public int TargetCaloriesDaily { get; set; }
        public int? MinCalories { get; set; }
        public int? MaxCalories { get; set; }
        public int TargetProteinG { get; set; }
        public int TargetCarbsG { get; set; }
        public int TargetFatG { get; set; }

        public string Status { get; set; } = "Pending";
        public DateTime CreatedAt { get; set; }
        public DateTime? AcceptedAt { get; set; }
        public Guid? MealPlanId { get; set; }
        public string PlanType { get; set; } = "DAILY";
        public DateOnly StartDate { get; set; }
        public DateOnly EndDate { get; set; }
        public int MealCount { get; set; }
    }

    public class CreatePersonalProgramResponse
    {
        public Guid ProgramId { get; set; }
        public Guid ClientId { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
