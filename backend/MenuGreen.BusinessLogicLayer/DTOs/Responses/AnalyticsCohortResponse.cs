using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AnalyticsCohortResponse
    {
        public DateOnly? CohortDate { get; set; }
        public int Users { get; set; }
        public int Events { get; set; }
    }
}
