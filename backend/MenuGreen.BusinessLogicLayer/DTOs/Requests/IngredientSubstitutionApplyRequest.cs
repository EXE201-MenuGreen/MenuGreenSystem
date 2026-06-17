using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class IngredientSubstitutionApplyRequest
    {
        [Required]
        public Guid OriginalIngredientId { get; set; }

        [Required]
        public Guid SubstituteIngredientId { get; set; }

        [Required]
        [Range(0.01, 100000.0, ErrorMessage = "Khối lượng nguyên liệu gốc phải lớn hơn 0.")]
        public double OriginalQuantity { get; set; }

        [Required]
        [Range(0.01, 100000.0, ErrorMessage = "Khối lượng nguyên liệu thay thế phải lớn hơn 0.")]
        public double SubstituteQuantity { get; set; }
    }
}
