using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class VnMealLogUpsertRequest
    {
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }

        [Required(ErrorMessage = "Bữa ăn không được để trống.")]
        public string MealType { get; set; } = string.Empty;

        [Range(0.01, double.MaxValue, ErrorMessage = "Số lượng phải lớn hơn 0.")]
        public decimal Quantity { get; set; }

        [Required(ErrorMessage = "Đơn vị không được để trống.")]
        public string Unit { get; set; } = "gram";

        public string? Notes { get; set; }
        public DateTime? LoggedAt { get; set; }
        public Guid? MealPlanItemId { get; set; }
    }
}
