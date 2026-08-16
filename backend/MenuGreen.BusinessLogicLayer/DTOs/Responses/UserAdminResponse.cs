using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class UserAdminResponse
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public string MembershipTier { get; set; } = "none";
        public string MembershipStatus { get; set; } = "NoSubscription";
        public IReadOnlyList<string> Entitlements { get; set; } = new[] { "free_features" };
        public DateTime? MembershipExpiresAt { get; set; }
        public bool IsActive { get; set; }
        public bool EmailConfirmed { get; set; }
        public DateTimeOffset CreatedAt { get; set; }
        public DateTimeOffset? LastSignInAt { get; set; }
    }
}
