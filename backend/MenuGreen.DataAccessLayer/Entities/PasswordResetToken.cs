using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class PasswordResetToken
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Token { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
        public DateTime? UsedAt { get; set; }
        public DateTime CreatedAt { get; set; }

        // Navigation properties
        public virtual User? User { get; set; }
    }
}
