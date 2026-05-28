using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class AllergyService : IAllergyService
    {
        private readonly IUnitOfWork _unitOfWork;

        public AllergyService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<IEnumerable<AllergyResponse>> GetAllAsync(Guid userId)
        {
            var allergies = await _unitOfWork.Allergies.FindAsync(allergy => allergy.UserId == userId);
            return allergies.Select(MapToResponse).ToList();
        }

        public async Task<AllergyResponse> CreateAsync(Guid userId, AllergyUpsertRequest request)
        {
            var allergy = new Allergy
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Name = request.Name,
                Notes = request.Notes,
                IsActive = request.IsActive ?? true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Allergies.AddAsync(allergy);
            await _unitOfWork.CompleteAsync();

            return MapToResponse(allergy);
        }

        public async Task<AllergyResponse> UpdateAsync(Guid userId, Guid allergyId, AllergyUpsertRequest request)
        {
            var allergy = await GetOwnedAllergyAsync(userId, allergyId);

            allergy.Name = request.Name;
            allergy.Notes = request.Notes;
            allergy.IsActive = request.IsActive ?? allergy.IsActive;
            allergy.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Allergies.Update(allergy);
            await _unitOfWork.CompleteAsync();

            return MapToResponse(allergy);
        }

        public async Task DeleteAsync(Guid userId, Guid allergyId)
        {
            var allergy = await GetOwnedAllergyAsync(userId, allergyId);
            _unitOfWork.Allergies.Remove(allergy);
            await _unitOfWork.CompleteAsync();
        }

        private async Task<Allergy> GetOwnedAllergyAsync(Guid userId, Guid allergyId)
        {
            var allergy = await _unitOfWork.Allergies.GetByIdAsync(allergyId);

            if (allergy == null)
            {
                throw new Exception("Allergy not found.");
            }

            if (allergy.UserId != userId)
            {
                throw new Exception("Forbidden.");
            }

            return allergy;
        }

        private static AllergyResponse MapToResponse(Allergy allergy)
        {
            return new AllergyResponse
            {
                Id = allergy.Id,
                Name = allergy.Name,
                Notes = allergy.Notes,
                IsActive = allergy.IsActive
            };
        }
    }
}
