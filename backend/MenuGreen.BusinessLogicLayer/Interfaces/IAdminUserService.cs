using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IAdminUserService
    {
        Task<IEnumerable<UserAdminResponse>> GetAllAsync();
        Task<UserAdminResponse> GetByIdAsync(Guid userId);
        Task<UserAdminResponse> LockAsync(Guid userId);
        Task<UserAdminResponse> UnlockAsync(Guid userId);
    }
}
