using System;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;

namespace MenuGreen.API.Authorization
{
    public class EntitlementHandler : AuthorizationHandler<EntitlementRequirement>
    {
        private readonly IUnitOfWork _unitOfWork;

        public EntitlementHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        protected override async Task HandleRequirementAsync(
            AuthorizationHandlerContext context,
            EntitlementRequirement requirement)
        {
            // 1. If admin, succeed immediately
            if (context.User.IsInRole("Admin"))
            {
                context.Succeed(requirement);
                return;
            }

            // 2. Extract UserId from claim
            var userIdString = context.User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdString) || !Guid.TryParse(userIdString, out var userId))
            {
                return;
            }

            // 3. Query DB for active subscription
            var now = DateTime.UtcNow;
            var subscriptions = await _unitOfWork.UserSubscriptions.FindAsync(
                s => s.UserId == userId && s.Status == "Active" && s.EndDate > now);

            var activeSub = subscriptions.FirstOrDefault();
            if (activeSub != null)
            {
                var plan = await _unitOfWork.SubscriptionPlans.GetByIdAsync(activeSub.SubscriptionPlanId);
                if (plan != null && !string.IsNullOrEmpty(plan.FeatureGroup))
                {
                    var planName = plan.Name?.ToLowerInvariant() ?? "";
                    var featureGroup = plan.FeatureGroup.Trim().ToLowerInvariant();

                    if (requirement.RequiredEntitlement == "gym_features" || requirement.RequiredEntitlement == "coach_access")
                    {
                        if (planName.Contains("gym") || featureGroup == "pro")
                        {
                            context.Succeed(requirement);
                            return;
                        }
                    }
                    else if (requirement.RequiredEntitlement == "office_features")
                    {
                        if (planName.Contains("office") || featureGroup == "office")
                        {
                            context.Succeed(requirement);
                            return;
                        }
                    }
                }
            }
        }
    }
}
