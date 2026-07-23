using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IFeatureAccessService
    {
        Task<FeatureAccessResponse> GetAsync(Guid userId);
        Task<bool> HasEntitlementAsync(Guid userId, string entitlement);
    }
}
