using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class VerifyOtpRequest
    {
        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Invalid email format.")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "OTP code is required.")]
        [MinLength(6, ErrorMessage = "OTP code must be at least 6 characters long.")]
        [MaxLength(6, ErrorMessage = "OTP code must be 6 characters long.")]
        public string OtpCode { get; set; } = string.Empty;
    }
}
