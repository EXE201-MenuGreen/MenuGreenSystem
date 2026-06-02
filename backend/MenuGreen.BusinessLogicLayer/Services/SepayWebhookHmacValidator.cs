using System;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Configuration;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class SepayWebhookHmacValidator
    {
        private readonly IConfiguration _configuration;

        public SepayWebhookHmacValidator(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public void Validate(string rawBody, string? signature, string? timestamp)
        {
            if (string.IsNullOrWhiteSpace(rawBody))
            {
                throw new ArgumentException("Empty webhook body.");
            }

            var secret = _configuration["SePay:WebhookSecret"];
            if (string.IsNullOrWhiteSpace(secret))
            {
                throw new InvalidOperationException("SePay:WebhookSecret is not configured.");
            }

            if (string.IsNullOrWhiteSpace(signature))
            {
                throw new UnauthorizedAccessException("Missing X-SePay-Signature header.");
            }

            if (!long.TryParse(timestamp, out var unixTimestamp))
            {
                throw new UnauthorizedAccessException("Missing or invalid X-SePay-Timestamp header.");
            }

            var toleranceSeconds = ReadToleranceSeconds();
            var requestTime = DateTimeOffset.FromUnixTimeSeconds(unixTimestamp);
            if (Math.Abs((DateTimeOffset.UtcNow - requestTime).TotalSeconds) > toleranceSeconds)
            {
                throw new UnauthorizedAccessException("SePay webhook request expired.");
            }

            var expectedSignature = ComputeSignature(secret, timestamp!, rawBody);
            var providedBytes = Encoding.UTF8.GetBytes(signature.Trim());
            var expectedBytes = Encoding.UTF8.GetBytes(expectedSignature);

            if (providedBytes.Length != expectedBytes.Length ||
                !CryptographicOperations.FixedTimeEquals(providedBytes, expectedBytes))
            {
                throw new UnauthorizedAccessException("Invalid SePay webhook signature.");
            }
        }

        public static string ComputeSignature(string secret, string timestamp, string rawBody)
        {
            var signingString = $"{timestamp}.{rawBody}";
            using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
            var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(signingString));
            return $"sha256={Convert.ToHexString(hash).ToLowerInvariant()}";
        }

        private int ReadToleranceSeconds()
        {
            var value = _configuration["SePay:WebhookTimestampToleranceSeconds"];
            if (int.TryParse(value, out var seconds) && seconds >= 60 && seconds <= 900)
            {
                return seconds;
            }

            return 300;
        }
    }
}
