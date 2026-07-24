using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    /// <summary>
    /// Body for POST /api/Coaches/clients/{clientId}/meal-plans/{planId}/submit.
    /// Optional notes that the Coach appends when sending the meal plan to the
    /// Gymer (used in the notification body).
    /// </summary>
    public class CoachSubmitMealPlanRequest
    {
        [StringLength(500)]
        public string? Notes { get; set; }
    }
}
