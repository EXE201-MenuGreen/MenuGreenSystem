using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class AssignRoleRequest
    {
        [Required]
        [RegularExpression("(?i)^(User|Coach|Admin)$", ErrorMessage = "Role must be User, Coach, or Admin.")]
        public string Role { get; set; } = string.Empty;
    }
}
