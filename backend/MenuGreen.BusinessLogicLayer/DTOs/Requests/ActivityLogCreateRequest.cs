using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class ActivityLogCreateRequest
    {
        [Required]
        public string Action { get; set; } = string.Empty;

        public string? EntityType { get; set; }

        public Guid? EntityId { get; set; }

        public string? Metadata { get; set; }

        public DateTimeOffset? CreatedAt { get; set; }
    }
}
