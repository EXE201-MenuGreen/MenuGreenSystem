using System;
using System.Collections.Generic;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class MicroLearningCard
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Summary { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty; // Protein, Sodium, Allergy, Hydration, Carb, Fat, General
        public string Tips { get; set; } = string.Empty; // Pipe-separated or simple text list of tips
        public string? ImageUrl { get; set; }
        public string? QuizQuestion { get; set; }
        public string? QuizOptions { get; set; } // Pipe-separated string: "A|B|C|D"
        public int? CorrectOptionIndex { get; set; }
        public int PointsReward { get; set; } = 10;
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual ICollection<UserCardInteraction> UserCardInteractions { get; set; } = new List<UserCardInteraction>();
    }
}
