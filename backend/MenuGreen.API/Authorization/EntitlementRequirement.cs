using Microsoft.AspNetCore.Authorization;

namespace MenuGreen.API.Authorization
{
    public class EntitlementRequirement : IAuthorizationRequirement
    {
        public string RequiredEntitlement { get; }

        public EntitlementRequirement(string requiredEntitlement)
        {
            RequiredEntitlement = requiredEntitlement;
        }
    }
}
