using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IRecipeService
    {
        Task<RecipeResponse> CreateAsync(RecipeUpsertRequest request);
        Task<RecipeResponse> UpdateAsync(Guid id, RecipeUpsertRequest request);
        Task DeleteAsync(Guid id);
        Task<RecipeResponse> GetByIdAsync(Guid id);
        Task<RecipeSearchResponse> SearchAsync(string? keyword, string? mealType, string? difficulty, bool? isActive);
        Task<IReadOnlyList<RecipeIngredientResponse>> GetIngredientsAsync(Guid recipeId);
        Task<RecipeNutritionResponse> GetNutritionAsync(Guid recipeId);
        Task<IReadOnlyList<RecipeResponse>> GetRelatedAsync(Guid recipeId);
    }
}
