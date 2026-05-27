using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class Notification
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string? Title { get; set; }
        public string? Body { get; set; }
        public string? Type { get; set; }
        public bool? IsRead { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }

        public virtual User? User { get; set; }
    }
}
