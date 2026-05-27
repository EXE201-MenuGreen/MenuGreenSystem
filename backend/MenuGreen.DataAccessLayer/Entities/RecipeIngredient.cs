using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class RecipeIngredient
    {
        public Guid Id { get; set; }
        public Guid RecipeId { get; set; }
        public Guid IngredientId { get; set; }
        public decimal? Quantity { get; set; }
        public string? Unit { get; set; }
        public string? Notes { get; set; }

        public virtual Recipe? Recipe { get; set; }
        public virtual Ingredient? Ingredient { get; set; }
    }
}
