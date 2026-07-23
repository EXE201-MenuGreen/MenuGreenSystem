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

            var dob = request.DateOfBirth ?? profile.DateOfBirth;
            if (!dob.HasValue)
            {
                throw new ArgumentException("Date of birth is required to calculate your profile and target metrics.");
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

            HealthProfileMetricsCalculator.Apply(healthProfile, profile.Gender, profile.DateOfBirth);

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

            var hasAllergies = await HasActiveAllergiesAsync(userId);
            var allergyCount = await CountActiveAllergiesAsync(userId);
            var aiProfile = (await _unitOfWork.UserAiProfiles.FindAsync(x => x.UserId == userId)).FirstOrDefault();
            var hasSnapshot = await HasNutritionSnapshotAsync(userId);
            var allergiesAcknowledged = UserAiProfilePreferencesHelper.TryGetAllergiesAcknowledged(aiProfile?.Preferences);

            var completedSteps = BuildCompletedSteps(
                profile,
                healthProfile,
                hasAllergies,
                allergiesAcknowledged,
                aiProfile,
                hasSnapshot);

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
                AllergyCount = allergyCount,
                HasProfile = !string.IsNullOrWhiteSpace(profile.FullName) && !string.IsNullOrWhiteSpace(profile.Gender),
                HasHealthProfile = healthProfile.HeightCm.HasValue && healthProfile.WeightKg.HasValue && !string.IsNullOrWhiteSpace(healthProfile.ActivityLevel),
                HasAllergies = hasAllergies || allergiesAcknowledged,
                HasAiProfile = UserAiProfilePreferencesHelper.HasMeaningfulAiProfile(
                    aiProfile?.Preferences,
                    aiProfile?.EatingPattern,
                    aiProfile?.DislikedFoods),
                OnboardingStepsCompleted = completedSteps,
            };
        }

        public async Task<ProfileCompletionResponse> GetCompletionAsync(Guid userId)
        {
            var roleName = await GetRoleNameAsync(userId);
            var isCoach = string.Equals(roleName, "Coach", StringComparison.OrdinalIgnoreCase);

            // Coach / PT không cần onboarding của user (calorie goal, allergy, snapshot) — bỏ qua.
            if (isCoach)
            {
                return new ProfileCompletionResponse
                {
                    IsCompleted = true,
                    CompletionPercent = 100,
                    CompletedSteps = new[] { "Profile", "Coach" },
                    MissingSteps = Array.Empty<string>(),
                    NextStep = "Completed"
                };
            }

            var profile = await EnsureProfileAsync(userId);
            var healthProfile = await EnsureHealthProfileAsync(userId);
            var hasAllergies = await HasActiveAllergiesAsync(userId);
            var aiProfile = (await _unitOfWork.UserAiProfiles.FindAsync(x => x.UserId == userId)).FirstOrDefault();
            var hasSnapshot = await HasNutritionSnapshotAsync(userId);
            var allergiesAcknowledged = UserAiProfilePreferencesHelper.TryGetAllergiesAcknowledged(aiProfile?.Preferences);

            var completedSteps = BuildCompletedSteps(
                profile,
                healthProfile,
                hasAllergies,
                allergiesAcknowledged,
                aiProfile,
                hasSnapshot);
            var allSteps = new[] { "Profile", "HealthProfile", "Allergies", "Goal", "UserAiProfile", "NutritionSnapshot" };
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

        private async Task<bool> HasActiveAllergiesAsync(Guid userId)
        {
            var allergies = await _unitOfWork.Allergies.FindAsync(x => x.UserId == userId && x.IsActive);
            if (allergies.Any())
            {
                return true;
            }

            var links = await _unitOfWork.UserAllergies.FindAsync(x => x.UserId == userId);
            return links.Any();
        }

        private async Task<int> CountActiveAllergiesAsync(Guid userId)
        {
            var allergies = await _unitOfWork.Allergies.FindAsync(x => x.UserId == userId && x.IsActive);
            return allergies.Count();
        }

        private async Task<bool> HasNutritionSnapshotAsync(Guid userId)
        {
            var snapshots = await _unitOfWork.NutritionSnapshots.FindAsync(x => x.UserId == userId);
            return snapshots.Any();
        }

        private static string[] BuildCompletedSteps(
            Profile profile,
            HealthProfile healthProfile,
            bool hasAllergies,
            bool allergiesAcknowledged,
            UserAiProfile? aiProfile,
            bool hasNutritionSnapshot)
        {
            var steps = new System.Collections.Generic.List<string>();

            if (!string.IsNullOrWhiteSpace(profile.FullName) && !string.IsNullOrWhiteSpace(profile.Gender))
            {
                steps.Add("Profile");
            }

            if (healthProfile.HeightCm.HasValue && healthProfile.WeightKg.HasValue
                && !string.IsNullOrWhiteSpace(healthProfile.ActivityLevel))
            {
                steps.Add("HealthProfile");
            }

            if (hasAllergies || allergiesAcknowledged)
            {
                steps.Add("Allergies");
            }

            if (!string.IsNullOrWhiteSpace(healthProfile.Goal) && healthProfile.TargetCalories.HasValue)
            {
                steps.Add("Goal");
            }

            if (UserAiProfilePreferencesHelper.HasMeaningfulAiProfile(
                aiProfile?.Preferences,
                aiProfile?.EatingPattern,
                aiProfile?.DislikedFoods))
            {
                steps.Add("UserAiProfile");
            }

            if (hasNutritionSnapshot)
            {
                steps.Add("NutritionSnapshot");
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
