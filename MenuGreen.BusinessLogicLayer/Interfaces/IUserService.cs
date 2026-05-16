using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IUserService
    {
        Task<bool> ChangePasswordAsync(Guid userId, ChangePasswordRequest request);
        Task<IEnumerable<UserAdminResponse>> GetAllUsersAsync();
        Task<UserAdminResponse> GetUserByIdAsync(Guid userId);
        Task<bool> ToggleUserStatusAsync(Guid userId);
        Task<bool> AssignRoleAsync(Guid userId, string newRole);
    }
}
