using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IUserMetricsService
    {
        Task<UserDashboardMetricsResponse> GetSummaryAsync();
    }
}
