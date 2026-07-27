using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class GoogleLoginRequest
    {
        [Required]
        [StringLength(8192, MinimumLength = 100)]
        public string IdToken { get; set; } = string.Empty;
    }
}
