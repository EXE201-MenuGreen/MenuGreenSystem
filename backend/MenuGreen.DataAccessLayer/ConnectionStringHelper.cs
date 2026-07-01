using System;
using Microsoft.Extensions.Configuration;

namespace MenuGreen.DataAccessLayer
{
    internal static class ConnectionStringHelper
    {
        public static string ResolvePostgresConnectionString(IConfiguration configuration)
        {
            var configured = configuration.GetConnectionString("DefaultConnection")
                ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
                ?? Environment.GetEnvironmentVariable("DATABASE_URL");

            if (IsNpgsqlKeyValueConnectionString(configured))
            {
                return configured!;
            }

            var databaseUrl = configuration["DATABASE_URL"]
                ?? Environment.GetEnvironmentVariable("DATABASE_URL");

            if (!string.IsNullOrWhiteSpace(databaseUrl))
            {
                return ConvertPostgresUriToNpgsql(databaseUrl);
            }

            if (!string.IsNullOrWhiteSpace(configured))
            {
                return ConvertPostgresUriToNpgsql(configured);
            }

            throw new InvalidOperationException(
                "PostgreSQL connection string is missing. Set ConnectionStrings__DefaultConnection (Npgsql format) " +
                "or DATABASE_URL on Render.");
        }

        private static bool IsNpgsqlKeyValueConnectionString(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return false;
            }

            var trimmed = value.TrimStart();
            return trimmed.StartsWith("Host=", StringComparison.OrdinalIgnoreCase)
                || trimmed.StartsWith("Server=", StringComparison.OrdinalIgnoreCase);
        }

        private static string ConvertPostgresUriToNpgsql(string databaseUrl)
        {
            var uri = new Uri(databaseUrl.Trim());
            var userInfo = uri.UserInfo.Split(':', 2);
            var username = Uri.UnescapeDataString(userInfo[0]);
            var password = userInfo.Length > 1 ? Uri.UnescapeDataString(userInfo[1]) : string.Empty;
            var database = uri.AbsolutePath.TrimStart('/');
            var port = uri.Port > 0 ? uri.Port : 5432;

            return $"Host={uri.Host};Port={port};Database={database};Username={username};Password={password};" +
                   "SSL Mode=Require;Trust Server Certificate=true";
        }
    }
}
