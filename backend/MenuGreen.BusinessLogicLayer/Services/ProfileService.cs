using System;
using System.Linq;
using System.Security.Cryptography;
using System.Threading.Tasks;
using BCrypt.Net;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
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
            var profile = await EnsureProfileAsync(userId);
            var healthProfile = await EnsureHealthProfileAsync(userId);
            var roleName = await GetRoleNameAsync(userId);
            return MapToResponse(profile, healthProfile, roleName);
        }

        public async Task<ProfileResponse> UpdateProfileAsync(Guid userId, UpdateProfileRequest request)
        {
            var profile = await EnsureProfileAsync(userId);
            var healthProfile = await EnsureHealthProfileAsync(userId);

            if (request.FullName != null) profile.FullName = request.FullName;
            if (request.DateOfBirth != null) profile.DateOfBirth = request.DateOfBirth;
            if (request.Gender != null) profile.Gender = request.Gender;
            if (request.PreferredCuisine != null) profile.PreferredCuisine = request.PreferredCuisine;

            if (request.HeightCm.HasValue) healthProfile.HeightCm = request.HeightCm;
            if (request.WeightKg.HasValue) healthProfile.WeightKg = request.WeightKg;
            if (request.BodyFatPercent.HasValue) healthProfile.BodyFatPercent = request.BodyFatPercent;
            if (request.ActivityLevel != null) healthProfile.ActivityLevel = request.ActivityLevel;
            if (request.Goal != null) healthProfile.Goal = request.Goal;

            CalculateNutritionTargets(profile, healthProfile);

            profile.UpdatedAt = DateTime.UtcNow;
            healthProfile.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Profiles.Update(profile);
            _unitOfWork.HealthProfiles.Update(healthProfile);
            await _unitOfWork.CompleteAsync();

            var roleName = await GetRoleNameAsync(userId);
            return MapToResponse(profile, healthProfile, roleName);
        }

        public async Task<ProfileResponse> UpdateAvatarAsync(Guid userId, UpdateAvatarRequest request)
        {
            var profile = await EnsureProfileAsync(userId);
            profile.AvatarUrl = request.AvatarUrl;
            profile.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.Profiles.Update(profile);
            await _unitOfWork.CompleteAsync();

            var healthProfile = await EnsureHealthProfileAsync(userId);
            var roleName = await GetRoleNameAsync(userId);
            return MapToResponse(profile, healthProfile, roleName);
        }

        public async Task<ProfileResponse> RemoveAvatarAsync(Guid userId)
        {
            var profile = await EnsureProfileAsync(userId);
            profile.AvatarUrl = null;
            profile.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.Profiles.Update(profile);
            await _unitOfWork.CompleteAsync();

            var healthProfile = await EnsureHealthProfileAsync(userId);
            var roleName = await GetRoleNameAsync(userId);
            return MapToResponse(profile, healthProfile, roleName);
        }

        public async Task<ProfileSummaryResponse> GetSummaryAsync(Guid userId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId) ?? throw new Exception("User not found.");
            var profile = await EnsureProfileAsync(userId);
            var healthProfile = await EnsureHealthProfileAsync(userId);

            var allergies = await _unitOfWork.Allergies.FindAsync(x => x.UserId == userId && x.IsActive);
            var aiProfile = (await _unitOfWork.UserAiProfiles.FindAsync(x => x.UserId == userId)).FirstOrDefault();

            var completedSteps = BuildCompletedSteps(profile, healthProfile, allergies.Any(), aiProfile != null);

            return new ProfileSummaryResponse
            {
                UserId = userId,
                Email = user.Email,
                FullName = profile.FullName,
                AvatarUrl = profile.AvatarUrl,
                Gender = profile.Gender,
                DateOfBirth = profile.DateOfBirth,
                PreferredCuisine = profile.PreferredCuisine,
                HeightCm = healthProfile.HeightCm,
                WeightKg = healthProfile.WeightKg,
                BodyFatPercent = healthProfile.BodyFatPercent,
                ActivityLevel = healthProfile.ActivityLevel ?? string.Empty,
                Goal = healthProfile.Goal,
                Bmi = healthProfile.Bmi,
                BmrKcal = healthProfile.BmrKcal,
                TdeeKcal = healthProfile.TdeeKcal,
                TargetCalories = healthProfile.TargetCalories,
                TargetProteinG = healthProfile.TargetProteinG,
                TargetCarbsG = healthProfile.TargetCarbsG,
                TargetFatG = healthProfile.TargetFatG,
                AllergyCount = allergies.Count(),
                HasProfile = !string.IsNullOrWhiteSpace(profile.FullName) || profile.DateOfBirth.HasValue || !string.IsNullOrWhiteSpace(profile.Gender) || !string.IsNullOrWhiteSpace(profile.PreferredCuisine),
                HasHealthProfile = healthProfile.HeightCm.HasValue || healthProfile.WeightKg.HasValue || healthProfile.BodyFatPercent.HasValue || !string.IsNullOrWhiteSpace(healthProfile.ActivityLevel) || !string.IsNullOrWhiteSpace(healthProfile.Goal),
                HasAllergies = allergies.Any(),
                HasAiProfile = aiProfile != null,
                OnboardingStepsCompleted = completedSteps,
            };
        }

        public async Task<ProfileCompletionResponse> GetCompletionAsync(Guid userId)
        {
            var profile = await EnsureProfileAsync(userId);
            var healthProfile = await EnsureHealthProfileAsync(userId);
            var allergies = await _unitOfWork.Allergies.FindAsync(x => x.UserId == userId && x.IsActive);
            var aiProfile = (await _unitOfWork.UserAiProfiles.FindAsync(x => x.UserId == userId)).FirstOrDefault();

            var completedSteps = BuildCompletedSteps(profile, healthProfile, allergies.Any(), aiProfile != null);
            var allSteps = new[] { "Profile", "HealthProfile", "Allergies", "Goal", "UserAiProfile" };
            var missingSteps = allSteps.Except(completedSteps, StringComparer.OrdinalIgnoreCase).ToArray();
            var completionPercent = (int)Math.Round((completedSteps.Length * 100.0) / allSteps.Length);

            return new ProfileCompletionResponse
            {
                IsCompleted = missingSteps.Length == 0,
                CompletionPercent = completionPercent,
                CompletedSteps = completedSteps,
                MissingSteps = missingSteps,
                NextStep = missingSteps.FirstOrDefault() ?? "Completed"
            };
        }

        public async Task ChangePasswordAsync(Guid userId, ChangePasswordRequest request)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId) ?? throw new Exception("User not found.");

            if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
            {
                throw new Exception("Current password is incorrect.");
            }

            if (request.NewPassword != request.ConfirmNewPassword)
            {
                throw new Exception("Confirm password does not match.");
            }

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            user.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();
        }

        private static string[] BuildCompletedSteps(Profile profile, HealthProfile healthProfile, bool hasAllergies, bool hasAiProfile)
        {
            var steps = new System.Collections.Generic.List<string>();

            if (!string.IsNullOrWhiteSpace(profile.FullName) || profile.DateOfBirth.HasValue || !string.IsNullOrWhiteSpace(profile.Gender) || !string.IsNullOrWhiteSpace(profile.PreferredCuisine))
            {
                steps.Add("Profile");
            }

            if (healthProfile.HeightCm.HasValue || healthProfile.WeightKg.HasValue || healthProfile.BodyFatPercent.HasValue || !string.IsNullOrWhiteSpace(healthProfile.ActivityLevel) || !string.IsNullOrWhiteSpace(healthProfile.Goal))
            {
                steps.Add("HealthProfile");
            }

            if (hasAllergies)
            {
                steps.Add("Allergies");
            }

            if (!string.IsNullOrWhiteSpace(healthProfile.Goal))
            {
                steps.Add("Goal");
            }

            if (hasAiProfile)
            {
                steps.Add("UserAiProfile");
            }

            return steps.Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
        }

        private async Task<Profile> EnsureProfileAsync(Guid userId)
        {
            var profile = await _unitOfWork.Profiles.GetByIdAsync(userId);
            if (profile != null) return profile;

            profile = new Profile { UserId = userId, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow };
            await _unitOfWork.Profiles.AddAsync(profile);
            await _unitOfWork.CompleteAsync();
            return profile;
        }

        private async Task<HealthProfile> EnsureHealthProfileAsync(Guid userId)
        {
            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId);
            var healthProfile = healthProfiles.FirstOrDefault();
            if (healthProfile != null) return healthProfile;

            healthProfile = new HealthProfile { UserId = userId, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow };
            await _unitOfWork.HealthProfiles.AddAsync(healthProfile);
            await _unitOfWork.CompleteAsync();
            return healthProfile;
        }

        private async Task<string> GetRoleNameAsync(Guid userId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) return "User";
            var roleEntities = await _unitOfWork.Roles.FindAsync(r => r.Id == user.RoleId);
            return roleEntities.FirstOrDefault()?.Name ?? "User";
        }

        private void CalculateNutritionTargets(Profile p, HealthProfile hp)
        {
            if (!hp.WeightKg.HasValue || !hp.HeightCm.HasValue) return;

            int age = 25;
            if (p.DateOfBirth.HasValue)
            {
                age = DateTime.Today.Year - p.DateOfBirth.Value.Year;
                if (p.DateOfBirth.Value > DateOnly.FromDateTime(DateTime.Today.AddYears(-age))) age--;
            }

            double bmr = (10 * (double)hp.WeightKg.Value) + (6.25 * (double)hp.HeightCm.Value) - (5 * age);
            bmr += (p.Gender?.ToLower() == "male" || p.Gender?.ToLower() == "nam") ? 5 : -161;
            hp.BmrKcal = (int)Math.Round(bmr);

            double multiplier = hp.ActivityLevel?.ToLower() switch
            {
                "light" => 1.375,
                "moderate" => 1.55,
                "active" => 1.725,
                "veryactive" => 1.9,
                _ => 1.2
            };
            hp.TdeeKcal = (int)Math.Round(bmr * multiplier);

            int targetKcal = hp.TdeeKcal.Value;
            targetKcal += hp.Goal?.ToLower() switch
            {
                "loseweight" => -500,
                "gainweight" => 500,
                _ => 0
            };
            hp.TargetCalories = targetKcal;

            double heightMeters = (double)hp.HeightCm.Value / 100.0;
            hp.Bmi = (decimal)Math.Round((double)hp.WeightKg.Value / (heightMeters * heightMeters), 2);
            hp.TargetProteinG = (int)Math.Round((targetKcal * 0.30) / 4);
            hp.TargetCarbsG = (int)Math.Round((targetKcal * 0.40) / 4);
            hp.TargetFatG = (int)Math.Round((targetKcal * 0.30) / 9);
        }

        private ProfileResponse MapToResponse(Profile p, HealthProfile hp, string roleName)
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
