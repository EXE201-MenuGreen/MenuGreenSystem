using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class SubscriptionPlanService : ISubscriptionPlanService
    {
        private readonly IUnitOfWork _unitOfWork;

        public SubscriptionPlanService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<IEnumerable<SubscriptionPlanResponse>> GetAllAsync(bool? isActive = null)
        {
            var plans = await _unitOfWork.SubscriptionPlans.GetAllAsync();
            if (isActive.HasValue)
            {
                plans = plans.Where(x => x.IsActive == isActive.Value);
            }

            return plans.Select(Map).OrderBy(x => x.PriceVnd).ToList();
        }

        public async Task<SubscriptionPlanResponse> GetByIdAsync(Guid id)
        {
            var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(id) ?? throw new Exception("Subscription plan not found.");
            return Map(plan);
        }

        public async Task<SubscriptionPlanFeaturesResponse> GetPlanFeaturesAsync(Guid id)
        {
            var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(id) ?? throw new Exception("Subscription plan not found.");
            
            var features = ParseFeatures(plan.FeatureGroup);
            
            return new SubscriptionPlanFeaturesResponse
            {
                PlanId = plan.Id,
                PlanName = plan.Name ?? string.Empty,
                FeatureGroup = plan.FeatureGroup,
                Features = features
            };
        }

        public async Task<SubscriptionPlanStatusResponse> GetPlanStatusAsync(Guid id)
        {
            var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(id) ?? throw new Exception("Subscription plan not found.");
            
            return new SubscriptionPlanStatusResponse
            {
                PlanId = plan.Id,
                PlanName = plan.Name ?? string.Empty,
                IsActive = plan.IsActive ?? false,
                StatusMessage = (plan.IsActive ?? false) ? "Plan is active" : "Plan is disabled"
            };
        }

        public async Task<SubscriptionPlanResponse> CreateAsync(SubscriptionPlanUpsertRequest request)
        {
            ValidateRequest(request);
            EnsureUniqueName(request.Name);

            var plan = new SubscriptionPlan
            {
                Id = Guid.NewGuid(),
                Name = request.Name.Trim(),
                Description = request.Description,
                DurationDays = request.DurationDays,
                PriceVnd = request.PriceVnd,
                FeatureGroup = request.FeatureGroup,
                IsActive = request.IsActive
            };

            await _unitOfWork.SubscriptionPlans.AddAsync(plan);
            await _unitOfWork.CompleteAsync();
            return Map(plan);
        }

        public async Task<SubscriptionPlanResponse> UpdateAsync(Guid id, SubscriptionPlanUpsertRequest request)
        {
            ValidateRequest(request);

            var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(id) ?? throw new Exception("Subscription plan not found.");
            var normalizedName = request.Name.Trim();
            var existing = await _unitOfWork.SubscriptionPlans.FindAsync(x => x.Name == normalizedName && x.Id != id && x.IsActive != false);
            if (existing.Any()) throw new Exception("Subscription plan name already exists.");

            plan.Name = normalizedName;
            plan.Description = request.Description;
            plan.DurationDays = request.DurationDays;
            plan.PriceVnd = request.PriceVnd;
            plan.FeatureGroup = request.FeatureGroup;
            plan.IsActive = request.IsActive;

            _unitOfWork.SubscriptionPlans.Update(plan);
            await _unitOfWork.CompleteAsync();
            return Map(plan);
        }

        public async Task DeleteAsync(Guid id)
        {
            var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(id) ?? throw new Exception("Subscription plan not found.");
            plan.IsActive = false;
            _unitOfWork.SubscriptionPlans.Update(plan);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<SubscriptionPlanResponse> UpdateStatusAsync(Guid id, SubscriptionPlanStatusRequest request)
        {
            var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(id) ?? throw new Exception("Subscription plan not found.");
            plan.IsActive = request.IsActive;
            _unitOfWork.SubscriptionPlans.Update(plan);
            await _unitOfWork.CompleteAsync();
            return Map(plan);
        }

        private void ValidateRequest(SubscriptionPlanUpsertRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Name)) throw new Exception("Name is required.");
            if (request.DurationDays < 0) throw new Exception("DurationDays must be greater than or equal to 0.");
            if (request.PriceVnd < 0) throw new Exception("PriceVnd must be greater than or equal to 0.");
        }

        private void EnsureUniqueName(string name)
        {
            var normalizedName = name.Trim();
            var existing = _unitOfWork.SubscriptionPlans.FindAsync(x => x.Name == normalizedName && x.IsActive != false).GetAwaiter().GetResult();
            if (existing.Any()) throw new Exception("Subscription plan name already exists.");
        }

        private static SubscriptionPlanResponse Map(SubscriptionPlan plan)
        {
            return new SubscriptionPlanResponse
            {
                Id = plan.Id,
                Name = plan.Name ?? string.Empty,
                Description = plan.Description,
                DurationDays = plan.DurationDays ?? 0,
                PriceVnd = plan.PriceVnd ?? 0,
                FeatureGroup = plan.FeatureGroup,
                IsActive = plan.IsActive ?? false,
                TierLabel = GetTierLabel(plan.Name)
            };
        }

        private static string GetTierLabel(string? name)
        {
            var normalized = name?.Trim().ToLowerInvariant();
            return normalized switch
            {
                "free" => "Free",
                "premium" => "Premium",
                "pro" => "Pro",
                _ => "Custom"
            };
        }

        private static List<string> ParseFeatures(string? featureGroup)
        {
            if (string.IsNullOrWhiteSpace(featureGroup))
            {
                return new List<string>();
            }

            // Giả sử FeatureGroup có format: "feature1,feature2,feature3" hoặc "feature1;feature2;feature3"
            return featureGroup
                .Split(new[] { ',', ';', '|' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(f => f.Trim())
                .Where(f => !string.IsNullOrWhiteSpace(f))
                .ToList();
        }
    }
}
