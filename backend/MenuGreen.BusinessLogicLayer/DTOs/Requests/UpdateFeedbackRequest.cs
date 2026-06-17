using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class UpdateFeedbackRequest
    {
        [Range(1, 5)]
        public int? Rating { get; set; }

        [MaxLength(2000)]
        public string? Comment { get; set; }

        public bool? WouldRecommend { get; set; }
    }
}
