using System;
using System.Collections.Generic;
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
        Task<FoodResponse> GetByIdAsync(Guid id, Guid? userId = null, string? allergyMode = null);
        Task<FoodSearchResponse> SearchAsync(
            string? keyword,
            decimal? minCalories,
            decimal? maxCalories,
            string? proteinLevel,
            int? maxPriceVnd,
            int? maxPrepTimeMin,
            string? category,
            Guid? userId = null,
            string? allergyMode = null,
            string? region = null,
            bool? localOnly = null,
            string? mealContext = null,
            string? sort = null,
            int? page = null,
            int? pageSize = null);
        Task<IReadOnlyList<RecipeResponse>> GetRecipesAsync(Guid foodId);
        Task<IReadOnlyList<FavoriteFoodResponse>> GetFavoritesAsync(Guid userId);
        Task<FavoriteFoodResponse> FavoriteAsync(Guid userId, Guid foodId);
        Task UnfavoriteAsync(Guid userId, Guid foodId);
    }
}
