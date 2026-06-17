using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class UserSubstitutePreferenceUpsertRequest
    {
        [Required]
        public Guid OriginalIngredientId { get; set; }

        [Required]
        public Guid SubstituteIngredientId { get; set; }
    }
}
