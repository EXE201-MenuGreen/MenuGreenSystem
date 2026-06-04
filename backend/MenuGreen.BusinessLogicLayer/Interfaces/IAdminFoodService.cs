using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IAdminFoodService
    {
        Task<FoodResponse> CreateAsync(FoodUpsertRequest request);
        Task<FoodResponse> UpdateAsync(Guid id, FoodUpsertRequest request);
        Task DeleteAsync(Guid id);
        Task<FoodResponse> GetByIdAsync(Guid id);
        Task<FoodAllergenTagsResponse> GetAllergenTagsAsync(Guid id);
        Task<FoodAllergenTagsResponse> SetAllergenTagsAsync(Guid id, FoodAllergenTagsUpsertRequest request);
    }
}
