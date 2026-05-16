using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class Session
    {
        public Guid Id { get; set; }
        
        public Guid UserId { get; set; }
        public string RefreshToken { get; set; } = string.Empty;
        
        public string? UserAgent { get; set; }
        public System.Net.IPAddress? IpAddress { get; set; }
        
        public DateTimeOffset ExpiresAt { get; set; }
        public DateTimeOffset CreatedAt { get; set; }

        // Navigation property
        public virtual User? User { get; set; }
    }
}
