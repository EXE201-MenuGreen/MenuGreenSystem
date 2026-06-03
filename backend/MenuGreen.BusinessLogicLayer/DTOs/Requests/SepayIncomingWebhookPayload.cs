using System;
using System.Text.Json.Serialization;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    /// <summary>
    /// Payload sent by SePay when a bank transaction is received.
    /// </summary>
    public class SepayIncomingWebhookPayload
    {
        [JsonPropertyName("id")]
        public long Id { get; set; }

        [JsonPropertyName("gateway")]
        public string? Gateway { get; set; }

        [JsonPropertyName("transactionDate")]
        public DateTime? TransactionDate { get; set; }

        [JsonPropertyName("accountNumber")]
        public string? AccountNumber { get; set; }

        [JsonPropertyName("subAccount")]
        public string? SubAccount { get; set; }

        [JsonPropertyName("code")]
        public string? Code { get; set; }

        [JsonPropertyName("content")]
        public string? Content { get; set; }

        [JsonPropertyName("transferType")]
        public string? TransferType { get; set; }

        [JsonPropertyName("description")]
        public string? Description { get; set; }

        [JsonPropertyName("transferAmount")]
        public int TransferAmount { get; set; }

        [JsonPropertyName("accumulated")]
        public long? Accumulated { get; set; }

        [JsonPropertyName("referenceCode")]
        public string? ReferenceCode { get; set; }
    }
}
