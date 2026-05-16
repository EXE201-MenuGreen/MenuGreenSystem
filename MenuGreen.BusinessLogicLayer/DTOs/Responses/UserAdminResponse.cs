using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class UserAdminResponse
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public bool EmailConfirmed { get; set; }
        public DateTimeOffset CreatedAt { get; set; }
        public DateTimeOffset? LastSignInAt { get; set; }
    }
}
