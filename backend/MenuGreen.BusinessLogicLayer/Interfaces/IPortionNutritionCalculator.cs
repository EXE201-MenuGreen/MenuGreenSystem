using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IPortionNutritionCalculator
    {
        Task<PortionNutritionResponse> CalculateRecipeAsync(
            Guid recipeId,
            IReadOnlyCollection<MealPlanIngredientPortionRequest>? portions = null);

        Task<PortionNutritionResponse> CalculateFoodAsync(Guid foodId, decimal? quantityG = null);

        PortionNutritionResponse Scale(PortionNutritionResponse source, decimal ratio);
        PortionNutritionResponse? Deserialize(string? json);
        string Serialize(PortionNutritionResponse value);
    }
}
