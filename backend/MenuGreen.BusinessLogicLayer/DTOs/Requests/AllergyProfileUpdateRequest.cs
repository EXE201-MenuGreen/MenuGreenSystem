using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class AllergenProfileItem
    {
        [Required]
        public string AllergenKey { get; set; } = string.Empty;

        public string? Name { get; set; }

        public string? Notes { get; set; }
    }

    public class AllergyProfileUpdateRequest
    {
        [Required]
        public List<AllergenProfileItem> Allergens { get; set; } = new();
    }
}
