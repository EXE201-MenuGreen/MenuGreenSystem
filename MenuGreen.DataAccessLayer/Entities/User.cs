using System;
using System.Collections.Generic;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class User
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        
        public bool EmailConfirmed { get; set; } = false;
        public bool IsActive { get; set; } = true;
        
        public DateTimeOffset? LastSignInAt { get; set; }
        public DateTimeOffset CreatedAt { get; set; }
        public DateTimeOffset UpdatedAt { get; set; }
        public DateTimeOffset? DeletedAt { get; set; }

        // Navigation properties
        public virtual Profile? Profile { get; set; }
        public virtual ICollection<Session> Sessions { get; set; } = new List<Session>();
    }
}
