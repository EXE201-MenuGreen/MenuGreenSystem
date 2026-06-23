using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class CustomUserPortion
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string UnitName { get; set; } = string.Empty; // e.g. Small bowl, Rice bowl
        public decimal GramsEquivalent { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        public virtual User? User { get; set; }
    }
}
