using System;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class OnboardingService : IOnboardingService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IProfileService _profileService;
        private readonly IHealthProfileService _healthProfileService;
        private readonly INutritionSnapshotService _nutritionSnapshotService;

        public OnboardingService(
            IUnitOfWork unitOfWork,
            IProfileService profileService,
            IHealthProfileService healthProfileService,
            INutritionSnapshotService nutritionSnapshotService
        )
        {
            _unitOfWork = unitOfWork;
            _profileService = profileService;
            _healthProfileService = healthProfileService;
            _nutritionSnapshotService = nutritionSnapshotService;
        }

        public async Task<OnboardingCompleteResponse> CompleteAsync(
            Guid userId,
            CompleteOnboardingRequest? request = null
        )
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId)
                ?? throw new Exception("User not found.");
            var roleName = (await _unitOfWork.Roles.FindAsync(r => r.Id == user.RoleId))
                .FirstOrDefault()?.Name ?? string.Empty;
            var isCoach = string.Equals(roleName, "Coach", StringComparison.OrdinalIgnoreCase);

            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(h =>
                h.UserId == userId
            );
            var health = healthProfiles.FirstOrDefault();

            // Coach/PT không cần health baseline — auto tạo placeholder nếu thiếu.
            if (health == null)
            {
                if (!isCoach)
                {
                    throw new Exception(
                        "Please complete health profile before finishing onboarding."
                    );
                }
                health = new MenuGreen.DataAccessLayer.Entities.HealthProfile
                {
                    UserId = userId,
                    HeightCm = 170,
                    WeightKg = 65,
                    ActivityLevel = "sedentary",
                    Goal = "maintain weight",
                    TargetCalories = 2000,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                };
                await _unitOfWork.HealthProfiles.AddAsync(health);
                await _unitOfWork.CompleteAsync();
            }
            else if (!isCoach &&
                (!health.HeightCm.HasValue || !health.WeightKg.HasValue))
            {
                throw new Exception("Height and weight are required.");
            }
            else if (!health.HeightCm.HasValue || !health.WeightKg.HasValue)
            {
                health.HeightCm ??= 170;
                health.WeightKg ??= 65;
                health.ActivityLevel = string.IsNullOrWhiteSpace(health.ActivityLevel)
                    ? "sedentary"
                    : health.ActivityLevel;
                health.Goal = string.IsNullOrWhiteSpace(health.Goal)
                    ? "maintain weight"
                    : health.Goal;
                if (health.TargetCalories == null || health.TargetCalories <= 0)
                {
                    health.TargetCalories = 2000;
                }
                HealthProfileMetricsCalculator.ApplyMacroTargets(health);
                health.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.HealthProfiles.Update(health);
                await _unitOfWork.CompleteAsync();
            }

            // The Office journey starts with a conservative activity baseline and
            // a ready-to-use reminder profile. Office access does not require payment.
            var aiProfile = (
                await _unitOfWork.UserAiProfiles.FindAsync(x => x.UserId == userId)
            ).FirstOrDefault();
            if (
                string.Equals(
                    aiProfile?.EatingPattern?.Trim().Trim('"'),
                    "office",
                    StringComparison.OrdinalIgnoreCase
                )
            )
            {
                health.ActivityLevel = "sedentary";
                HealthProfileMetricsCalculator.ApplyMacroTargets(health);
                health.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.HealthProfiles.Update(health);

                var reminderProfile = (
                    await _unitOfWork.ReminderProfiles.FindAsync(x => x.UserId == userId)
                ).FirstOrDefault();
                if (reminderProfile == null)
                {
                    await _unitOfWork.ReminderProfiles.AddAsync(
                        new MenuGreen.DataAccessLayer.Entities.ReminderProfile
                        {
                            Id = Guid.NewGuid(),
                            UserId = userId,
                            OptimalBreakfastTime = new TimeOnly(8, 0),
                            OptimalLunchTime = new TimeOnly(12, 0),
                            OptimalDinnerTime = new TimeOnly(19, 0),
                            LastRecalculatedAt = DateTime.UtcNow,
                        }
                    );
                }
                await _unitOfWork.CompleteAsync();
            }

            if (request?.TargetCalories is int target && target >= 800 && target <= 6000)
            {
                health.TargetCalories = target;
                HealthProfileMetricsCalculator.ApplyMacroTargets(health);
                health.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.HealthProfiles.Update(health);
                await _unitOfWork.CompleteAsync();
            }

            var snapshotCreated = await _nutritionSnapshotService.EnsureInitialSnapshotAsync(
                userId
            );
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            await _nutritionSnapshotService.SyncDailySnapshotAsync(userId, today);
            var completion = await _profileService.GetCompletionAsync(userId);
            var healthResponse = await _healthProfileService.GetAsync(userId);

            return new OnboardingCompleteResponse
            {
                SnapshotCreated = snapshotCreated,
                Completion = completion,
                HealthProfile = healthResponse,
            };
        }
    }
}
