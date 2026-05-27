using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class FavoriteFood
    {
        public Guid UserId { get; set; }
        public Guid FoodId { get; set; }
        public DateTime CreatedAt { get; set; }

        // Navigation properties
        public virtual User? User { get; set; }
        public virtual Food? Food { get; set; }
    }
}
