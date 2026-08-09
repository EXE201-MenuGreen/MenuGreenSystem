using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IRevenueMetricsService
    {
        Task<RevenueDashboardMetricsResponse> GetSummaryAsync();
        Task<RevenueTimeSeriesResponse> GetTimeSeriesAsync(DateTimeOffset from, DateTimeOffset to);
        Task<RevenueByPlanResponse> GetByPlanAsync(DateTimeOffset from, DateTimeOffset to);
    }
}
