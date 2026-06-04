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
            INutritionSnapshotService nutritionSnapshotService)
        {
            _unitOfWork = unitOfWork;
            _profileService = profileService;
            _healthProfileService = healthProfileService;
            _nutritionSnapshotService = nutritionSnapshotService;
        }

        public async Task<OnboardingCompleteResponse> CompleteAsync(Guid userId, CompleteOnboardingRequest? request = null)
        {
            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(h => h.UserId == userId);
            var health = healthProfiles.FirstOrDefault()
                ?? throw new Exception("Vui lòng nhập thông số sức khỏe trước khi hoàn tất thiết lập.");

            if (!health.HeightCm.HasValue || !health.WeightKg.HasValue)
            {
                throw new Exception("Chiều cao và cân nặng là bắt buộc.");
            }

            if (request?.TargetCalories is int target && target >= 800 && target <= 6000)
            {
                health.TargetCalories = target;
                HealthProfileMetricsCalculator.ApplyMacroTargets(health);
                health.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.HealthProfiles.Update(health);
                await _unitOfWork.CompleteAsync();
            }

            var snapshotCreated = await _nutritionSnapshotService.EnsureInitialSnapshotAsync(userId);
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            await _nutritionSnapshotService.SyncDailySnapshotAsync(userId, today);
            var completion = await _profileService.GetCompletionAsync(userId);
            var healthResponse = await _healthProfileService.GetAsync(userId);

            return new OnboardingCompleteResponse
            {
                SnapshotCreated = snapshotCreated,
                Completion = completion,
                HealthProfile = healthResponse
            };
        }
    }
}
