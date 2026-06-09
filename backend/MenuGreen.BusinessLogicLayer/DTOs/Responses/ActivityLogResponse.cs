using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class ActivityLogResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string? Action { get; set; }
        public string? EntityType { get; set; }
        public Guid? EntityId { get; set; }
        public string? Metadata { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }
    }
}
