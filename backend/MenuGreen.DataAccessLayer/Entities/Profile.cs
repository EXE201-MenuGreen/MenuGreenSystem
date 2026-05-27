using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class Profile
    {
        // For a 1-1 relationship, UserId is both PK and FK referencing User.Id
        public Guid UserId { get; set; }

        public string? FullName { get; set; }
        public string? AvatarUrl { get; set; }

        public DateOnly? DateOfBirth { get; set; }
        public string? Gender { get; set; }
        public string? PreferredCuisine { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        // Navigation property
        public virtual User? User { get; set; }
    }
}
