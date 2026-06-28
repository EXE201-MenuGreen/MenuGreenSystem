using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IMealTemplateService
    {
        Task<IEnumerable<MealTemplateResponse>> GetAllAsync(Guid userId);
        Task<MealTemplateResponse> GetByIdAsync(Guid userId, Guid id);
        Task<MealTemplateResponse> CreateAsync(Guid userId, MealTemplateUpsertRequest request);
        Task<MealTemplateResponse> UpdateAsync(Guid userId, Guid id, MealTemplateUpsertRequest request);
        Task DeleteAsync(Guid userId, Guid id);
        Task<MealTemplateLogResponse> LogAsync(Guid userId, Guid id, MealTemplateLogRequest request);
        Task<MealTemplateResponse> DuplicateAsync(Guid userId, Guid id);
        Task<int> GetUsageAsync(Guid userId, Guid id);
        Task<MealTemplateResponse> CreateFromLogAsync(Guid userId, Guid mealLogId, string title);
    }
}
