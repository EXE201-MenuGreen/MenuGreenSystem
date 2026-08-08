using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RegisterResponse
    {
        public Guid UserId { get; set; }
        public string Email { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public bool RequiresOtpVerification { get; set; }
    }
}
