using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class QuizSubmitRequest
    {
        [Required]
        [Range(0, 10)]
        public int SelectedOptionIndex { get; set; }
    }
}
