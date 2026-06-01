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

            RecalculateMetrics(healthProfile, userProfile.Gender, userProfile.DateOfBirth);

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

        private void RecalculateMetrics(HealthProfile healthProfile, string? gender, DateOnly? dateOfBirth)
        {
            if (!healthProfile.HeightCm.HasValue || !healthProfile.WeightKg.HasValue)
            {
                return;
            }

            var age = CalculateAge(dateOfBirth);
            var bmr = CalculateBmr(healthProfile.WeightKg.Value, healthProfile.HeightCm.Value, age, gender);
            var multiplier = GetActivityMultiplier(healthProfile.ActivityLevel);

            healthProfile.Bmi = CalculateBmi(healthProfile.WeightKg.Value, healthProfile.HeightCm.Value);
            healthProfile.BmrKcal = (int)Math.Round(bmr);
            healthProfile.TdeeKcal = (int)Math.Round(bmr * multiplier);
            healthProfile.TargetCalories = CalculateTargetCalories(healthProfile.TdeeKcal.Value, healthProfile.Goal);

            ApplyMacroTargets(healthProfile);
        }

        private static int CalculateAge(DateOnly? dateOfBirth)
        {
            if (!dateOfBirth.HasValue)
            {
                return 25;
            }

            var age = DateTime.Today.Year - dateOfBirth.Value.Year;
            if (dateOfBirth.Value > DateOnly.FromDateTime(DateTime.Today.AddYears(-age)))
            {
                age--;
            }

            return age;
        }

        private static double CalculateBmr(decimal weightKg, decimal heightCm, int age, string? gender)
        {
            var baseBmr = (10 * (double)weightKg) + (6.25 * (double)heightCm) - (5 * age);
            var genderBonus = gender?.Trim().ToLower() is "male" or "nam" ? 5 : -161;
            return baseBmr + genderBonus;
        }

        private static double GetActivityMultiplier(string? activityLevel)
        {
            return activityLevel?.Trim().ToLower() switch
            {
                "sedentary" => 1.2,
                "lightly active" => 1.375,
                "moderately active" => 1.55,
                "very active" => 1.725,
                _ => 1.2
            };
        }

        private static decimal CalculateBmi(decimal weightKg, decimal heightCm)
        {
            var heightMeters = (double)heightCm / 100d;
            return (decimal)Math.Round((double)weightKg / (heightMeters * heightMeters), 2);
        }

        private static int CalculateTargetCalories(int tdeeKcal, string? goal)
        {
            return tdeeKcal + (goal?.Trim().ToLower() switch
            {
                "gain weight" => 300,
                "lose weight" => -500,
                "build muscle" => 200,
                _ => 0
            });
        }

        private static void ApplyMacroTargets(HealthProfile healthProfile)
        {
            var goal = healthProfile.Goal?.Trim().ToLower();
            var proteinRatio = goal == "build muscle" ? 0.35 : 0.30;
            var fatRatio = goal == "build muscle" ? 0.25 : 0.30;
            var carbsRatio = 0.40;

            var targetCalories = (double)(healthProfile.TargetCalories ?? 0);
            healthProfile.TargetProteinG = (int)Math.Round((targetCalories * proteinRatio) / 4);
            healthProfile.TargetCarbsG = (int)Math.Round((targetCalories * carbsRatio) / 4);
            healthProfile.TargetFatG = (int)Math.Round((targetCalories * fatRatio) / 9);
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
    }
}
