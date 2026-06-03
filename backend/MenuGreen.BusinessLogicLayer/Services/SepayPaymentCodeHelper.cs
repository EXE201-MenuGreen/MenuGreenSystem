using System;
using System.Security.Cryptography;
using System.Text.RegularExpressions;

namespace MenuGreen.BusinessLogicLayer.Services
{
    /// <summary>
    /// SePay payment codes: prefix (e.g. DH) + 3–10 alphanumeric suffix (see SePay company configuration).
    /// </summary>
    public static class SepayPaymentCodeHelper
    {
        public const int DefaultSuffixMinLength = 3;
        public const int DefaultSuffixMaxLength = 10;
        public const int DefaultSuffixLength = 8;

        private const string Alphanumeric = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

        public static string Generate(string prefix, int suffixLength)
        {
            var normalizedPrefix = NormalizePrefix(prefix);
            ValidateSuffixLength(suffixLength);

            Span<char> suffix = stackalloc char[suffixLength];
            for (var i = 0; i < suffixLength; i++)
            {
                suffix[i] = Alphanumeric[RandomNumberGenerator.GetInt32(Alphanumeric.Length)];
            }

            return normalizedPrefix + new string(suffix);
        }

        public static string? TryExtract(
            string? text,
            string prefix,
            int minSuffixLength = DefaultSuffixMinLength,
            int maxSuffixLength = DefaultSuffixMaxLength)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return null;
            }

            var normalizedPrefix = NormalizePrefix(prefix);
            ValidateSuffixRange(minSuffixLength, maxSuffixLength);

            var normalizedText = text.Trim().ToUpperInvariant();
            var pattern =
                $@"{Regex.Escape(normalizedPrefix)}[A-Z0-9]{{{minSuffixLength},{maxSuffixLength}}}";
            var match = Regex.Match(normalizedText, pattern);
            if (match.Success)
            {
                return match.Value;
            }

            return TryExtractLegacy(normalizedText, normalizedPrefix);
        }

        public static string NormalizeForMatch(string value) =>
            value.Trim().ToUpperInvariant().Replace("-", string.Empty, StringComparison.Ordinal);

        public static bool CodesMatch(string expected, string actual) =>
            string.Equals(NormalizeForMatch(expected), NormalizeForMatch(actual), StringComparison.Ordinal);

        public static bool ContainsCode(string transferContent, string providerOrderCode)
        {
            if (string.IsNullOrWhiteSpace(transferContent))
            {
                return false;
            }

            var normalizedContent = NormalizeForMatch(transferContent);
            var normalizedCode = NormalizeForMatch(providerOrderCode);
            return normalizedContent.Contains(normalizedCode, StringComparison.Ordinal);
        }

        public static int ClampSuffixLength(int value)
        {
            if (value < DefaultSuffixMinLength)
            {
                return DefaultSuffixMinLength;
            }

            if (value > DefaultSuffixMaxLength)
            {
                return DefaultSuffixMaxLength;
            }

            return value;
        }

        private static string? TryExtractLegacy(string normalizedText, string normalizedPrefix)
        {
            var legacyPattern = $@"{Regex.Escape(normalizedPrefix)}-[A-Z0-9]+-[A-Z0-9]+";
            var match = Regex.Match(normalizedText, legacyPattern);
            return match.Success ? match.Value : null;
        }

        private static string NormalizePrefix(string prefix)
        {
            if (string.IsNullOrWhiteSpace(prefix))
            {
                throw new ArgumentException("Payment code prefix is required.", nameof(prefix));
            }

            return prefix.Trim().ToUpperInvariant();
        }

        private static void ValidateSuffixLength(int suffixLength)
        {
            if (suffixLength < DefaultSuffixMinLength || suffixLength > DefaultSuffixMaxLength)
            {
                throw new ArgumentOutOfRangeException(
                    nameof(suffixLength),
                    $"SePay payment code suffix length must be between {DefaultSuffixMinLength} and {DefaultSuffixMaxLength}.");
            }
        }

        private static void ValidateSuffixRange(int minSuffixLength, int maxSuffixLength)
        {
            if (minSuffixLength < DefaultSuffixMinLength ||
                maxSuffixLength > DefaultSuffixMaxLength ||
                minSuffixLength > maxSuffixLength)
            {
                throw new ArgumentOutOfRangeException(
                    nameof(minSuffixLength),
                    $"SePay payment code suffix range must stay within {DefaultSuffixMinLength}-{DefaultSuffixMaxLength}.");
            }
        }
    }
}
