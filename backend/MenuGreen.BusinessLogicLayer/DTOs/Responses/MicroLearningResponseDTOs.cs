using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MicroLearningCardResponse
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Summary { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public List<string> Tips { get; set; } = new List<string>();
        public string? ImageUrl { get; set; }
        
        // Quiz Details
        public string? QuizQuestion { get; set; }
        public List<string> QuizOptions { get; set; } = new List<string>();
        public int PointsReward { get; set; }

        // User specific state
        public bool IsSaved { get; set; }
        public bool IsRead { get; set; }
        public bool IsQuizCompleted { get; set; }
        public bool? IsQuizCorrect { get; set; }
        public int? SelectedQuizOption { get; set; }
    }

    public class MicroLearningCategoryResponse
    {
        public string Name { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Icon { get; set; } = string.Empty;
        public int TotalCards { get; set; }
    }

    public class QuizSubmitResponse
    {
        public bool IsCorrect { get; set; }
        public int CorrectOptionIndex { get; set; }
        public string Feedback { get; set; } = string.Empty;
        public int PointsEarned { get; set; }
    }
}
