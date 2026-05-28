using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class AllergyUpsertRequest
    {
        [Required]
        public string Name { get; set; } = string.Empty;

        public string? Notes { get; set; }
        public bool? IsActive { get; set; }
    }
}
