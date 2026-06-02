using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IIngredientService
    {
        Task<IngredientResponse> CreateAsync(IngredientUpsertRequest request);
        Task<IngredientResponse> UpdateAsync(Guid id, IngredientUpsertRequest request);
        Task DeleteAsync(Guid id);
        Task<IngredientResponse> GetByIdAsync(Guid id);
        Task<IngredientSearchResponse> SearchAsync(string? keyword, string? category, bool? isActive);
        Task<IReadOnlyList<IngredientRecipeResponse>> GetRecipesAsync(Guid ingredientId);
        Task<IReadOnlyList<IngredientCatalogResponse>> GetCatalogAsync();
    }
}
