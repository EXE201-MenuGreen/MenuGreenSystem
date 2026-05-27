using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface ICatalogService
    {
        Task<FoodResponse> CreateFoodAsync(FoodUpsertRequest request);
        Task<FoodResponse> UpdateFoodAsync(Guid id, FoodUpsertRequest request);
        Task DeleteFoodAsync(Guid id);
        Task<FoodResponse> GetFoodByIdAsync(Guid id);
        Task<FoodSearchResponse> SearchFoodsAsync(string? keyword, decimal? minCalories, decimal? maxCalories, string? proteinLevel, int? maxPriceVnd, int? maxPrepTimeMin, string? category);

        Task<IngredientResponse> CreateIngredientAsync(IngredientUpsertRequest request);
        Task<IngredientResponse> UpdateIngredientAsync(Guid id, IngredientUpsertRequest request);
        Task DeleteIngredientAsync(Guid id);
        Task<IngredientResponse> GetIngredientByIdAsync(Guid id);

        Task<RecipeResponse> CreateRecipeAsync(RecipeUpsertRequest request);
        Task<RecipeResponse> UpdateRecipeAsync(Guid id, RecipeUpsertRequest request);
        Task DeleteRecipeAsync(Guid id);
        Task<RecipeResponse> GetRecipeByIdAsync(Guid id);
    }
}
