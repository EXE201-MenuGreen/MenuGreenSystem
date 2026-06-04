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
    public class HealthProfileService : IHealthProfileService
    {
        private readonly IUnitOfWork _unitOfWork;

        public HealthProfileService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<HealthProfileResponse> GetAsync(Guid userId)
        {
            var healthProfile = await EnsureHealthProfileAsync(userId);
            return MapToResponse(healthProfile);
        }

        public async Task<HealthProfileResponse> UpdateAsync(Guid userId, UpdateHealthProfileRequest request)
        {
            var healthProfile = await EnsureHealthProfileAsync(userId);
            var userProfile = await GetUserProfileAsync(userId);

            healthProfile.HeightCm = request.HeightCm;
            healthProfile.WeightKg = request.WeightKg;
            healthProfile.BodyFatPercent = request.BodyFatPercent;
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

            HealthProfileMetricsCalculator.Apply(healthProfile, userProfile.Gender, userProfile.DateOfBirth);
            healthProfile.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.HealthProfiles.Update(healthProfile);
            await _unitOfWork.CompleteAsync();

            return MapToResponse(healthProfile);
        }

        public async Task<HealthProfileResponse> UpdateGoalAsync(Guid userId, UpdateHealthGoalRequest request)
        {
            var healthProfile = await EnsureHealthProfileAsync(userId);
            var userProfile = await GetUserProfileAsync(userId);

            healthProfile.Goal = request.Goal;
            HealthProfileMetricsCalculator.Apply(healthProfile, userProfile.Gender, userProfile.DateOfBirth);

            healthProfile.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.HealthProfiles.Update(healthProfile);
            await _unitOfWork.CompleteAsync();

            return MapToResponse(healthProfile);
        }

        private async Task EnsureUserExistsAsync(Guid userId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null)
            {
                throw new Exception("Tài khoản không tồn tại. Vui lòng đăng xuất và đăng nhập lại.");
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
