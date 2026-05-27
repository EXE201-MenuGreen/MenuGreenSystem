using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class EmailVerification
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string OtpCode { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
        public DateTime? VerifiedAt { get; set; }
        public DateTime CreatedAt { get; set; }

        // Navigation properties
        public virtual User? User { get; set; }
    }
}
