using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AdminUserMembershipResponse
    {
        public Guid UserId { get; set; }
        public string Tier { get; set; } = "free";
        public IReadOnlyList<string> Entitlements { get; set; } = Array.Empty<string>();
        public IReadOnlyList<string> FeatureGroups { get; set; } = Array.Empty<string>();
        public DateTime? ExpiresAt { get; set; }
        public IReadOnlyList<AdminMembershipItemResponse> Memberships { get; set; } = Array.Empty<AdminMembershipItemResponse>();
    }

    public class AdminMembershipItemResponse
    {
        public Guid SubscriptionId { get; set; }
        public Guid PlanId { get; set; }
        public string PlanName { get; set; } = string.Empty;
        public string FeatureGroup { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public DateTime? CancelledAt { get; set; }
        public DateTime? RenewedAt { get; set; }
        public int DaysRemaining { get; set; }
    }
}
