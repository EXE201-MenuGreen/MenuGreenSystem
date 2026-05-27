using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IFoodService
    {
        Task<FoodResponse> CreateAsync(FoodUpsertRequest request);
        Task<FoodResponse> UpdateAsync(Guid id, FoodUpsertRequest request);
        Task DeleteAsync(Guid id);
        Task<FoodResponse> GetByIdAsync(Guid id);
        Task<FoodSearchResponse> SearchAsync(string? keyword, decimal? minCalories, decimal? maxCalories, string? proteinLevel, int? maxPriceVnd, int? maxPrepTimeMin, string? category);
    }
}
