using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class NotificationTrackRequest
    {
        [StringLength(500)]
        public string? Source { get; set; }

        [StringLength(500)]
        public string? Metadata { get; set; }
    }
}
