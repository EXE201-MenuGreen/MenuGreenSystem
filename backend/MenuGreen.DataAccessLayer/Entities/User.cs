using System;
using System.Collections.Generic;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class User
    {
        public Guid Id { get; set; }
        public Guid RoleId { get; set; }
        
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        
        public bool EmailConfirmed { get; set; } = false;
        public bool IsActive { get; set; } = true;
        
        public DateTime? LastSignInAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public DateTime? DeletedAt { get; set; }

        // Navigation properties
        public virtual Role? Role { get; set; }
        public virtual Profile? Profile { get; set; }
        public virtual HealthProfile? HealthProfile { get; set; }
        public virtual ICollection<Session> Sessions { get; set; } = new List<Session>();
    }
}
