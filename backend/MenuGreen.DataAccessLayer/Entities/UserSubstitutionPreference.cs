using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class UserSubstitutionPreference
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid OriginalIngredientId { get; set; }
        public Guid SubstituteIngredientId { get; set; }
        public DateTime CreatedAt { get; set; }

        public virtual User? User { get; set; }
        public virtual Ingredient? OriginalIngredient { get; set; }
        public virtual Ingredient? SubstituteIngredient { get; set; }
    }
}
