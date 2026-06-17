using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MealPlanUpsertRequest
    {
        [Required]
        public string Title { get; set; } = string.Empty;

        [Required]
        public string PlanType { get; set; } = string.Empty;

        public DateOnly? StartDate { get; set; }
        public DateOnly? EndDate { get; set; }
        public int? TargetCalories { get; set; }
        public string? GeneratedBy { get; set; }
        public bool IsActive { get; set; } = true;
        public List<MealPlanItemUpsertRequest> Items { get; set; } = new();
    }

    /// DTO riêng cho phép tạo plan rỗng (user tạo plan trước, thêm items sau)
    public class CreateEmptyPlanRequest
    {
        [Required]
        public string Title { get; set; } = string.Empty;

        [Required]
        public string PlanType { get; set; } = string.Empty;

        public DateOnly? StartDate { get; set; }
        public DateOnly? EndDate { get; set; }
        public int? TargetCalories { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
