using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class SendMessageRequest
    {
        [Required]
        public string Message { get; set; } = string.Empty;
        public string Language { get; set; } = "vi";
        public bool Stream { get; set; } = false;
    }
}
