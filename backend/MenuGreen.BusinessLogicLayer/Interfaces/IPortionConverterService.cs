using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IPortionConverterService
    {
        Task<IEnumerable<PortionUnitResponse>> GetDefaultUnitsAsync();
        Task<IEnumerable<PortionUnitResponse>> GetUnitsByFoodAsync(Guid foodId);
        Task<PortionConvertResponse> ConvertPortionAsync(PortionConvertRequest request, Guid? userId = null);
        Task<IEnumerable<CustomUserPortionResponse>> GetCustomUnitsAsync(Guid userId);
        Task<CustomUserPortionResponse> CreateCustomUnitAsync(Guid userId, CustomUserPortionUpsertRequest request);
        Task<CustomUserPortionResponse> UpdateCustomUnitAsync(Guid userId, Guid id, CustomUserPortionUpsertRequest request);
        Task<bool> DeleteCustomUnitAsync(Guid userId, Guid id);
    }
}
