using System;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Helpers;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class HealthProfileService : IHealthProfileService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICacheService _cache;
        private static readonly TimeSpan HealthTargetsTtl = TimeSpan.FromMinutes(15);

        public HealthProfileService(IUnitOfWork unitOfWork, ICacheService cache)
        {
            _unitOfWork = unitOfWork;
            _cache = cache;
        }

        public async Task<HealthProfileResponse> GetAsync(Guid userId)
        {
            var cacheKey = CacheKeys.UserHealthTargets(userId);
            var cached = await _cache.GetAsync<HealthProfileResponse>(cacheKey);
            if (cached != null)
            {
                return cached;
            }

            var healthProfile = await EnsureHealthProfileAsync(userId);
            var response = MapToResponse(healthProfile);
            await _cache.SetAsync(cacheKey, response, HealthTargetsTtl);
            return response;
        }

        public async Task<HealthProfileResponse> UpdateAsync(Guid userId, UpdateHealthProfileRequest request)
        {
            var healthProfile = await EnsureHealthProfileAsync(userId);
            var userProfile = await GetUserProfileAsync(userId);

            if (!userProfile.DateOfBirth.HasValue)
            {
                throw new ArgumentException("Please enter your date of birth in your profile first to calculate targets.");
            }

            healthProfile.HeightCm = request.HeightCm;
            healthProfile.WeightKg = request.WeightKg;
            healthProfile.BodyFatPercent = request.BodyFatPercent;
            if (request.TargetWeightKg.HasValue)
            {
                healthProfile.TargetWeightKg = request.TargetWeightKg;
            }
            healthProfile.ActivityLevel = request.ActivityLevel;
            healthProfile.Goal = request.Goal;

            HealthProfileMetricsCalculator.Apply(
                healthProfile,
                userProfile.Gender,
                userProfile.DateOfBirth,
                request.TargetCalories);

            healthProfile.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.HealthProfiles.Update(healthProfile);
            await _unitOfWork.CompleteAsync();

            await _cache.RemoveAsync(CacheKeys.UserHealthTargets(userId));
            return MapToResponse(healthProfile);
        }

        public async Task<HealthProfileSummaryResponse> GetSummaryAsync(Guid userId)
        {
            var healthProfile = await EnsureHealthProfileAsync(userId);
            return MapToSummaryResponse(healthProfile);
        }

        public async Task<HealthProfileResponse> CalculateAsync(Guid userId)
        {
            var healthProfile = await EnsureHealthProfileAsync(userId);
            var userProfile = await GetUserProfileAsync(userId);

            if (!userProfile.DateOfBirth.HasValue)
            {
                throw new ArgumentException("Please enter your date of birth in your profile first to calculate targets.");
            }

            HealthProfileMetricsCalculator.Apply(healthProfile, userProfile.Gender, userProfile.DateOfBirth);
            healthProfile.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.HealthProfiles.Update(healthProfile);
            await _unitOfWork.CompleteAsync();

            await _cache.RemoveAsync(CacheKeys.UserHealthTargets(userId));
            return MapToResponse(healthProfile);
        }

        public async Task<HealthProfileResponse> UpdateGoalAsync(Guid userId, UpdateHealthGoalRequest request)
        {
            var healthProfile = await EnsureHealthProfileAsync(userId);
            var userProfile = await GetUserProfileAsync(userId);

            if (!userProfile.DateOfBirth.HasValue)
            {
                throw new ArgumentException("Please enter your date of birth in your profile first to calculate targets.");
            }

            healthProfile.Goal = request.Goal;
            HealthProfileMetricsCalculator.Apply(healthProfile, userProfile.Gender, userProfile.DateOfBirth);

            healthProfile.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.HealthProfiles.Update(healthProfile);
            await _unitOfWork.CompleteAsync();

            await _cache.RemoveAsync(CacheKeys.UserHealthTargets(userId));
            return MapToResponse(healthProfile);
        }

        private async Task EnsureUserExistsAsync(Guid userId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null)
            {
                throw new Exception("Account not found. Please sign out and sign in again.");
            }
        }

        private async Task<HealthProfile> EnsureHealthProfileAsync(Guid userId)
        {
            await EnsureUserExistsAsync(userId);

            var healthProfile = (await _unitOfWork.HealthProfiles.FindAsync(profile => profile.UserId == userId)).FirstOrDefault();
            if (healthProfile != null)
            {
                return healthProfile;
            }

            healthProfile = new HealthProfile
            {
                UserId = userId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.HealthProfiles.AddAsync(healthProfile);
            await _unitOfWork.CompleteAsync();
            return healthProfile;
        }

        private async Task<Profile> GetUserProfileAsync(Guid userId)
        {
            await EnsureUserExistsAsync(userId);

            var userProfile = await _unitOfWork.Profiles.GetByIdAsync(userId);
            if (userProfile == null)
            {
                userProfile = new Profile
                {
                    UserId = userId,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                await _unitOfWork.Profiles.AddAsync(userProfile);
                await _unitOfWork.CompleteAsync();
            }

            return userProfile;
        }

        private static HealthProfileResponse MapToResponse(HealthProfile healthProfile)
        {
            return new HealthProfileResponse
            {
                UserId = healthProfile.UserId,
                HeightCm = healthProfile.HeightCm,
                WeightKg = healthProfile.WeightKg,
                BodyFatPercent = healthProfile.BodyFatPercent,
                TargetWeightKg = healthProfile.TargetWeightKg,
                ActivityLevel = healthProfile.ActivityLevel,
                Goal = healthProfile.Goal,
                Bmi = healthProfile.Bmi,
                BmrKcal = healthProfile.BmrKcal,
                TdeeKcal = healthProfile.TdeeKcal,
                TargetCalories = healthProfile.TargetCalories,
                TargetProteinG = healthProfile.TargetProteinG,
                TargetCarbsG = healthProfile.TargetCarbsG,
                TargetFatG = healthProfile.TargetFatG
            };
        }

        private static HealthProfileSummaryResponse MapToSummaryResponse(HealthProfile healthProfile)
        {
            return new HealthProfileSummaryResponse
            {
                UserId = healthProfile.UserId,
                HeightCm = healthProfile.HeightCm,
                WeightKg = healthProfile.WeightKg,
                BodyFatPercent = healthProfile.BodyFatPercent,
                TargetWeightKg = healthProfile.TargetWeightKg,
                ActivityLevel = healthProfile.ActivityLevel,
                Goal = healthProfile.Goal,
                Bmi = healthProfile.Bmi,
                BmrKcal = healthProfile.BmrKcal,
                TdeeKcal = healthProfile.TdeeKcal,
                TargetCalories = healthProfile.TargetCalories,
                TargetProteinG = healthProfile.TargetProteinG,
                TargetCarbsG = healthProfile.TargetCarbsG,
                TargetFatG = healthProfile.TargetFatG,
                UpdatedAt = healthProfile.UpdatedAt
            };
        }
    }
}
