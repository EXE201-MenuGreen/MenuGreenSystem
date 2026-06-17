using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class BudgetRequestResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public int BudgetVnd { get; set; }
        public int TimeLimitMin { get; set; }
        public string? Result { get; set; }
        public DateTimeOffset CreatedAt { get; set; }
    }
}
