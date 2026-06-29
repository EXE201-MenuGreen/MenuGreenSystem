using System;
using System.ComponentModel.DataAnnotations;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CvMealLogCreateRequest
    {
        [Required]
        public CvSuggestedDish Dish { get; set; } = new();

        [Required]
        public string MealType { get; set; } = string.Empty;

        [Range(0.01, double.MaxValue)]
        public decimal QuantityG { get; set; } = 100m;

        public DateTime? LoggedAt { get; set; }
        public string? Notes { get; set; }
        public string? AnalysisJobId { get; set; }
        public string? AnalysisRequestId { get; set; }
    }
}
