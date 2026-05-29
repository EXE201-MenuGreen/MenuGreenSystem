using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class SubscriptionPlanUpsertRequest
    {
        [Required]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        [Range(0, int.MaxValue)]
        public int DurationDays { get; set; }

        [Range(0, int.MaxValue)]
        public int PriceVnd { get; set; }

        public string? FeatureGroup { get; set; }

        public bool IsActive { get; set; } = true;
    }
}
