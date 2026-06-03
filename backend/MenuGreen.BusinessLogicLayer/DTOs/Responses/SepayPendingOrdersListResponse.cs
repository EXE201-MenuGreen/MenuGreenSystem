using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class SepayPendingOrdersListResponse
    {
        public IReadOnlyList<SepayPendingOrderResponse> Items { get; set; } = new List<SepayPendingOrderResponse>();
    }
}
