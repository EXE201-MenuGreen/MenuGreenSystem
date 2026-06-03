using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class RecommendationFeedbackRequest
    {
        [Required]
        public Guid RecommendationId { get; set; }

        [Range(1, 5)]
        public int? Rating { get; set; }

        [MaxLength(2000)]
        public string? Feedback { get; set; }
    }
}
