using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IAllergenMatchingService
    {
        Task<HashSet<string>> GetUserAllergenKeysAsync(Guid userId);
        Task<Dictionary<Guid, HashSet<string>>> GetFoodAllergenKeysAsync(IEnumerable<Guid> foodIds);
        Task<HashSet<string>> GetFoodAllergenKeysAsync(Guid foodId);
        Task SetFoodAllergenKeysAsync(Guid foodId, IEnumerable<string> allergenKeys);
        Task<IReadOnlyList<string>> GetFoodAllergenKeysListAsync(Guid foodId);
        Task<AllergenRiskResult> EvaluateFoodRiskAsync(Guid foodId, Guid? userId);
        Task<AllergenRiskResult> EvaluateRecipeRiskAsync(Guid? foodId, IEnumerable<string> ingredientNamesVi, Guid? userId);
    }
}
