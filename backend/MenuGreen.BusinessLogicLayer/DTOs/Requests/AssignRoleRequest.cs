using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class AssignRoleRequest
    {
        [Required]
        public string Role { get; set; } = string.Empty; // e.g., "Admin", "User", "Manager"
    }
}
