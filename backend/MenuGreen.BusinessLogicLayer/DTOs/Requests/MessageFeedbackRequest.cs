using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MessageFeedbackRequest
    {
        public bool IsPositive { get; set; } // true = positive/like, false = negative/dislike
        public string? Comment { get; set; }
    }
}
