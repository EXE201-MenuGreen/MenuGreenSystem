using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class RecommendationFeedback
    {
        public Guid Id { get; set; }
        public Guid RecommendationId { get; set; }
        public int? Rating { get; set; } // 1 - 5 stars
        public string? Feedback { get; set; }
        public DateTime? CreatedAt { get; set; }

        // Navigation properties
        public virtual RecommendationHistory? Recommendation { get; set; }
    }
}
