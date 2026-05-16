using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Interfaces;

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

            return MapToResponse(profile);
        }

        public async Task<ProfileResponse> UpdateProfileAsync(Guid userId, UpdateProfileRequest request)
        {
            var profile = await _unitOfWork.Profiles.GetByIdAsync(userId);
            if (profile == null) throw new Exception("Profile not found.");

            if (request.FullName != null) profile.FullName = request.FullName;
            if (request.DateOfBirth != null) profile.DateOfBirth = request.DateOfBirth;
            if (request.Gender != null) profile.Gender = request.Gender;
            if (request.HeightCm.HasValue) profile.HeightCm = request.HeightCm;
            if (request.WeightKg.HasValue) profile.WeightKg = request.WeightKg;
            if (request.BodyFatPercent.HasValue) profile.BodyFatPercent = request.BodyFatPercent;
            if (request.ActivityLevel != null) profile.ActivityLevel = request.ActivityLevel;
            if (request.Goal != null) profile.Goal = request.Goal;
            if (request.PreferredCuisine != null) profile.PreferredCuisine = request.PreferredCuisine;

            // Automatically calculate health metrics based on new data
            CalculateNutritionTargets(profile);

            profile.UpdatedAt = DateTimeOffset.UtcNow;
            _unitOfWork.Profiles.Update(profile);
            await _unitOfWork.CompleteAsync();

            return MapToResponse(profile);
        }

        private void CalculateNutritionTargets(DataAccessLayer.Entities.Profile p)
        {
            // Only calculate if weight and height are provided
            if (!p.WeightKg.HasValue || !p.HeightCm.HasValue) return;

            int age = 25; // Assume 25 years old if date of birth is not provided
            if (p.DateOfBirth.HasValue)
            {
                age = DateTime.Today.Year - p.DateOfBirth.Value.Year;
                if (p.DateOfBirth.Value > DateOnly.FromDateTime(DateTime.Today.AddYears(-age))) age--; // Subtract 1 if birthday hasn't occurred yet this year
            }

            // Calculate BMR using Mifflin-St Jeor equation
            double bmr = (10 * (double)p.WeightKg.Value) + (6.25 * (double)p.HeightCm.Value) - (5 * age);
            bmr += (p.Gender?.ToLower() == "male" || p.Gender?.ToLower() == "nam") ? 5 : -161;
            p.BmrKcal = (int)Math.Round(bmr);

            // Calculate TDEE (Total Daily Energy Expenditure)
            double multiplier = p.ActivityLevel?.ToLower() switch
            {
                "light" => 1.375,       // Lightly active
                "moderate" => 1.55,     // Moderately active
                "active" => 1.725,      // Very active
                "veryactive" => 1.9,    // Extra active
                _ => 1.2                // Sedentary
            };
            p.TdeeKcal = (int)Math.Round(bmr * multiplier);

            // Calculate Target Calories based on user's goal
            int targetKcal = p.TdeeKcal.Value;
            targetKcal += p.Goal?.ToLower() switch
            {
                "loseweight" => -500,   // Lose weight (500 kcal deficit)
                "gainweight" => 500,    // Gain weight (500 kcal surplus)
                _ => 0                  // Maintain weight
            };
            p.TargetCalories = targetKcal;

            // Calculate Macro Targets (Reference ratio: Protein 30%, Carbs 40%, Fat 30%)
            // 1g Protein = 4 kcal, 1g Carbs = 4 kcal, 1g Fat = 9 kcal
            p.TargetProteinG = (int)Math.Round((targetKcal * 0.30) / 4);
            p.TargetCarbsG = (int)Math.Round((targetKcal * 0.40) / 4);
            p.TargetFatG = (int)Math.Round((targetKcal * 0.30) / 9);
        }

        private ProfileResponse MapToResponse(DataAccessLayer.Entities.Profile p)
        {
            return new ProfileResponse
            {
                Id = p.Id,
                FullName = p.FullName,
                AvatarUrl = p.AvatarUrl,
                Role = p.Role,
                DateOfBirth = p.DateOfBirth,
                Gender = p.Gender,
                HeightCm = p.HeightCm,
                WeightKg = p.WeightKg,
                BodyFatPercent = p.BodyFatPercent,
                ActivityLevel = p.ActivityLevel ?? "Sedentary",
                Goal = p.Goal,
                TdeeKcal = p.TdeeKcal,
                BmrKcal = p.BmrKcal,
                TargetCalories = p.TargetCalories,
                TargetProteinG = p.TargetProteinG,
                TargetCarbsG = p.TargetCarbsG,
                TargetFatG = p.TargetFatG,
                PreferredCuisine = p.PreferredCuisine
            };
        }
    }
}
