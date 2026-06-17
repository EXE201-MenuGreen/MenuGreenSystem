using System;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class BudgetRequestService : IBudgetRequestService
    {
        private readonly IUnitOfWork _unitOfWork;

        public BudgetRequestService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<BudgetRequestResponse?> GetActiveBudgetAsync(Guid userId)
        {
            var budgetRequests = await _unitOfWork.BudgetRequests.FindAsync(x => x.UserId == userId);
            var active = budgetRequests.OrderByDescending(x => x.CreatedAt).FirstOrDefault();
            if (active == null) return null;

            return MapToResponse(active);
        }

        public async Task<BudgetRequestResponse> CreateAsync(Guid userId, BudgetRequestUpsertRequest request)
        {
            var entity = new BudgetRequest
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                BudgetVnd = request.BudgetVnd,
                TimeLimitMin = request.TimeLimitMin,
                CreatedAt = DateTimeOffset.UtcNow
            };

            await _unitOfWork.BudgetRequests.AddAsync(entity);
            await _unitOfWork.CompleteAsync();

            return MapToResponse(entity);
        }

        public async Task<BudgetRequestResponse> UpdateAsync(Guid userId, Guid id, BudgetRequestUpsertRequest request)
        {
            var entity = await _unitOfWork.BudgetRequests.GetByIdAsync(id);
            if (entity == null || entity.UserId != userId)
            {
                throw new Exception("Budget request not found.");
            }

            entity.BudgetVnd = request.BudgetVnd;
            entity.TimeLimitMin = request.TimeLimitMin;

            _unitOfWork.BudgetRequests.Update(entity);
            await _unitOfWork.CompleteAsync();

            return MapToResponse(entity);
        }

        public async Task DeleteAsync(Guid userId, Guid id)
        {
            var entity = await _unitOfWork.BudgetRequests.GetByIdAsync(id);
            if (entity == null || entity.UserId != userId)
            {
                throw new Exception("Budget request not found.");
            }

            _unitOfWork.BudgetRequests.Remove(entity);
            await _unitOfWork.CompleteAsync();
        }

        private static BudgetRequestResponse MapToResponse(BudgetRequest budget)
        {
            return new BudgetRequestResponse
            {
                Id = budget.Id,
                UserId = budget.UserId,
                BudgetVnd = budget.BudgetVnd ?? 0,
                TimeLimitMin = budget.TimeLimitMin ?? 0,
                Result = budget.Result,
                CreatedAt = budget.CreatedAt ?? DateTimeOffset.UtcNow
            };
        }
    }
}
