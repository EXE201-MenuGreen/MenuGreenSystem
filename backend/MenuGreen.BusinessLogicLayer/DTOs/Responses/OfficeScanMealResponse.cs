using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class OfficeScanMealResponse
    {
        public Guid MealPlanId { get; set; }
        public Guid MealPlanItemId { get; set; }
        public Guid MealLogId { get; set; }
        public bool ReplacedExisting { get; set; }
        public string DisplayName { get; set; } = string.Empty;
    }
}
