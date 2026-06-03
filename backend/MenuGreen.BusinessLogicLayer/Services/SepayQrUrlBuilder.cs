using System;
using Microsoft.Extensions.Configuration;

namespace MenuGreen.BusinessLogicLayer.Services
{
    /// <summary>
    /// Builds dynamic VietQR image URLs via SePay (https://developer.sepay.vn).
    /// </summary>
    public class SepayQrUrlBuilder
    {
        private const string DefaultQrBaseUrl = "https://qr.sepay.vn/img";

        private readonly IConfiguration _configuration;

        public SepayQrUrlBuilder(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public SepayQrBuildResult Build(int amountVnd, string providerOrderCode)
        {
            if (amountVnd <= 0)
            {
                throw new ArgumentException("Amount must be greater than zero.");
            }

            if (string.IsNullOrWhiteSpace(providerOrderCode))
            {
                throw new ArgumentException("Provider order code is required.");
            }

            var accountNumber = _configuration["SePay:BankAccount:AccountNumber"]?.Trim();
            var bankName = _configuration["SePay:BankAccount:BankName"]?.Trim();
            var accountHolderName = _configuration["SePay:BankAccount:AccountHolderName"]?.Trim() ?? string.Empty;

            if (string.IsNullOrWhiteSpace(accountNumber) || string.IsNullOrWhiteSpace(bankName))
            {
                throw new InvalidOperationException(
                    "SePay bank account is not configured. Set SePay:BankAccount:AccountNumber and SePay:BankAccount:BankName in appsettings (values from your SePay dashboard).");
            }

            var transferMemo = BuildTransferMemo(providerOrderCode);
            var qrBaseUrl = _configuration["SePay:QrImageBaseUrl"]?.Trim();
            if (string.IsNullOrWhiteSpace(qrBaseUrl))
            {
                qrBaseUrl = DefaultQrBaseUrl;
            }

            var qrImageUrl =
                $"{qrBaseUrl.TrimEnd('/')}?acc={Uri.EscapeDataString(accountNumber)}" +
                $"&bank={Uri.EscapeDataString(bankName)}" +
                $"&amount={amountVnd}" +
                $"&des={Uri.EscapeDataString(transferMemo)}";

            return new SepayQrBuildResult
            {
                QrImageUrl = qrImageUrl,
                TransferMemo = transferMemo,
                Receiver = new SepayQrReceiver
                {
                    BankName = bankName,
                    AccountNumber = accountNumber,
                    AccountHolderName = accountHolderName
                }
            };
        }

        private string BuildTransferMemo(string providerOrderCode)
        {
            var prefix = _configuration["SePay:BankAccount:TransferDescriptionPrefix"]?.Trim();
            if (string.IsNullOrWhiteSpace(prefix))
            {
                return providerOrderCode;
            }

            return $"{prefix} {providerOrderCode}";
        }
    }

    public class SepayQrBuildResult
    {
        public string QrImageUrl { get; set; } = string.Empty;
        public string TransferMemo { get; set; } = string.Empty;
        public SepayQrReceiver Receiver { get; set; } = new();
    }

    public class SepayQrReceiver
    {
        public string BankName { get; set; } = string.Empty;
        public string AccountNumber { get; set; } = string.Empty;
        public string AccountHolderName { get; set; } = string.Empty;
    }
}
