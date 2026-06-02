using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface ISepayPaymentService
    {
        Task<SepayOrderResponse> CreateOrderAsync(Guid userId, CreateSepayOrderRequest request);
        Task<SepayOrderResponse> CreateRenewOrderAsync(Guid userId, CreateRenewSepayOrderRequest request);
        Task<SepayOrderResponse> GetOrderStatusAsync(Guid userId, Guid paymentId);
        Task<SepayWebhookResultResponse> ProcessWebhookAsync(string rawBody, string? signature, string? timestamp);
    }
}
