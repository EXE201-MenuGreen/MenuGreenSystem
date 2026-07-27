using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class VerifyOtpRequest
    {
        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Invalid email format.")]
        [StringLength(254)]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "OTP code is required.")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "OTP code must contain exactly 6 digits.")]
        public string OtpCode { get; set; } = string.Empty;
    }
}
