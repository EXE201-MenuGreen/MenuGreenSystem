using System;
using System.Threading;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface ISepayPaymentStatusCache
    {
        Task<SepayOrderResponse?> TryGetAsync(Guid userId, Guid paymentId, CancellationToken cancellationToken = default);

        Task SetAsync(Guid userId, Guid paymentId, SepayOrderResponse response, CancellationToken cancellationToken = default);

        Task InvalidateAsync(Guid userId, Guid paymentId, CancellationToken cancellationToken = default);
    }
}
