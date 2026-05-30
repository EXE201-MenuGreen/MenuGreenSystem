using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IFoodRankingService
    {
        Task<List<DashboardFoodRankingItemResponse>> GetTopFoodsAsync(int topCount = 10);
    }
}
