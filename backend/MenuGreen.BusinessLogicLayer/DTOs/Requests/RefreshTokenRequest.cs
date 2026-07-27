using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class RefreshTokenRequest
    {
        [Required]
        [StringLength(4096, MinimumLength = 32)]
        public string RefreshToken { get; set; } = string.Empty;
    }
}
