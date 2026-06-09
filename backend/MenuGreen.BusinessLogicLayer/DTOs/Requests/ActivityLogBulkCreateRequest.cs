using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class ActivityLogBulkCreateRequest
    {
        [Required]
        public List<ActivityLogCreateRequest> Items { get; set; } = new();
    }
}
