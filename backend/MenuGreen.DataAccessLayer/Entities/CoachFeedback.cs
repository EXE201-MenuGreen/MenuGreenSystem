using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class CoachFeedback
    {
        public Guid Id { get; set; }
        public Guid ClientId { get; set; }
        public Guid CoachId { get; set; }
        public string FeedbackType { get; set; } = "General"; // Meal, Daily, General
        public Guid? TargetId { get; set; } // ID of MealLog or MealPlanHeader
        public string? MealType { get; set; } // breakfast, lunch, dinner
        public DateOnly? LogDate { get; set; }
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual User? Client { get; set; }
        public virtual User? Coach { get; set; }
    }
}
