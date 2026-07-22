using System.Net;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Text.Encodings.Web;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Xunit;

namespace MenuGreen.API.Tests;

public class FreeAccessAuthorizationTests : IClassFixture<FreeUserApiFactory>
{
    private readonly FreeUserApiFactory _factory;

    public FreeAccessAuthorizationTests(FreeUserApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Entitlements_WithoutAuthentication_ReturnsUnauthorized()
    {
        using var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/UserSubscription/me/entitlements");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Entitlements_ForFreeUser_ReturnsFreeAccess()
    {
        using var client = CreateAuthenticatedClient();

        var response = await client.GetAsync("/api/UserSubscription/me/entitlements");
        var access = await response.Content.ReadFromJsonAsync<FeatureAccessResponse>();

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(access);
        Assert.Equal("free", access.Tier);
        Assert.Contains("free_features", access.Entitlements);
    }

    [Fact]
    public async Task LuckyWheel_ForFreeUser_ReturnsForbidden()
    {
        using var client = CreateAuthenticatedClient();

        var response = await client.GetAsync("/api/LuckyWheel/foods");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    private HttpClient CreateAuthenticatedClient()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add(TestAuthenticationHandler.UserHeader, "free-user");
        return client;
    }
}

public sealed class FreeUserApiFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");
        builder.ConfigureTestServices(services =>
        {
            services.RemoveAll<IFeatureAccessService>();
            services.AddSingleton<IFeatureAccessService, FreeFeatureAccessService>();

            services
                .AddAuthentication(options =>
                {
                    options.DefaultAuthenticateScheme = TestAuthenticationHandler.SchemeName;
                    options.DefaultChallengeScheme = TestAuthenticationHandler.SchemeName;
                    options.DefaultForbidScheme = TestAuthenticationHandler.SchemeName;
                })
                .AddScheme<AuthenticationSchemeOptions, TestAuthenticationHandler>(
                    TestAuthenticationHandler.SchemeName,
                    _ => { }
                );
        });
    }
}

internal sealed class FreeFeatureAccessService : IFeatureAccessService
{
    private static readonly FeatureAccessResponse FreeAccess = new()
    {
        Tier = "free",
        Entitlements = ["free_features"],
        FeatureGroups = ["free"],
    };

    public Task<FeatureAccessResponse> GetAsync(Guid userId) => Task.FromResult(FreeAccess);

    public Task<bool> HasEntitlementAsync(Guid userId, string entitlement) =>
        Task.FromResult(string.Equals(entitlement, "free_features", StringComparison.OrdinalIgnoreCase));
}

internal sealed class TestAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public const string SchemeName = "FreeUserTest";
    public const string UserHeader = "X-Test-User";
    private static readonly Guid UserId = Guid.Parse("11111111-1111-1111-1111-111111111111");

    public TestAuthenticationHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder
    )
        : base(options, logger, encoder) { }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.ContainsKey(UserHeader))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, UserId.ToString()),
            new Claim(ClaimTypes.Role, "User"),
        };
        var principal = new ClaimsPrincipal(new ClaimsIdentity(claims, SchemeName));
        var ticket = new AuthenticationTicket(principal, SchemeName);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
