using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class UserAiProfile
    {
        public Guid UserId { get; set; }
        public string? Preferences { get; set; }
        public string? DislikedFoods { get; set; }
        public string? EatingPattern { get; set; }
        public DateTime? UpdatedAt { get; set; }

        public virtual User? User { get; set; }
    }
}
