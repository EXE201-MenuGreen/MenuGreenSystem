using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class FoodAllergenTag
    {
        public Guid FoodId { get; set; }
        public string AllergenKey { get; set; } = string.Empty;

        public virtual Food? Food { get; set; }
    }
}
