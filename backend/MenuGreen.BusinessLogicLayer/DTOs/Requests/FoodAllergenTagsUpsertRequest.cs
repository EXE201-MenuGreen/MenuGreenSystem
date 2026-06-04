using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class FoodAllergenTagsUpsertRequest
    {
        [Required]
        public List<string> AllergenKeys { get; set; } = new();
    }
}
