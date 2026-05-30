using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IDashboardService
    {
        Task<DashboardMetricsResponse> GetMetricsAsync(int topCount = 10);
    }
}
