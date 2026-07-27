using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class SendMessageRequest
    {
        [Required]
        [StringLength(8000)]
        public string Message { get; set; } = string.Empty;

        [RegularExpression(@"^[a-z]{2}(?:-[A-Z]{2})?$")]
        public string Language { get; set; } = "vi";
        public bool Stream { get; set; } = false;
    }
}
