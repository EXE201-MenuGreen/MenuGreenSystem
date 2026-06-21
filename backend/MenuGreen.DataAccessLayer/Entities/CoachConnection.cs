using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class CoachConnection
    {
        public Guid Id { get; set; }
        public Guid ClientId { get; set; }
        public Guid CoachId { get; set; }
        public string Status { get; set; } = "Pending"; // Pending, Connected, Rejected, Disconnected
        public bool IsAccessGranted { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual User? Client { get; set; }
        public virtual User? Coach { get; set; }
    }
}
