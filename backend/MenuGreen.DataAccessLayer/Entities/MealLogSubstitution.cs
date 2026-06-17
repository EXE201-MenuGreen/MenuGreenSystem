using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class MealLogSubstitution
    {
        public Guid Id { get; set; }
        public Guid MealLogId { get; set; }
        public Guid OriginalIngredientId { get; set; }
        public Guid SubstituteIngredientId { get; set; }
        public double OriginalQuantity { get; set; }
        public double SubstituteQuantity { get; set; }
        public DateTime CreatedAt { get; set; }

        public virtual MealLog? MealLog { get; set; }
        public virtual Ingredient? OriginalIngredient { get; set; }
        public virtual Ingredient? SubstituteIngredient { get; set; }
    }
}
