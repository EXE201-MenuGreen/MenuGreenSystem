using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;

namespace MenuGreen.API.Authorization
{
    public class EntitlementHandler : AuthorizationHandler<EntitlementRequirement>
    {
        private readonly IFeatureAccessService _featureAccessService;

        public EntitlementHandler(IFeatureAccessService featureAccessService)
        {
            _featureAccessService = featureAccessService;
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

            if (
                await _featureAccessService.HasEntitlementAsync(
                    userId,
                    requirement.RequiredEntitlement
                )
            )
            {
                context.Succeed(requirement);
            }
        }
    }
}
