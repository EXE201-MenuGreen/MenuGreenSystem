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
    public class UserAiProfileService : IUserAiProfileService
    {
        private readonly IUnitOfWork _unitOfWork;

        public UserAiProfileService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<UserAiProfileResponse> GetAsync(Guid userId)
        {
            var entity = await GetOrNullAsync(userId);
            return Map(entity, userId);
        }

        public async Task<UserAiProfileResponse> UpsertAsync(Guid userId, UpdateUserAiProfileRequest request)
        {
            var entity = await GetOrNullAsync(userId);
            var now = DateTime.UtcNow;

            if (entity == null)
            {
                entity = new UserAiProfile
                {
                    UserId = userId,
                    UpdatedAt = now
                };
                ApplyUpdate(entity, request);
                await _unitOfWork.UserAiProfiles.AddAsync(entity);
            }
            else
            {
                ApplyUpdate(entity, request);
                entity.UpdatedAt = now;
                _unitOfWork.UserAiProfiles.Update(entity);
            }

            await _unitOfWork.CompleteAsync();
            return Map(entity, userId);
        }

        private static void ApplyUpdate(UserAiProfile entity, UpdateUserAiProfileRequest request)
        {
            if (request.EatingPattern != null)
            {
                entity.EatingPattern = request.EatingPattern;
            }

            if (request.DislikedFoods != null)
            {
                entity.DislikedFoods = request.DislikedFoods;
            }

            if (request.Preferences != null || request.AllergiesAcknowledged.HasValue)
            {
                entity.Preferences = UserAiProfilePreferencesHelper.MergePreferences(
                    entity.Preferences,
                    request.Preferences,
                    request.AllergiesAcknowledged);
            }
        }

        private async Task<UserAiProfile?> GetOrNullAsync(Guid userId)
        {
            return (await _unitOfWork.UserAiProfiles.FindAsync(x => x.UserId == userId)).FirstOrDefault();
        }

        private static UserAiProfileResponse Map(UserAiProfile? entity, Guid userId)
        {
            return new UserAiProfileResponse
            {
                UserId = userId,
                Preferences = entity?.Preferences,
                DislikedFoods = entity?.DislikedFoods,
                EatingPattern = entity?.EatingPattern,
                AllergiesAcknowledged = UserAiProfilePreferencesHelper.TryGetAllergiesAcknowledged(entity?.Preferences),
                UpdatedAt = entity?.UpdatedAt
            };
        }
    }
}
