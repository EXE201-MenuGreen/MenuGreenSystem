using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class RegisterRequest
    {
        [Required(ErrorMessage = "Full name is required.")]
        [MaxLength(255, ErrorMessage = "Full name must not exceed 255 characters.")]
        public string FullName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Invalid email format.")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Password is required.")]
        [MinLength(6, ErrorMessage = "Password must be at least 6 characters long.")]
        public string Password { get; set; } = string.Empty;

        [Required(ErrorMessage = "Account type is required.")]
        [RegularExpression("(?i)^(User|Coach)$", ErrorMessage = "Account type must be User or Coach.")]
        public string AccountType { get; set; } = "User";
    }
}
