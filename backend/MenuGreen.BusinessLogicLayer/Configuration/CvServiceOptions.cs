using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace MenuGreen.BusinessLogicLayer.Configuration;

public class CvServiceOptions
{
    public const string SectionName = "CvService";

    public string BaseUrl { get; set; } = string.Empty;
    public string ApiVersion { get; set; } = "v1";
    public string ApiSecretKey { get; set; } = string.Empty;
    public int PollTimeoutSeconds { get; set; } = 90;
    public int PollIntervalSeconds { get; set; } = 3;
}

public static class CvServiceOptionsExtensions
{
    public static IServiceCollection AddCvServiceOptions(
        this IServiceCollection services,
        IConfiguration configuration
    )
    {
        services.Configure<CvServiceOptions>(options =>
        {
            var section = configuration.GetSection(CvServiceOptions.SectionName);
            options.BaseUrl = section[nameof(CvServiceOptions.BaseUrl)] ?? string.Empty;
            options.ApiVersion = section[nameof(CvServiceOptions.ApiVersion)] ?? "v1";
            options.ApiSecretKey = section[nameof(CvServiceOptions.ApiSecretKey)] ?? string.Empty;

            if (int.TryParse(section[nameof(CvServiceOptions.PollTimeoutSeconds)], out var timeout))
            {
                options.PollTimeoutSeconds = timeout;
            }

            if (
                int.TryParse(
                    section[nameof(CvServiceOptions.PollIntervalSeconds)],
                    out var interval
                )
            )
            {
                options.PollIntervalSeconds = interval;
            }
        });

        return services;
    }
}
