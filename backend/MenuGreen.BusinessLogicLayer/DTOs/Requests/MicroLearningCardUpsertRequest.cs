using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MicroLearningCardUpsertRequest
    {
        [Required]
        [MaxLength(500)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(2000)]
        public string Summary { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string Category { get; set; } = string.Empty;

        [MaxLength(2000)]
        public string Tips { get; set; } = string.Empty; // Pipe-separated: "Tip 1|Tip 2|Tip 3"

        public string? ImageUrl { get; set; }

        [MaxLength(1000)]
        public string? QuizQuestion { get; set; }

        [MaxLength(1000)]
        public string? QuizOptions { get; set; } // Pipe-separated: "Option A|Option B|Option C|Option D"

        [Range(0, 10)]
        public int? CorrectOptionIndex { get; set; }

        [Range(0, 1000)]
        public int PointsReward { get; set; } = 10;

        public bool IsActive { get; set; } = true;
    }
}
