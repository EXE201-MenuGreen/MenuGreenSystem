using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class PortionUnitResponse
    {
        public string UnitName { get; set; } = string.Empty;
        public decimal GramsPerUnit { get; set; }
        public string Description { get; set; } = string.Empty;
    }

    public class PortionConvertResponse
    {
        public Guid FoodId { get; set; }
        public string OriginalUnit { get; set; } = string.Empty;
        public decimal OriginalQuantity { get; set; }
        public decimal ConvertedGrams { get; set; }
        public decimal CaloriesKcal { get; set; }
        public decimal ProteinG { get; set; }
        public decimal CarbsG { get; set; }
        public decimal FatG { get; set; }
    }

    public class CustomUserPortionResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string UnitName { get; set; } = string.Empty;
        public decimal GramsEquivalent { get; set; }
    }
}

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CustomUserPortionUpsertRequest
    {
        [Required(ErrorMessage = "Unit name is required.")]
        [MaxLength(150, ErrorMessage = "Unit name cannot exceed 150 characters.")]
        public string UnitName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Equivalent weight is required.")]
        [Range(0.1, 10000.0, ErrorMessage = "Equivalent weight must be between 0.1g and 10000g.")]
        public decimal GramsEquivalent { get; set; }
    }

    public class PortionConvertRequest
    {
        [Required(ErrorMessage = "Food ID is required.")]
        public Guid FoodId { get; set; }

        [Required(ErrorMessage = "Conversion unit is required.")]
        public string Unit { get; set; } = string.Empty;

        [Required(ErrorMessage = "Quantity is required.")]
        [Range(0.01, 1000.0, ErrorMessage = "Conversion quantity must be between 0.01 and 1000.")]
        public decimal Quantity { get; set; }
    }
}
