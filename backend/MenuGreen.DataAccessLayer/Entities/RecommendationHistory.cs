using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class RecommendationHistory
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string? Type { get; set; }
        public string? Input { get; set; }
        public string? Output { get; set; }
        public decimal? Confidence { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }

        public virtual User? User { get; set; }
    }
}
