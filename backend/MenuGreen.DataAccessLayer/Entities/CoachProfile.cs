using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class CoachProfile
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Specialty { get; set; } = string.Empty;
        public string Bio { get; set; } = string.Empty;
        public int ExperienceYears { get; set; }
        public string? CertificateUrl { get; set; }
        public int PriceVnd { get; set; }
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        public virtual User? User { get; set; }
    }
}
