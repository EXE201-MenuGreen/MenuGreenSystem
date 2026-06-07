using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MealPlanConvertToLogRequest
    {
        public DateTime? LoggedAt { get; set; }
        public string? Notes { get; set; }
    }
}
