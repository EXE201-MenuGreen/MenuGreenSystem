using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class WaterLog
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public int AmountMl { get; set; }
        public DateTime LoggedAt { get; set; }

        // Navigation properties
        public virtual User? User { get; set; }
    }
}
