using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    /// <summary>
    /// Phase 8: Coach creates a PersonalProgram and sends it to a connected client (Gymer).
    /// This is the PT -> Gymer direction, complementary to CreatePtReviewReportRequest which is Gymer -> PT.
    /// </summary>
    public class CreatePersonalProgramRequest
    {
        [Required]
        public Guid ClientId { get; set; } // Gymer userId

        [Required]
        [StringLength(255)]
        public string Title { get; set; } = string.Empty;

        [StringLength(2000)]
        public string? Description { get; set; }

        [Range(1, 52)]
        public int DurationWeeks { get; set; } = 4;

        [Required]
        public DateOnly WeekStartDate { get; set; }

        [Range(800, 6000)]
        public int TargetCaloriesDaily { get; set; } = 2000;

        [Range(20, 400)]
        public int TargetProteinG { get; set; } = 120;

        [Range(50, 600)]
        public int TargetCarbsG { get; set; } = 250;

        [Range(20, 250)]
        public int TargetFatG { get; set; } = 70;

        /// <summary>
        /// PT comments explaining the rationale for this program.
        /// </summary>
        [StringLength(2000)]
        public string? CoachComment { get; set; }

        /// <summary>
        /// Optional meal-by-meal suggestions (re-use PtSuggestedChangeDto semantics).
        /// </summary>
        public List<PtSuggestedChangeDto> SuggestedChanges { get; set; } = new();
    }
}