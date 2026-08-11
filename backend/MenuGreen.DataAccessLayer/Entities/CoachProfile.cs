using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class CoachProfile
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Specialty { get; set; } = string.Empty;
        public string Headline { get; set; } = string.Empty;
        public string Bio { get; set; } = string.Empty;
        public int ExperienceYears { get; set; }
        public string? CertificateUrl { get; set; }
        public string PhoneNumber { get; set; } = string.Empty;
        public string City { get; set; } = string.Empty;
        public string LanguagesJson { get; set; } = "[]";
        public string CoachingStylesJson { get; set; } = "[]";
        public string ClientLevelsJson { get; set; } = "[]";
        public string CertificatesJson { get; set; } = "[]";
        public string GalleryUrlsJson { get; set; } = "[]";
        public string Achievements { get; set; } = string.Empty;
        public string? IdentityDocumentUrl { get; set; }
        public string ApplicationStatus { get; set; } = "Draft";
        public string? ReviewNote { get; set; }
        public DateTime? SubmittedAt { get; set; }
        public DateTime? ReviewedAt { get; set; }
        public Guid? ReviewedByUserId { get; set; }
        public int PriceVnd { get; set; }
        public bool IsActive { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        public virtual User? User { get; set; }
    }
}
