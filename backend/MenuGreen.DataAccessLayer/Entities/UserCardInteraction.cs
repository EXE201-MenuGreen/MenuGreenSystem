using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class UserCardInteraction
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid CardId { get; set; }
        public bool IsSaved { get; set; } = false;
        public bool IsDismissed { get; set; } = false;
        public bool IsRead { get; set; } = false;
        public bool IsQuizCompleted { get; set; } = false;
        public int? SelectedQuizOption { get; set; }
        public bool? IsQuizCorrect { get; set; }
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual User? User { get; set; }
        public virtual MicroLearningCard? MicroLearningCard { get; set; }
    }
}
