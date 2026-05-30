using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class AdminUserService : IAdminUserService
    {
        private readonly IUnitOfWork _unitOfWork;

        public AdminUserService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<IEnumerable<UserAdminResponse>> GetAllAsync()
        {
            var users = await _unitOfWork.Users.GetAllAsync();
            return users.Select(Map).OrderByDescending(x => x.CreatedAt).ToList();
        }

        public async Task<UserAdminResponse> GetByIdAsync(Guid userId)
        {
            var user = await GetUserOrThrowAsync(userId);
            return Map(user);
        }

        public async Task<UserAdminResponse> LockAsync(Guid userId)
        {
            var user = await GetUserOrThrowAsync(userId);
            user.IsActive = false;
            user.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();
            return Map(user);
        }

        public async Task<UserAdminResponse> UnlockAsync(Guid userId)
        {
            var user = await GetUserOrThrowAsync(userId);
            user.IsActive = true;
            user.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();
            return Map(user);
        }

        private async Task<User> GetUserOrThrowAsync(Guid userId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null)
            {
                throw new Exception("User not found.");
            }

            return user;
        }

        private async Task<string> GetRoleNameAsync(Guid roleId)
        {
            var role = await _unitOfWork.Roles.GetByIdAsync(roleId);
            return role?.Name ?? string.Empty;
        }

        private static UserAdminResponse Map(User user)
        {
            return new UserAdminResponse
            {
                Id = user.Id,
                Email = user.Email,
                FullName = user.Profile?.FullName ?? string.Empty,
                Role = user.Role?.Name ?? string.Empty,
                IsActive = user.IsActive,
                EmailConfirmed = user.EmailConfirmed,
                CreatedAt = new DateTimeOffset(user.CreatedAt, TimeSpan.Zero),
                LastSignInAt = user.LastSignInAt.HasValue ? new DateTimeOffset(user.LastSignInAt.Value, TimeSpan.Zero) : null
            };
        }
    }
}
