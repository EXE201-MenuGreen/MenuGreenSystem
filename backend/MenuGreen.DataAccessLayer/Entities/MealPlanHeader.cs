using System;
using System.Collections.Generic;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class MealPlanHeader
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string? Title { get; set; }
        public string? PlanType { get; set; } // DAILY / WEEKLY / MONTHLY
        public DateOnly? StartDate { get; set; }
        public DateOnly? EndDate { get; set; }
        public int? TargetCalories { get; set; }
        public string? GeneratedBy { get; set; } // AI / USER / SYSTEM
        public bool IsActive { get; set; } = true;
        public DateTime? CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        // Navigation properties
        public virtual User? User { get; set; }
        public virtual ICollection<MealPlanItem> MealPlanItems { get; set; } = new List<MealPlanItem>();
    }
}
