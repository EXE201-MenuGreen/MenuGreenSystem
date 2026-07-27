using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MessageFeedbackRequest
    {
        public bool IsPositive { get; set; } // true = positive/like, false = negative/dislike
        [StringLength(2000)]
        public string? Comment { get; set; }
    }
}
