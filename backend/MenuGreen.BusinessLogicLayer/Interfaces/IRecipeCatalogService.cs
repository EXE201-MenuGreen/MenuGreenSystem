using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IRecipeCatalogService
    {
        Task<RecipeResponse> CreateAsync(RecipeUpsertRequest request);
        Task<RecipeResponse> UpdateAsync(Guid id, RecipeUpsertRequest request);
        Task DeleteAsync(Guid id);
        Task<RecipeResponse> GetByIdAsync(Guid id);
    }
}
