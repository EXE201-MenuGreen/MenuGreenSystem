using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CompleteMealPlanItemRequest
    {
        [Range(0.01, double.MaxValue)]
        public decimal? QuantityG { get; set; }
    }
}
