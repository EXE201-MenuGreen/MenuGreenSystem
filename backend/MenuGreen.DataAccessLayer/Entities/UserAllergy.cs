using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class UserAllergy
    {
        public Guid UserId { get; set; }
        public Guid AllergyId { get; set; }
        public DateTime CreatedAt { get; set; }

        public virtual User? User { get; set; }
        public virtual Allergy? Allergy { get; set; }
    }
}
