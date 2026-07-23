using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class FeatureAccessService : IFeatureAccessService
    {
        private readonly IUnitOfWork _unitOfWork;

        public FeatureAccessService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<FeatureAccessResponse> GetAsync(Guid userId)
        {
            var subscriptions = await _unitOfWork.UserSubscriptions.FindAsync(x => x.UserId == userId);
            var snapshots = new List<SubscriptionAccessSnapshot>();

            foreach (var subscription in subscriptions)
            {
                var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(subscription.SubscriptionPlanId);
                snapshots.Add(
                    new SubscriptionAccessSnapshot(
                        subscription.Status,
                        subscription.StartDate,
                        subscription.EndDate,
                        plan?.FeatureGroup,
                        plan?.Name
                    )
                );
            }

            return FeatureAccessResolver.Resolve(snapshots, DateTime.UtcNow);
        }

        public async Task<bool> HasEntitlementAsync(Guid userId, string entitlement)
        {
            var access = await GetAsync(userId);
            return access.Entitlements.Contains(entitlement, StringComparer.OrdinalIgnoreCase);
        }
    }
}
