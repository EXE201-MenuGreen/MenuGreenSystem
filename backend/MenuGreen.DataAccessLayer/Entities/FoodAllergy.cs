using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class FoodAllergy
    {
        public Guid FoodId { get; set; }
        public Guid AllergyId { get; set; }

        public virtual Food? Food { get; set; }
        public virtual Allergy? Allergy { get; set; }
    }
}
