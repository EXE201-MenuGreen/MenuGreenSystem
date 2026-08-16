using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IAdminMembershipService
    {
        Task<AdminUserMembershipResponse> GetAsync(Guid userId);
        Task<AdminUserMembershipResponse> GrantAsync(Guid adminUserId, Guid userId, AdminGrantMembershipRequest request);
        Task<AdminUserMembershipResponse> ExtendAsync(Guid adminUserId, Guid userId, Guid subscriptionId, AdminExtendMembershipRequest request);
        Task<AdminUserMembershipResponse> RevokeAsync(Guid adminUserId, Guid userId, Guid subscriptionId, AdminRevokeMembershipRequest request);
    }
}
