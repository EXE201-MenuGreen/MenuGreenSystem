using System;
using System.Linq;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.DataAccessLayer.Entities;
using Microsoft.Extensions.Configuration;

namespace MenuGreen.BusinessLogicLayer.Services
{
    /// <summary>
    /// Validates SePay webhook payload against a pending payment (amount, payment code, transfer memo, receiver account).
    /// </summary>
    public class SepayWebhookPaymentVerifier
    {
        private const string DefaultPaymentCodePrefix = "DH";

        private readonly IConfiguration _configuration;
        private readonly SepayQrUrlBuilder _qrUrlBuilder;

        public SepayWebhookPaymentVerifier(IConfiguration configuration, SepayQrUrlBuilder qrUrlBuilder)
        {
            _configuration = configuration;
            _qrUrlBuilder = qrUrlBuilder;
        }

        public void Verify(Payment payment, SepayIncomingWebhookPayload payload, string transferContent, int transferAmount)
        {
            if (payment.AmountVnd != transferAmount)
            {
                throw new Exception(
                    $"Transfer amount does not match payment order. Expected {payment.AmountVnd} VND, received {transferAmount} VND.");
            }

            var prefix = ReadPaymentCodePrefix();
            var minSuffix = ReadPaymentCodeSuffixMinLength();
            var maxSuffix = ReadPaymentCodeSuffixMaxLength();
            var resolvedCode = ResolvePaymentCode(payload, transferContent, prefix, minSuffix, maxSuffix);
            if (string.IsNullOrWhiteSpace(resolvedCode))
            {
                throw new Exception(
                    $"Transfer content does not contain a valid payment code (prefix '{prefix}', suffix {minSuffix}-{maxSuffix} alphanumeric).");
            }

            if (!SepayPaymentCodeHelper.CodesMatch(payment.ProviderOrderCode, resolvedCode))
            {
                throw new Exception(
                    $"Payment code mismatch. Expected '{payment.ProviderOrderCode}', received '{resolvedCode}'.");
            }

            var expectedQr = _qrUrlBuilder.Build(payment.AmountVnd, payment.ProviderOrderCode);
            if (!TransferContentMatchesExpected(transferContent, expectedQr.TransferMemo, payment.ProviderOrderCode))
            {
                throw new Exception(
                    $"Transfer content does not match order memo. Expected memo containing '{expectedQr.TransferMemo}'.");
            }

            VerifyReceiverAccount(payload.AccountNumber, expectedQr.Receiver.AccountNumber);
        }

        private void VerifyReceiverAccount(string? webhookAccountNumber, string configuredAccountNumber)
        {
            if (string.IsNullOrWhiteSpace(configuredAccountNumber))
            {
                return;
            }

            if (string.IsNullOrWhiteSpace(webhookAccountNumber))
            {
                return;
            }

            if (NormalizeAccount(webhookAccountNumber) != NormalizeAccount(configuredAccountNumber))
            {
                throw new Exception(
                    "Receiver bank account in webhook does not match configured SePay bank account.");
            }
        }

        private static bool TransferContentMatchesExpected(
            string transferContent,
            string expectedTransferMemo,
            string providerOrderCode)
        {
            if (!SepayPaymentCodeHelper.ContainsCode(transferContent, providerOrderCode))
            {
                return false;
            }

            if (string.IsNullOrWhiteSpace(expectedTransferMemo) ||
                string.Equals(expectedTransferMemo, providerOrderCode, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            return SepayPaymentCodeHelper.ContainsCode(transferContent, expectedTransferMemo);
        }

        private static string? ResolvePaymentCode(
            SepayIncomingWebhookPayload payload,
            string transferContent,
            string prefix,
            int minSuffixLength,
            int maxSuffixLength)
        {
            if (!string.IsNullOrWhiteSpace(payload.Code))
            {
                var fromCode = SepayPaymentCodeHelper.TryExtract(payload.Code, prefix, minSuffixLength, maxSuffixLength);
                if (!string.IsNullOrWhiteSpace(fromCode))
                {
                    return fromCode;
                }
            }

            return SepayPaymentCodeHelper.TryExtract(transferContent, prefix, minSuffixLength, maxSuffixLength);
        }

        private static string NormalizeAccount(string value) =>
            new string(value.Where(char.IsDigit).ToArray());

        private string ReadPaymentCodePrefix()
        {
            var prefix = _configuration["SePay:PaymentCodePrefix"]?.Trim();
            return string.IsNullOrWhiteSpace(prefix) ? DefaultPaymentCodePrefix : prefix.ToUpperInvariant();
        }

        private int ReadPaymentCodeSuffixMinLength()
        {
            var value = _configuration["SePay:PaymentCodeSuffixMinLength"];
            if (int.TryParse(value, out var length))
            {
                return SepayPaymentCodeHelper.ClampSuffixLength(length);
            }

            return SepayPaymentCodeHelper.DefaultSuffixMinLength;
        }

        private int ReadPaymentCodeSuffixMaxLength()
        {
            var value = _configuration["SePay:PaymentCodeSuffixMaxLength"];
            if (int.TryParse(value, out var length))
            {
                return SepayPaymentCodeHelper.ClampSuffixLength(length);
            }

            return SepayPaymentCodeHelper.DefaultSuffixMaxLength;
        }
    }
}
