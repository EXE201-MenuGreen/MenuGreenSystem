using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MealPlanRoutineUpsertRequest
    {
        [Range(0, 24)]
        public int BreakfastHour { get; set; } = 7;

        [Range(0, 59)]
        public int BreakfastMinute { get; set; } = 0;

        [Range(0, 24)]
        public int LunchHour { get; set; } = 12;

        [Range(0, 59)]
        public int LunchMinute { get; set; } = 0;

        [Range(0, 24)]
        public int DinnerHour { get; set; } = 18;

        [Range(0, 59)]
        public int DinnerMinute { get; set; } = 0;

        [Range(0, 24)]
        public int SnackHour { get; set; } = 15;

        [Range(0, 59)]
        public int SnackMinute { get; set; } = 0;
    }
}
