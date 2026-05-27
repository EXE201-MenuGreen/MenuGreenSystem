using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class BudgetRequest
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public int? BudgetVnd { get; set; }
        public int? TimeLimitMin { get; set; }
        public string? Result { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }

        public virtual User? User { get; set; }
    }
}
