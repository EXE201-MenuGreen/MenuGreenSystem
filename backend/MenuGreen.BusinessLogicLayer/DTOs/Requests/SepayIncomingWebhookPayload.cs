using System;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    /// <summary>
    /// Payload sent by SePay when a bank transaction is received.
    /// </summary>
    public class SepayIncomingWebhookPayload
    {
        [JsonPropertyName("id")]
        [Range(1, long.MaxValue)]
        public long Id { get; set; }

        [JsonPropertyName("gateway")]
        [StringLength(64)]
        public string? Gateway { get; set; }

        /// <summary>SePay format: yyyy-MM-dd HH:mm:ss (Vietnam local time).</summary>
        [JsonPropertyName("transactionDate")]
        [StringLength(32)]
        public string? TransactionDate { get; set; }

        [JsonPropertyName("accountNumber")]
        [StringLength(64)]
        public string? AccountNumber { get; set; }

        [JsonPropertyName("subAccount")]
        [StringLength(64)]
        public string? SubAccount { get; set; }

        [JsonPropertyName("code")]
        [StringLength(128)]
        public string? Code { get; set; }

        [JsonPropertyName("content")]
        [StringLength(1_000)]
        public string? Content { get; set; }

        [JsonPropertyName("transferType")]
        [Required]
        [RegularExpression("^(?i:in|out)$")]
        public string? TransferType { get; set; }

        [JsonPropertyName("description")]
        [StringLength(2_000)]
        public string? Description { get; set; }

        [JsonPropertyName("transferAmount")]
        [Range(1, int.MaxValue)]
        public int TransferAmount { get; set; }

        [JsonPropertyName("accumulated")]
        public long? Accumulated { get; set; }

        [JsonPropertyName("referenceCode")]
        [StringLength(128)]
        public string? ReferenceCode { get; set; }
    }
}
