using System;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class UserAiProfileService : IUserAiProfileService
    {
        private readonly IUnitOfWork _unitOfWork;

        public UserAiProfileService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<UserAiProfileResponse> GetAsync(Guid userId)
        {
            var entity = await GetOrNullAsync(userId);
            return Map(entity, userId);
        }

        public async Task<UserAiProfileResponse> UpsertAsync(Guid userId, UpdateUserAiProfileRequest request)
        {
            try
            {
                var entity = await GetOrNullAsync(userId);
                var now = DateTime.UtcNow;

                if (entity == null)
                {
                    entity = new UserAiProfile
                    {
                        UserId = userId,
                        UpdatedAt = now
                    };
                    ApplyUpdate(entity, request);
                    await _unitOfWork.UserAiProfiles.AddAsync(entity);
                }
                else
                {
                    ApplyUpdate(entity, request);
                    entity.UpdatedAt = now;
                    _unitOfWork.UserAiProfiles.Update(entity);
                }

                await _unitOfWork.CompleteAsync();
                return Map(entity, userId);
            }
            catch (DbUpdateException ex)
            {
                var friendlyMessage = ToUserFriendlyDbMessage(ex);
                throw new Exception(friendlyMessage, ex);
            }
            catch (InvalidOperationException ex)
            {
                throw new Exception($"Database connection error: {ex.Message}", ex);
            }
            catch (Exception ex)
            {
                throw new Exception($"Failed to save AI profile: {ex.Message}", ex);
            }
        }

        private static void ApplyUpdate(UserAiProfile entity, UpdateUserAiProfileRequest request)
        {
            if (request.EatingPattern != null)
            {
                entity.EatingPattern = NormalizeJsonColumnValue(request.EatingPattern);
            }

            if (request.DislikedFoods != null)
            {
                entity.DislikedFoods = NormalizeJsonColumnValue(request.DislikedFoods);
            }

            if (request.Preferences != null ||
                request.AllergiesAcknowledged.HasValue ||
                request.VietnamRegion != null ||
                request.MealContext != null ||
                request.BudgetPerMealVnd.HasValue ||
                request.PreferredPortionUnits != null)
            {
                entity.Preferences = UserAiProfilePreferencesHelper.MergePreferences(
                    entity.Preferences,
                    request.Preferences,
                    request.AllergiesAcknowledged,
                    request.VietnamRegion,
                    request.MealContext,
                    request.BudgetPerMealVnd,
                    request.PreferredPortionUnits);
            }
        }

        /// <summary>Ensures value is valid JSON for jsonb columns (PostgreSQL).</summary>
        private static string? NormalizeJsonColumnValue(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return null;
            }

            var trimmed = value.Trim();
            try
            {
                using var doc = JsonDocument.Parse(trimmed);
                return trimmed;
            }
            catch (JsonException)
            {
                return JsonSerializer.Serialize(trimmed);
            }
        }

        private static string ToUserFriendlyDbMessage(DbUpdateException ex)
        {
            var inner = ex.InnerException?.Message ?? ex.Message;
            if (inner.Contains("invalid input syntax for type json", StringComparison.OrdinalIgnoreCase))
            {
                return "Invalid preference data. Please try again.";
            }

            if (inner.Contains("user_ai_profile", StringComparison.OrdinalIgnoreCase)
                && inner.Contains("does not exist", StringComparison.OrdinalIgnoreCase))
            {
                return "Database schema is outdated. Please run migrations.";
            }

            if (inner.Contains("FK_user_ai_profile_users_UserId", StringComparison.OrdinalIgnoreCase)
                || inner.Contains("foreign key", StringComparison.OrdinalIgnoreCase))
            {
                return "User profile record not found. Please relogin and try again.";
            }

            return "Cannot save AI profile. Please try again later.";
        }

        private async Task<UserAiProfile?> GetOrNullAsync(Guid userId)
        {
            return (await _unitOfWork.UserAiProfiles.FindAsync(x => x.UserId == userId)).FirstOrDefault();
        }

        private static UserAiProfileResponse Map(UserAiProfile? entity, Guid userId)
        {
            return new UserAiProfileResponse
            {
                UserId = userId,
                Preferences = entity?.Preferences,
                DislikedFoods = entity?.DislikedFoods,
                EatingPattern = ParseEatingPattern(entity?.EatingPattern),
                AllergiesAcknowledged = UserAiProfilePreferencesHelper.TryGetAllergiesAcknowledged(entity?.Preferences),
                VietnamRegion = UserAiProfilePreferencesHelper.TryGetVietnamRegion(entity?.Preferences),
                MealContext = UserAiProfilePreferencesHelper.TryGetMealContext(entity?.Preferences),
                BudgetPerMealVnd = UserAiProfilePreferencesHelper.TryGetBudgetPerMealVnd(entity?.Preferences),
                PreferredPortionUnits = UserAiProfilePreferencesHelper.TryGetPreferredPortionUnits(entity?.Preferences),
                UpdatedAt = entity?.UpdatedAt
            };
        }

        private static string? ParseEatingPattern(string? stored)
        {
            if (string.IsNullOrWhiteSpace(stored))
            {
                return null;
            }

            var trimmed = stored.Trim();
            if (!trimmed.StartsWith("\"", StringComparison.Ordinal))
            {
                return trimmed;
            }

            try
            {
                return JsonSerializer.Deserialize<string>(trimmed);
            }
            catch (JsonException)
            {
                return trimmed;
            }
        }
    }
}
