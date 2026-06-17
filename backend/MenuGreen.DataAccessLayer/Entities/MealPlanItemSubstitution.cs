using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class MealPlanItemSubstitution
    {
        public Guid Id { get; set; }
        public Guid MealPlanItemId { get; set; }
        public Guid OriginalIngredientId { get; set; }
        public Guid SubstituteIngredientId { get; set; }
        public double OriginalQuantity { get; set; }
        public double SubstituteQuantity { get; set; }
        public DateTime CreatedAt { get; set; }

        public virtual MealPlanItem? MealPlanItem { get; set; }
        public virtual Ingredient? OriginalIngredient { get; set; }
        public virtual Ingredient? SubstituteIngredient { get; set; }
    }
}
