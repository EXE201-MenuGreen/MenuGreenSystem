using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class FridgeItem
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid? IngredientId { get; set; }
        public string? CustomName { get; set; }
        public decimal? Quantity { get; set; }
        public string? Unit { get; set; }
        public decimal? MinimumQuantity { get; set; }
        public DateOnly? PurchaseDate { get; set; }
        public DateOnly? ExpiresAt { get; set; }
        public DateTime? AddedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        public virtual User? User { get; set; }
        public virtual Ingredient? Ingredient { get; set; }
    }
}
