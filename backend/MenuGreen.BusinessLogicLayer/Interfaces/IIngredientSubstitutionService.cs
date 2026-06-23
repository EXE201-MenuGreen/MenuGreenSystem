using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IIngredientSubstitutionService
    {
        // A. Engine gợi ý thay thế
        Task<IEnumerable<IngredientSubstituteDetailResponse>> GetSubstitutesAsync(Guid userId, Guid ingredientId, string reason, int? maxPrice, bool macroMatch);
        Task<IEnumerable<IngredientSubstituteDto>> GetBatchSubstitutesAsync(Guid userId, BatchSubstitutionRequest request);
        Task<RecipeIngredientSubstituteResponse> GetRecipeIngredientSubstitutesAsync(Guid userId, Guid recipeId, Guid ingredientId);
        Task<IEnumerable<RecipeResponse>> GetSafeRecipeAlternativesAsync(Guid userId, Guid recipeId);

        // B. Áp dụng thay thế
        Task ApplyMealPlanSubstitutionAsync(Guid userId, Guid planId, Guid itemId, IngredientSubstitutionApplyRequest request);
        Task ApplyMealLogSubstitutionAsync(Guid userId, Guid mealLogId, IngredientSubstitutionApplyRequest request);

        // C. Cấu hình cá nhân
        Task<IEnumerable<UserSubstitutePreferenceResponse>> GetPersonalPreferencesAsync(Guid userId);
        Task<UserSubstitutePreferenceResponse> CreatePersonalPreferenceAsync(Guid userId, UserSubstitutePreferenceUpsertRequest request);
        Task DeletePersonalPreferenceAsync(Guid userId, Guid id);
    }
}
