using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class PremiumProgramResponse
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int DurationWeeks { get; set; }
        public int TargetCaloriesDaily { get; set; }
        public string GoalType { get; set; } = string.Empty;
        public int PriceVnd { get; set; }
        public string SampleMenu { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class UserPremiumProgramResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid ProgramId { get; set; }
        public string ProgramTitle { get; set; } = string.Empty;
        public DateOnly? StartDate { get; set; }
        public string Status { get; set; } = string.Empty; // PendingPayment, Paid, Active, Completed
        public int CurrentWeek { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<UserProgramMilestoneResponse> Milestones { get; set; } = new();
    }

    public class UserProgramMilestoneResponse
    {
        public Guid Id { get; set; }
        public int WeekNumber { get; set; }
        public bool IsUnlocked { get; set; }
        public bool IsCheckedIn { get; set; }
        public decimal? WeightKg { get; set; }
        public decimal? BodyFatPercent { get; set; }
        public DateTime? CheckInDate { get; set; }
        public DateTime? UnlockedAt { get; set; }
    }

    public class ProgramReportResponse
    {
        public Guid UserProgramId { get; set; }
        public string ProgramTitle { get; set; } = string.Empty;
        public int TotalWeeks { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateOnly? StartDate { get; set; }
        public decimal? StartWeight { get; set; }
        public decimal? EndWeight { get; set; }
        public decimal? WeightChange { get; set; }
        public decimal? StartBodyFat { get; set; }
        public decimal? EndBodyFat { get; set; }
        public decimal? BodyFatChange { get; set; }
        public double AverageAdherenceRate { get; set; }
        public List<MilestoneWeightProgress> ProgressTrend { get; set; } = new();
    }

    public class MilestoneWeightProgress
    {
        public int WeekNumber { get; set; }
        public decimal? WeightKg { get; set; }
        public decimal? BodyFatPercent { get; set; }
        public DateTime? CheckInDate { get; set; }
    }
}

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class ProgramCheckInRequest
    {
        [Required(ErrorMessage = "Cân nặng không được để trống.")]
        [Range(30.0, 300.0, ErrorMessage = "Cân nặng phải từ 30kg đến 300kg.")]
        public decimal WeightKg { get; set; }

        [Range(1.0, 80.0, ErrorMessage = "Tỷ lệ mỡ cơ thể phải từ 1% đến 80%.")]
        public decimal? BodyFatPercent { get; set; }
    }

    public class ProgramActivationRequest
    {
        [Required(ErrorMessage = "Ngày bắt đầu không được để trống.")]
        public DateOnly StartDate { get; set; }
    }
}
