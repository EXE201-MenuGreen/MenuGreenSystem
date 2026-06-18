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
        [Required(ErrorMessage = "Tên đơn vị không được để trống.")]
        [MaxLength(150, ErrorMessage = "Tên đơn vị không được dài quá 150 ký tự.")]
        public string UnitName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Trọng lượng quy đổi không được để trống.")]
        [Range(0.1, 10000.0, ErrorMessage = "Trọng lượng quy đổi phải từ 0.1g đến 10000g.")]
        public decimal GramsEquivalent { get; set; }
    }

    public class PortionConvertRequest
    {
        [Required(ErrorMessage = "FoodId không được để trống.")]
        public Guid FoodId { get; set; }

        [Required(ErrorMessage = "Đơn vị quy đổi không được để trống.")]
        public string Unit { get; set; } = string.Empty;

        [Required(ErrorMessage = "Số lượng không được để trống.")]
        [Range(0.01, 1000.0, ErrorMessage = "Số lượng quy đổi phải từ 0.01 đến 1000.")]
        public decimal Quantity { get; set; }
    }
}
