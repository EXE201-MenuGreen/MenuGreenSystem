using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class FoodRankingService : IFoodRankingService
    {
        private readonly IUnitOfWork _unitOfWork;

        public FoodRankingService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<List<DashboardFoodRankingItemResponse>> GetTopFoodsAsync(int topCount = 10)
        {
            var mealLogs = await _unitOfWork.MealLogs.GetAllAsync();
            var foods = await _unitOfWork.Foods.GetAllAsync();

            var ranking = mealLogs
                .Where(x => x.FoodId.HasValue)
                .GroupBy(x => x.FoodId!.Value)
                .Select(group => new
                {
                    FoodId = group.Key,
                    UseCount = group.Count()
                })
                .Join(foods, x => x.FoodId, f => f.Id, (x, f) => new DashboardFoodRankingItemResponse
                {
                    FoodId = f.Id,
                    FoodName = f.NameVi,
                    UseCount = x.UseCount,
                    CaloriesKcal = f.CaloriesKcal ?? 0,
                    EstimatedPriceVnd = f.EstimatedPriceVnd ?? 0
                })
                .OrderByDescending(x => x.UseCount)
                .ThenByDescending(x => x.CaloriesKcal)
                .Take(topCount)
                .ToList();

            return ranking;
        }
    }
}
