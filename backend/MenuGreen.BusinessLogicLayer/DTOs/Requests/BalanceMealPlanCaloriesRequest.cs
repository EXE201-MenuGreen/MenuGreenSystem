using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class BalanceMealPlanCaloriesRequest
    {
        [Range(1, 20000)]
        public int TargetCalories { get; set; }

        public DateOnly PlannedDate { get; set; }

        [MinLength(1)]
        public List<Guid> ItemIds { get; set; } = new();

        /// <summary>
        /// Scale the selected portions without replacing the configured daily
        /// nutrition target. Gymer uses this when choosing an intake below or
        /// above the recommended target.
        /// </summary>
        public bool PreservePlanTarget { get; set; }
    }
}
