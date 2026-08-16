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
        private static readonly string[] AssignableRoles = ["User", "Coach", "Admin"];
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
            var subscriptions = (await _unitOfWork.UserSubscriptions.GetAllAsync()).ToList();
            var plans = (await _unitOfWork.SubscriptionPlans.GetAllAsync()).ToDictionary(x => x.Id);
            var now = DateTime.UtcNow;

            var result = users.Select(u => 
            {
                var p = profiles.FirstOrDefault(prof => prof.UserId == u.Id);
                var r = roles.FirstOrDefault(role => role.Id == u.RoleId);
                var userSubscriptions = subscriptions.Where(x => x.UserId == u.Id).ToList();
                var snapshots = userSubscriptions.Select(subscription =>
                {
                    plans.TryGetValue(subscription.SubscriptionPlanId, out var plan);
                    return new SubscriptionAccessSnapshot(
                        subscription.Status,
                        subscription.StartDate,
                        subscription.EndDate,
                        plan?.FeatureGroup,
                        plan?.Name);
                });
                var access = FeatureAccessResolver.Resolve(snapshots, now);
                var hasActive = userSubscriptions.Any(x =>
                    string.Equals(x.Status, "Active", StringComparison.OrdinalIgnoreCase)
                    && x.StartDate <= now
                    && x.EndDate > now);
                var latest = userSubscriptions.OrderByDescending(x => x.UpdatedAt).FirstOrDefault();
                var membershipStatus = GetMembershipStatus(latest, hasActive, now);
                return new UserAdminResponse
                {
                    Id = u.Id,
                    Email = u.Email,
                    FullName = p?.FullName ?? "",
                    Role = r?.Name ?? "Free",
                    MembershipTier = hasActive ? access.Tier : "none",
                    MembershipStatus = membershipStatus,
                    Entitlements = access.Entitlements,
                    MembershipExpiresAt = access.ExpiresAt,
                    IsActive = u.IsActive,
                    EmailConfirmed = u.EmailConfirmed,
                    CreatedAt = u.CreatedAt,
                    LastSignInAt = u.LastSignInAt
                };
            }).ToList();

            return result;
        }

        private static string GetMembershipStatus(
            MenuGreen.DataAccessLayer.Entities.UserSubscription? latest,
            bool hasActive,
            DateTime now)
        {
            if (hasActive) return "Active";
            if (latest == null) return "NoSubscription";

            if (string.Equals(latest.Status, "Active", StringComparison.OrdinalIgnoreCase))
            {
                if (latest.StartDate > now) return "Scheduled";
                if (latest.EndDate <= now) return "Expired";
            }

            return string.IsNullOrWhiteSpace(latest.Status)
                ? "NoSubscription"
                : latest.Status;
        }

        public async Task<UserAdminResponse> GetUserByIdAsync(Guid userId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) throw new Exception("Account not found.");
            return (await GetAllUsersAsync()).First(x => x.Id == userId);
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

            var canonicalRole = AssignableRoles.FirstOrDefault(role =>
                string.Equals(role, newRole?.Trim(), StringComparison.OrdinalIgnoreCase));
            if (canonicalRole == null)
                throw new ArgumentException("Role must be User, Coach, or Admin.", nameof(newRole));

            var roles = await _unitOfWork.Roles.FindAsync(r =>
                r.Name.ToLower() == canonicalRole.ToLower());
            var role = roles.FirstOrDefault()
                ?? throw new Exception($"Configured role '{canonicalRole}' was not found.");

            user.RoleId = role.Id;
            user.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();

            return true;
        }
    }
}
