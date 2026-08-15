using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class UserService : IUserService
    {
        private readonly IUnitOfWork _unitOfWork;

        public UserService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<bool> ChangePasswordAsync(Guid userId, ChangePasswordRequest request)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) throw new Exception("Account not found.");

            // Verify old password
            bool isOldPasswordValid = BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash);
            if (!isOldPasswordValid)
            {
                throw new Exception("Current password is incorrect.");
            }

            // Hash and save new password
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            user.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();

            return true;
        }

        public async Task<IEnumerable<UserAdminResponse>> GetAllUsersAsync()
        {
            var users = await _unitOfWork.Users.GetAllAsync();
            var profiles = await _unitOfWork.Profiles.GetAllAsync();
            var roles = await _unitOfWork.Roles.GetAllAsync();

            var result = users.Select(u => 
            {
                var p = profiles.FirstOrDefault(prof => prof.UserId == u.Id);
                var r = roles.FirstOrDefault(role => role.Id == u.RoleId);
                return new UserAdminResponse
                {
                    Id = u.Id,
                    Email = u.Email,
                    FullName = p?.FullName ?? "",
                    Role = r?.Name ?? "Free",
                    IsActive = u.IsActive,
                    EmailConfirmed = u.EmailConfirmed,
                    CreatedAt = u.CreatedAt,
                    LastSignInAt = u.LastSignInAt
                };
            }).ToList();

            return result;
        }

        public async Task<UserAdminResponse> GetUserByIdAsync(Guid userId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) throw new Exception("Account not found.");

            var profile = await _unitOfWork.Profiles.GetByIdAsync(userId);
            var roleName = "Free";
            var roleEntities = await _unitOfWork.Roles.FindAsync(r => r.Id == user.RoleId);
            if (roleEntities.Any())
            {
                roleName = roleEntities.First().Name;
            }

            return new UserAdminResponse
            {
                Id = user.Id,
                Email = user.Email,
                FullName = profile?.FullName ?? "",
                Role = roleName,
                IsActive = user.IsActive,
                EmailConfirmed = user.EmailConfirmed,
                CreatedAt = user.CreatedAt,
                LastSignInAt = user.LastSignInAt
            };
        }

        public async Task<bool> ToggleUserStatusAsync(Guid userId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) throw new Exception("Account not found.");

            user.IsActive = !user.IsActive; // Toggle status
            user.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();

            return user.IsActive;
        }

        public async Task<bool> LockUserAsync(Guid userId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) throw new Exception("Account not found.");

            user.IsActive = false;
            user.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();

            return user.IsActive;
        }

        public async Task<bool> UnlockUserAsync(Guid userId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) throw new Exception("Account not found.");

            user.IsActive = true;
            user.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();

            return user.IsActive;
        }

        public async Task<bool> AssignRoleAsync(Guid userId, string newRole)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) throw new Exception("Account not found.");

            var roles = await _unitOfWork.Roles.FindAsync(r => r.Name.ToLower() == newRole.ToLower());
            var role = roles.FirstOrDefault();
            if (role == null)
            {
                role = new Role
                {
                    Id = Guid.NewGuid(),
                    Name = newRole,
                    Description = $"{newRole} Role",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.Roles.AddAsync(role);
                await _unitOfWork.CompleteAsync();
            }

            user.RoleId = role.Id;
            user.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();

            return true;
        }
    }
}
