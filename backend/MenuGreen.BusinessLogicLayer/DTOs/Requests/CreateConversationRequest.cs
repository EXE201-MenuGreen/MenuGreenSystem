using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CreateConversationRequest
    {
        [StringLength(8000)]
        public string? FirstMessage { get; set; }
    }
}
