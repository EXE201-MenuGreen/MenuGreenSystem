using System.ComponentModel.DataAnnotations;
using System.Globalization;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace MenuGreen.API.Controllers;

[ApiController]
[Route("api/location")]
[Authorize(Policy = "UserOnly")]
[EnableRateLimiting("AiPolicy")]
public sealed class LocationController : ControllerBase
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<LocationController> _logger;

    public LocationController(
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        ILogger<LocationController> logger
    )
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _logger = logger;
    }

    [HttpGet("reverse-geocode")]
    public async Task<IActionResult> ReverseGeocode(
        [FromQuery, Range(-90d, 90d)] double latitude,
        [FromQuery, Range(-180d, 180d)] double longitude,
        CancellationToken cancellationToken
    )
    {
        var apiKey =
            _configuration["Goong:ApiKey"]
            ?? Environment.GetEnvironmentVariable("GOONG_API_KEY");
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            _logger.LogError("Goong reverse geocoding is not configured.");
            return Problem(
                statusCode: StatusCodes.Status503ServiceUnavailable,
                title: "Location service is unavailable."
            );
        }

        var latLng = string.Create(
            CultureInfo.InvariantCulture,
            $"{latitude:F7},{longitude:F7}"
        );
        var requestUri =
            $"Geocode?latlng={Uri.EscapeDataString(latLng)}&api_key={Uri.EscapeDataString(apiKey)}";

        try
        {
            var client = _httpClientFactory.CreateClient("Goong");
            using var response = await client.GetAsync(requestUri, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Goong reverse geocoding returned status {StatusCode}.",
                    (int)response.StatusCode
                );
                return Problem(
                    statusCode: StatusCodes.Status502BadGateway,
                    title: "Location provider rejected the request."
                );
            }

            await using var responseStream = await response.Content.ReadAsStreamAsync(
                cancellationToken
            );
            using var document = await JsonDocument.ParseAsync(
                responseStream,
                new JsonDocumentOptions
                {
                    AllowTrailingCommas = false,
                    CommentHandling = JsonCommentHandling.Disallow,
                    MaxDepth = 32,
                },
                cancellationToken
            );

            var province = FindProvince(document.RootElement);
            return Ok(new { province });
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Goong reverse geocoding failed.");
            return Problem(
                statusCode: StatusCodes.Status502BadGateway,
                title: "Location service failed."
            );
        }
    }

    private static string? FindProvince(JsonElement root)
    {
        if (
            !root.TryGetProperty("results", out var results)
            || results.ValueKind != JsonValueKind.Array
            || results.GetArrayLength() == 0
        )
        {
            return null;
        }

        var first = results[0];
        if (
            first.TryGetProperty("address_components", out var components)
            && components.ValueKind == JsonValueKind.Array
        )
        {
            foreach (var component in components.EnumerateArray())
            {
                if (
                    component.TryGetProperty("types", out var types)
                    && types.ValueKind == JsonValueKind.Array
                    && types
                        .EnumerateArray()
                        .Any(type =>
                            string.Equals(
                                type.GetString(),
                                "administrative_area_level_1",
                                StringComparison.Ordinal
                            )
                        )
                    && component.TryGetProperty("long_name", out var longName)
                )
                {
                    return longName.GetString();
                }
            }
        }

        if (
            first.TryGetProperty("formatted_address", out var formattedAddress)
            && formattedAddress.ValueKind == JsonValueKind.String
        )
        {
            var parts = formattedAddress
                .GetString()
                ?.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            if (parts is { Length: >= 2 })
            {
                return parts[^2];
            }
        }

        return null;
    }
}
