using MenuGreen.BusinessLogicLayer.Services;
using Xunit;

namespace MenuGreen.BusinessLogicLayer.Tests;

public class FeatureAccessResolverTests
{
    private static readonly DateTime Now = new(2026, 7, 22, 8, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Valid_user_without_subscription_always_has_free_features()
    {
        var access = FeatureAccessResolver.Resolve([], Now);

        Assert.Equal("free", access.Tier);
        Assert.Contains(FeatureAccessResolver.FreeFeatures, access.Entitlements);
        Assert.DoesNotContain(FeatureAccessResolver.CasualFeatures, access.Entitlements);
        Assert.DoesNotContain(FeatureAccessResolver.OfficeFeatures, access.Entitlements);
        Assert.DoesNotContain(FeatureAccessResolver.GymFeatures, access.Entitlements);
        Assert.Null(access.ExpiresAt);
    }

    [Fact]
    public void Legacy_basic_subscription_remains_free_without_a_paid_expiry()
    {
        var access = FeatureAccessResolver.Resolve(
            [Snapshot("Active", "basic", Now.AddDays(-1), Now.AddYears(100))],
            Now
        );

        Assert.Equal("free", access.Tier);
        Assert.Equal([FeatureAccessResolver.FreeFeatures], access.Entitlements);
        Assert.Equal(["free"], access.FeatureGroups);
        Assert.Null(access.ExpiresAt);
    }

    [Fact]
    public void Expired_and_cancelled_subscriptions_do_not_grant_paid_features()
    {
        var access = FeatureAccessResolver.Resolve(
            [
                Snapshot("Active", "office", Now.AddDays(-5), Now.AddSeconds(-1)),
                Snapshot("Cancelled", "gym", Now.AddDays(-5), Now.AddDays(5)),
            ],
            Now
        );

        Assert.Equal([FeatureAccessResolver.FreeFeatures], access.Entitlements);
    }

    [Fact]
    public void Multiple_active_subscriptions_merge_entitlements()
    {
        var officeExpiry = Now.AddDays(7);
        var gymExpiry = Now.AddDays(30);
        var access = FeatureAccessResolver.Resolve(
            [
                Snapshot("Active", "office", Now.AddDays(-1), officeExpiry),
                Snapshot("Active", "gym", Now.AddDays(-1), gymExpiry),
            ],
            Now
        );

        Assert.Equal("multi", access.Tier);
        Assert.Contains(FeatureAccessResolver.FreeFeatures, access.Entitlements);
        Assert.Contains(FeatureAccessResolver.OfficeFeatures, access.Entitlements);
        Assert.Contains(FeatureAccessResolver.GymFeatures, access.Entitlements);
        Assert.Contains(FeatureAccessResolver.CoachAccess, access.Entitlements);
        Assert.Equal(gymExpiry, access.ExpiresAt);
    }

    [Fact]
    public void Pro_subscription_keeps_free_and_grants_existing_pro_capabilities()
    {
        var access = FeatureAccessResolver.Resolve(
            [Snapshot("Active", "pro", Now.AddDays(-1), Now.AddDays(30))],
            Now
        );

        Assert.Contains(FeatureAccessResolver.FreeFeatures, access.Entitlements);
        Assert.Contains(FeatureAccessResolver.CasualFeatures, access.Entitlements);
        Assert.Contains(FeatureAccessResolver.GymFeatures, access.Entitlements);
        Assert.Contains(FeatureAccessResolver.CoachAccess, access.Entitlements);
        Assert.Contains(FeatureAccessResolver.AiFeatures, access.Entitlements);
    }

    [Fact]
    public void Future_subscription_does_not_grant_access_before_start_date()
    {
        var access = FeatureAccessResolver.Resolve(
            [Snapshot("Active", "office", Now.AddMinutes(1), Now.AddDays(1))],
            Now
        );

        Assert.Equal([FeatureAccessResolver.FreeFeatures], access.Entitlements);
    }

    private static SubscriptionAccessSnapshot Snapshot(
        string status,
        string group,
        DateTime start,
        DateTime end
    ) => new(status, start, end, group, group);
}
