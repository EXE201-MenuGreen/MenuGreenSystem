using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class GymGoalUpsertRequest
    {
        [Required]
        public string GoalMode { get; set; } = string.Empty; // cut | bulk | maintain | recomp

        public string WeeklyTrainingSchedule { get; set; } = string.Empty;

        public int? TrainingDaysPerWeek { get; set; }
        public int? RestDaysPerWeek { get; set; }
        public int? TrainingDayTargetCalories { get; set; }
        public int? RestDayTargetCalories { get; set; }
        public int? MinCalories { get; set; }
        public int? MaxCalories { get; set; }
        public int? MinProteinG { get; set; }
        public int? MaxProteinG { get; set; }

        [Range(30.0, 300.0, ErrorMessage = "Target weight must be between 30kg and 300kg.")]
        public decimal? TargetWeightKg { get; set; }

        [Range(1.0, 80.0, ErrorMessage = "Target body fat percentage must be between 1% and 80%.")]
        public decimal? TargetBodyFatPercent { get; set; }

        public string? Preferences { get; set; }
        public string? Notes { get; set; }
    }
}
