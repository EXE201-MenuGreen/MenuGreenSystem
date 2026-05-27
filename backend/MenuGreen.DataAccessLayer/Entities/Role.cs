using System;
using System.Collections.Generic;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class Role
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        // Navigation properties
        public virtual ICollection<User> Users { get; set; } = new List<User>();
    }
}
