using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface ILuckyWheelService
    {
        Task<IEnumerable<FoodResponse>> GetWheelFoodsAsync(Guid userId);
        Task ApplyWheelSelectionAsync(Guid userId, Guid foodId, string mealType);
    }
}
