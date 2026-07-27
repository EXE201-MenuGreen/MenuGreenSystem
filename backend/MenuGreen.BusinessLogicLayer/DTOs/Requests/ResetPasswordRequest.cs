using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class ResetPasswordRequest
    {
        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Invalid email format.")]
        [StringLength(254)]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "OTP code is required.")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "OTP code must contain exactly 6 digits.")]
        public string OtpCode { get; set; } = string.Empty;

        [Required(ErrorMessage = "New password is required.")]
        [StringLength(128, MinimumLength = 12, ErrorMessage = "Password must be between 12 and 128 characters long.")]
        public string NewPassword { get; set; } = string.Empty;
    }
}
