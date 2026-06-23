using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class BudgetRequestUpsertRequest
    {
        [Required]
        [Range(1000, 100000000, ErrorMessage = "Ngân sách tối thiểu từ 1,000 VND và tối đa 100,000,000 VND.")]
        public int BudgetVnd { get; set; }

        [Required]
        [Range(5, 1440, ErrorMessage = "Giới hạn thời gian nấu từ 5 phút đến tối đa 1,440 phút.")]
        public int TimeLimitMin { get; set; }
    }
}
