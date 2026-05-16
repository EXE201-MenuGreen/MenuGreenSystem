using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Interfaces;

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
            if (user == null) throw new Exception("Không tìm thấy tài khoản.");

            // Verify old password
            bool isOldPasswordValid = BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash);
            if (!isOldPasswordValid)
            {
                throw new Exception("Mật khẩu hiện tại không chính xác.");
            }

            // Hash and save new password
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            user.UpdatedAt = DateTimeOffset.UtcNow;

            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();

            return true;
        }

        public async Task<IEnumerable<UserAdminResponse>> GetAllUsersAsync()
        {
            var users = await _unitOfWork.Users.GetAllAsync();
            var profiles = await _unitOfWork.Profiles.GetAllAsync();

            var result = users.Select(u => 
            {
                var p = profiles.FirstOrDefault(prof => prof.Id == u.Id);
                return new UserAdminResponse
                {
                    Id = u.Id,
                    Email = u.Email,
                    FullName = p?.FullName ?? "",
                    Role = p?.Role ?? "User",
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
            if (user == null) throw new Exception("Không tìm thấy tài khoản.");

            var profile = await _unitOfWork.Profiles.GetByIdAsync(userId);

            return new UserAdminResponse
            {
                Id = user.Id,
                Email = user.Email,
                FullName = profile?.FullName ?? "",
                Role = profile?.Role ?? "User",
                IsActive = user.IsActive,
                EmailConfirmed = user.EmailConfirmed,
                CreatedAt = user.CreatedAt,
                LastSignInAt = user.LastSignInAt
            };
        }

        public async Task<bool> ToggleUserStatusAsync(Guid userId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) throw new Exception("Không tìm thấy tài khoản.");

            user.IsActive = !user.IsActive; // Đảo ngược trạng thái
            user.UpdatedAt = DateTimeOffset.UtcNow;

            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();

            return user.IsActive;
        }

        public async Task<bool> AssignRoleAsync(Guid userId, string newRole)
        {
            var profile = await _unitOfWork.Profiles.GetByIdAsync(userId);
            if (profile == null) throw new Exception("Không tìm thấy thông tin profile của người dùng.");

            profile.Role = newRole;
            profile.UpdatedAt = DateTimeOffset.UtcNow;

            _unitOfWork.Profiles.Update(profile);
            await _unitOfWork.CompleteAsync();

            return true;
        }
    }
}
