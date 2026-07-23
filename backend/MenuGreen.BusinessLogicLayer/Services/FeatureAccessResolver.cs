using System;
using System.Collections.Generic;
using System.Linq;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public sealed record SubscriptionAccessSnapshot(
        string Status,
        DateTime StartDate,
        DateTime EndDate,
        string? FeatureGroup,
        string? PlanName
    );

    public static class FeatureAccessResolver
    {
        public const string FreeFeatures = "free_features";
        public const string CasualFeatures = "casual_features";
        public const string OfficeFeatures = "office_features";
        public const string GymFeatures = "gym_features";
        public const string CoachAccess = "coach_access";
        public const string AiFeatures = "ai_features";

        public static FeatureAccessResponse Resolve(
            IEnumerable<SubscriptionAccessSnapshot> subscriptions,
            DateTime nowUtc
        )
        {
            var entitlements = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                FreeFeatures,
            };
            var featureGroups = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "free",
            };
            DateTime? latestPaidExpiry = null;

            foreach (
                var subscription in subscriptions.Where(x =>
                    string.Equals(x.Status, "Active", StringComparison.OrdinalIgnoreCase)
                    && x.StartDate <= nowUtc
                    && x.EndDate > nowUtc
                )
            )
            {
                var group = Normalize(subscription.FeatureGroup);
                var planName = Normalize(subscription.PlanName);
                var matchedPaidGroup = false;

                if (group == "casual" || planName.Contains("casual"))
                {
                    entitlements.Add(CasualFeatures);
                    featureGroups.Add("casual");
                    matchedPaidGroup = true;
                }

                if (group == "office" || planName.Contains("office"))
                {
                    entitlements.Add(OfficeFeatures);
                    featureGroups.Add("office");
                    matchedPaidGroup = true;
                }

                if (group == "gym" || planName.Contains("gym"))
                {
                    entitlements.Add(GymFeatures);
                    entitlements.Add(CoachAccess);
                    entitlements.Add(AiFeatures);
                    featureGroups.Add("gym");
                    matchedPaidGroup = true;
                }

                if (
                    group is "pro" or "premium" or "vip" or "gold"
                    || planName.Contains("pro")
                    || planName.Contains("premium")
                    || planName.Contains("vip")
                    || planName.Contains("gold")
                )
                {
                    entitlements.Add(CasualFeatures);
                    entitlements.Add(GymFeatures);
                    entitlements.Add(CoachAccess);
                    entitlements.Add(AiFeatures);
                    featureGroups.Add("casual");
                    featureGroups.Add("gym");
                    featureGroups.Add("pro");
                    matchedPaidGroup = true;
                }

                if (
                    matchedPaidGroup
                    && (!latestPaidExpiry.HasValue || subscription.EndDate > latestPaidExpiry.Value)
                )
                {
                    latestPaidExpiry = subscription.EndDate;
                }
            }

            var paidGroups = featureGroups.Where(x => x != "free").OrderBy(x => x).ToList();
            var tier = paidGroups.Count switch
            {
                0 => "free",
                1 => paidGroups[0],
                _ => "multi",
            };

            return new FeatureAccessResponse
            {
                Tier = tier,
                Entitlements = entitlements.OrderBy(x => x).ToArray(),
                FeatureGroups = featureGroups.OrderBy(x => x).ToArray(),
                ExpiresAt = latestPaidExpiry,
            };
        }

        private static string Normalize(string? value) =>
            value?.Trim().Trim('"').ToLowerInvariant() ?? string.Empty;
    }
}
