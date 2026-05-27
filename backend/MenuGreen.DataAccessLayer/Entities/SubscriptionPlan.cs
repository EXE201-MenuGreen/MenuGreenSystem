using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class SubscriptionPlan
    {
        public Guid Id { get; set; }
        public string? Name { get; set; }
        public string? Description { get; set; }
        public int? DurationDays { get; set; }
        public int? PriceVnd { get; set; }
        public string? FeatureGroup { get; set; }
        public bool? IsActive { get; set; }
    }
}
