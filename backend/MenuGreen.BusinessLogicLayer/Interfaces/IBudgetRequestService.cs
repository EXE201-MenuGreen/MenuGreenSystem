using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IBudgetRequestService
    {
        Task<BudgetRequestResponse?> GetActiveBudgetAsync(Guid userId);
        Task<BudgetRequestResponse> CreateAsync(Guid userId, BudgetRequestUpsertRequest request);
        Task<BudgetRequestResponse> UpdateAsync(Guid userId, Guid id, BudgetRequestUpsertRequest request);
        Task DeleteAsync(Guid userId, Guid id);
    }
}
