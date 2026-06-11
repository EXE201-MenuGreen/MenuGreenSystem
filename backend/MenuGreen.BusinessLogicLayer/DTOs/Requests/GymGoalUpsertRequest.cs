using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class GymGoalUpsertRequest
    {
        [Required]
        public string GoalMode { get; set; } = string.Empty; // cut | bulk | maintain | recomp

        [Required]
        public string WeeklyTrainingSchedule { get; set; } = string.Empty;

        public int? TrainingDaysPerWeek { get; set; }
        public int? RestDaysPerWeek { get; set; }
        public int? TrainingDayTargetCalories { get; set; }
        public int? RestDayTargetCalories { get; set; }
        public int? MinCalories { get; set; }
        public int? MaxCalories { get; set; }
        public int? MinProteinG { get; set; }
        public int? MaxProteinG { get; set; }
        public string? Notes { get; set; }
    }
}
