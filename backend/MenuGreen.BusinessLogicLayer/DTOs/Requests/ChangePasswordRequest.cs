using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class ChangePasswordRequest
    {
        [Required]
        [StringLength(128)]
        public string CurrentPassword { get; set; } = string.Empty;

        [Required]
        [StringLength(128, MinimumLength = 12, ErrorMessage = "New password must be between 12 and 128 characters long.")]
        public string NewPassword { get; set; } = string.Empty;

        [Required]
        [StringLength(128)]
        [Compare(nameof(NewPassword), ErrorMessage = "Confirm password does not match.")]
        public string ConfirmNewPassword { get; set; } = string.Empty;
    }
}
