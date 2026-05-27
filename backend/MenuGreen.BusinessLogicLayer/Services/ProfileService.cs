using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class ProfileService : IProfileService
    {
        private readonly IUnitOfWork _unitOfWork;

        public ProfileService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<ProfileResponse> GetProfileAsync(Guid userId)
        {
            var profile = await _unitOfWork.Profiles.GetByIdAsync(userId);
            if (profile == null) throw new Exception("Profile not found.");

            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId);
            var healthProfile = healthProfiles.FirstOrDefault();
            if (healthProfile == null)
            {
                healthProfile = new HealthProfile
                {
                    UserId = userId,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.HealthProfiles.AddAsync(healthProfile);
                await _unitOfWork.CompleteAsync();
            }

            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            var roleName = "User";
            if (user != null)
            {
                var roleEntities = await _unitOfWork.Roles.FindAsync(r => r.Id == user.RoleId);
                if (roleEntities.Any())
                {
                    roleName = roleEntities.First().Name;
                }
            }

            return MapToResponse(profile, healthProfile, roleName);
        }

        public async Task<ProfileResponse> UpdateProfileAsync(Guid userId, UpdateProfileRequest request)
        {
            var profile = await _unitOfWork.Profiles.GetByIdAsync(userId);
            if (profile == null) throw new Exception("Profile not found.");

            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId);
            var healthProfile = healthProfiles.FirstOrDefault();
            if (healthProfile == null)
            {
                healthProfile = new HealthProfile
                {
                    UserId = userId,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.HealthProfiles.AddAsync(healthProfile);
            }

            if (request.FullName != null) profile.FullName = request.FullName;
            if (request.DateOfBirth != null) profile.DateOfBirth = request.DateOfBirth;
            if (request.Gender != null) profile.Gender = request.Gender;
            if (request.PreferredCuisine != null) profile.PreferredCuisine = request.PreferredCuisine;

            if (request.HeightCm.HasValue) healthProfile.HeightCm = request.HeightCm;
            if (request.WeightKg.HasValue) healthProfile.WeightKg = request.WeightKg;
            if (request.BodyFatPercent.HasValue) healthProfile.BodyFatPercent = request.BodyFatPercent;
            if (request.ActivityLevel != null) healthProfile.ActivityLevel = request.ActivityLevel;
            if (request.Goal != null) healthProfile.Goal = request.Goal;

            // Automatically calculate health metrics based on new data
            CalculateNutritionTargets(profile, healthProfile);

            profile.UpdatedAt = DateTime.UtcNow;
            healthProfile.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Profiles.Update(profile);
            _unitOfWork.HealthProfiles.Update(healthProfile);
            await _unitOfWork.CompleteAsync();

            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            var roleName = "User";
            if (user != null)
            {
                var roleEntities = await _unitOfWork.Roles.FindAsync(r => r.Id == user.RoleId);
                if (roleEntities.Any())
                {
                    roleName = roleEntities.First().Name;
                }
            }

            return MapToResponse(profile, healthProfile, roleName);
        }

        private void CalculateNutritionTargets(DataAccessLayer.Entities.Profile p, DataAccessLayer.Entities.HealthProfile hp)
        {
            // Only calculate if weight and height are provided
            if (!hp.WeightKg.HasValue || !hp.HeightCm.HasValue) return;

            int age = 25; // Assume 25 years old if date of birth is not provided
            if (p.DateOfBirth.HasValue)
            {
                age = DateTime.Today.Year - p.DateOfBirth.Value.Year;
                if (p.DateOfBirth.Value > DateOnly.FromDateTime(DateTime.Today.AddYears(-age))) age--; // Subtract 1 if birthday hasn't occurred yet this year
            }

            // Calculate BMR using Mifflin-St Jeor equation
            double bmr = (10 * (double)hp.WeightKg.Value) + (6.25 * (double)hp.HeightCm.Value) - (5 * age);
            bmr += (p.Gender?.ToLower() == "male" || p.Gender?.ToLower() == "nam") ? 5 : -161;
            hp.BmrKcal = (int)Math.Round(bmr);

            // Calculate TDEE (Total Daily Energy Expenditure)
            double multiplier = hp.ActivityLevel?.ToLower() switch
            {
                "light" => 1.375,       // Lightly active
                "moderate" => 1.55,     // Moderately active
                "active" => 1.725,      // Very active
                "veryactive" => 1.9,    // Extra active
                _ => 1.2                // Sedentary
            };
            hp.TdeeKcal = (int)Math.Round(bmr * multiplier);

            // Calculate Target Calories based on user's goal
            int targetKcal = hp.TdeeKcal.Value;
            targetKcal += hp.Goal?.ToLower() switch
            {
                "loseweight" => -500,   // Lose weight (500 kcal deficit)
                "gainweight" => 500,    // Gain weight (500 kcal surplus)
                _ => 0                  // Maintain weight
            };
            hp.TargetCalories = targetKcal;

            // Calculate BMI
            double heightMeters = (double)hp.HeightCm.Value / 100.0;
            hp.Bmi = (decimal)Math.Round((double)hp.WeightKg.Value / (heightMeters * heightMeters), 2);

            // Calculate Macro Targets (Reference ratio: Protein 30%, Carbs 40%, Fat 30%)
            // 1g Protein = 4 kcal, 1g Carbs = 4 kcal, 1g Fat = 9 kcal
            hp.TargetProteinG = (int)Math.Round((targetKcal * 0.30) / 4);
            hp.TargetCarbsG = (int)Math.Round((targetKcal * 0.40) / 4);
            hp.TargetFatG = (int)Math.Round((targetKcal * 0.30) / 9);
        }

        private ProfileResponse MapToResponse(DataAccessLayer.Entities.Profile p, DataAccessLayer.Entities.HealthProfile hp, string roleName)
        {
            return new ProfileResponse
            {
                Id = p.UserId,
                FullName = p.FullName,
                AvatarUrl = p.AvatarUrl,
                Role = roleName,
                DateOfBirth = p.DateOfBirth,
                Gender = p.Gender,
                HeightCm = hp.HeightCm,
                WeightKg = hp.WeightKg,
                BodyFatPercent = hp.BodyFatPercent,
                ActivityLevel = hp.ActivityLevel ?? "Sedentary",
                Goal = hp.Goal,
                TdeeKcal = hp.TdeeKcal,
                BmrKcal = hp.BmrKcal,
                TargetCalories = hp.TargetCalories,
                TargetProteinG = hp.TargetProteinG,
                TargetCarbsG = hp.TargetCarbsG,
                TargetFatG = hp.TargetFatG,
                PreferredCuisine = p.PreferredCuisine
            };
        }
    }
}
