using System;
using System.ComponentModel.DataAnnotations;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class CoachProfileResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string AvatarUrl { get; set; } = string.Empty;
        public string Specialty { get; set; } = string.Empty;
        public string Bio { get; set; } = string.Empty;
        public int ExperienceYears { get; set; }
        public string? CertificateUrl { get; set; }
        public int PriceVnd { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class CoachClientSummaryResponse
    {
        public Guid ClientId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string AvatarUrl { get; set; } = string.Empty;
        public string ConnectionStatus { get; set; } = string.Empty;
        public bool IsAccessGranted { get; set; }
        public int CurrentStreak { get; set; }
        public bool HasCalorieDriftAlert { get; set; }
        public string ActiveProgramTitle { get; set; } = string.Empty;
        public DateTime ConnectedAt { get; set; }
    }

    public class ClientNutritionSummaryResponse
    {
        public Guid ClientId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public DateOnly Date { get; set; }
        public decimal ActualCalories { get; set; }
        public decimal TargetCalories { get; set; }
        public decimal ActualProtein { get; set; }
        public decimal TargetProtein { get; set; }
        public decimal ActualCarbs { get; set; }
        public decimal TargetCarbs { get; set; }
        public decimal ActualFat { get; set; }
        public decimal TargetFat { get; set; }
    }

    public class ClientWeightTrendResponse
    {
        public Guid Id { get; set; }
        public decimal? WeightKg { get; set; }
        public decimal? BodyFatPercent { get; set; }
        public DateTime? RecordedAt { get; set; }
    }

    public class CoachFeedbackResponse
    {
        public Guid Id { get; set; }
        public Guid ClientId { get; set; }
        public Guid CoachId { get; set; }
        public string CoachName { get; set; } = string.Empty;
        public string FeedbackType { get; set; } = string.Empty; // Meal, Daily, General
        public Guid? TargetId { get; set; }
        public string? MealType { get; set; }
        public DateOnly? LogDate { get; set; }
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CoachRegisterRequest
    {
        [Required(ErrorMessage = "Lĩnh vực chuyên môn không được để trống.")]
        [StringLength(255)]
        public string Specialty { get; set; } = string.Empty;

        [Required(ErrorMessage = "Giới thiệu bản thân không được để trống.")]
        public string Bio { get; set; } = string.Empty;

        [Required(ErrorMessage = "Số năm kinh nghiệm không được để trống.")]
        [Range(0, 100)]
        public int ExperienceYears { get; set; }

        [StringLength(500)]
        public string? CertificateUrl { get; set; }

        [Required(ErrorMessage = "Mức phí dịch vụ không được để trống.")]
        [Range(0, int.MaxValue)]
        public int PriceVnd { get; set; }
    }

    public class CoachApproveConnectionRequest
    {
        [Required]
        public bool Approve { get; set; }
    }

    public class CoachFeedbackCreateRequest
    {
        [Required(ErrorMessage = "Loại nhận xét không được để trống.")]
        public string FeedbackType { get; set; } = "General"; // Meal, Daily, General

        public Guid? TargetId { get; set; }
        public string? MealType { get; set; }
        public DateOnly? LogDate { get; set; }

        [Required(ErrorMessage = "Nội dung nhận xét không được để trống.")]
        public string Content { get; set; } = string.Empty;
    }

    public class ClientHealthTargetsAdjustRequest
    {
        [Required(ErrorMessage = "Calorie mục tiêu không được để trống.")]
        [Range(500, 10000)]
        public int TargetCalories { get; set; }

        [Range(10, 1000)]
        public int TargetProteinG { get; set; }

        [Range(10, 1000)]
        public int TargetCarbsG { get; set; }

        [Range(10, 1000)]
        public int TargetFatG { get; set; }
    }
}
