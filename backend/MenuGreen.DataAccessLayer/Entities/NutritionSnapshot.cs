using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class NutritionSnapshot
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public DateOnly? SnapshotDate { get; set; }
        public decimal? TotalCalories { get; set; }
        public decimal? TotalProteinG { get; set; }
        public decimal? TotalCarbsG { get; set; }
        public decimal? TotalFatG { get; set; }
        public decimal? GoalCompletionPercent { get; set; }

        public virtual User? User { get; set; }
    }
}
