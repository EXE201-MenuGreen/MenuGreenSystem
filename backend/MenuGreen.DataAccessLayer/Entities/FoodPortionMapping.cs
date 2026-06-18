using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class FoodPortionMapping
    {
        public Guid Id { get; set; }
        public Guid FoodId { get; set; }
        public string Unit { get; set; } = string.Empty; // chén, tô, bát, đĩa, muỗng, quả/trái
        public decimal GramsPerUnit { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        public virtual Food? Food { get; set; }
    }
}
