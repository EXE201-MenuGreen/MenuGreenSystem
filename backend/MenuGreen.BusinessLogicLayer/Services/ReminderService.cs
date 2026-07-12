using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class ReminderService : IReminderService
    {
        private readonly IUnitOfWork _unitOfWork;

        public ReminderService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<ReminderProfileResponse> GetProfileAsync(Guid userId)
        {
            var profile = (await _unitOfWork.ReminderProfiles.FindAsync(x => x.UserId == userId)).FirstOrDefault();
            if (profile == null)
            {
                profile = new ReminderProfile
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    OptimalBreakfastTime = new TimeOnly(8, 0),
                    OptimalLunchTime = new TimeOnly(12, 0),
                    OptimalDinnerTime = new TimeOnly(19, 0),
                    LastRecalculatedAt = DateTime.UtcNow
                };
                await _unitOfWork.ReminderProfiles.AddAsync(profile);
                await _unitOfWork.CompleteAsync();
            }
            return MapProfile(profile);
        }

        public async Task<ReminderProfileResponse> UpdateProfileAsync(Guid userId, ReminderProfileUpdateRequest request)
        {
            var profile = (await _unitOfWork.ReminderProfiles.FindAsync(x => x.UserId == userId)).FirstOrDefault();
            if (profile == null)
            {
                profile = new ReminderProfile
                {
                    Id = Guid.NewGuid(),
                    UserId = userId
                };
                await _unitOfWork.ReminderProfiles.AddAsync(profile);
            }

            profile.OptimalBreakfastTime = TimeOnly.ParseExact(request.OptimalBreakfastTime, "HH:mm");
            profile.OptimalLunchTime = TimeOnly.ParseExact(request.OptimalLunchTime, "HH:mm");
            profile.OptimalDinnerTime = TimeOnly.ParseExact(request.OptimalDinnerTime, "HH:mm");
            profile.LastRecalculatedAt = DateTime.UtcNow;

            _unitOfWork.ReminderProfiles.Update(profile);
            await _unitOfWork.CompleteAsync();
            return MapProfile(profile);
        }

        public async Task<ReminderProfileResponse> RecalculateProfileAsync(Guid userId)
        {
            var logs = await _unitOfWork.MealLogs.FindAsync(x => x.UserId == userId);
            var mealLogs = logs.ToList();

            var profile = (await _unitOfWork.ReminderProfiles.FindAsync(x => x.UserId == userId)).FirstOrDefault();
            if (profile == null)
            {
                profile = new ReminderProfile
                {
                    Id = Guid.NewGuid(),
                    UserId = userId
                };
                await _unitOfWork.ReminderProfiles.AddAsync(profile);
            }

            // Recalculate Breakfast
            var breakfastLogs = mealLogs.Where(x => x.MealType != null && x.MealType.Equals("Breakfast", StringComparison.OrdinalIgnoreCase) && x.LoggedAt.HasValue).ToList();
            if (breakfastLogs.Any())
            {
                var avgTicks = (long)breakfastLogs.Average(x => x.LoggedAt!.Value.TimeOfDay.Ticks);
                profile.OptimalBreakfastTime = TimeOnly.FromTimeSpan(TimeSpan.FromTicks(avgTicks));
            }
            else
            {
                profile.OptimalBreakfastTime = new TimeOnly(8, 0);
            }

            // Recalculate Lunch
            var lunchLogs = mealLogs.Where(x => x.MealType != null && x.MealType.Equals("Lunch", StringComparison.OrdinalIgnoreCase) && x.LoggedAt.HasValue).ToList();
            if (lunchLogs.Any())
            {
                var avgTicks = (long)lunchLogs.Average(x => x.LoggedAt!.Value.TimeOfDay.Ticks);
                profile.OptimalLunchTime = TimeOnly.FromTimeSpan(TimeSpan.FromTicks(avgTicks));
            }
            else
            {
                profile.OptimalLunchTime = new TimeOnly(12, 0);
            }

            // Recalculate Dinner
            var dinnerLogs = mealLogs.Where(x => x.MealType != null && x.MealType.Equals("Dinner", StringComparison.OrdinalIgnoreCase) && x.LoggedAt.HasValue).ToList();
            if (dinnerLogs.Any())
            {
                var avgTicks = (long)dinnerLogs.Average(x => x.LoggedAt!.Value.TimeOfDay.Ticks);
                profile.OptimalDinnerTime = TimeOnly.FromTimeSpan(TimeSpan.FromTicks(avgTicks));
            }
            else
            {
                profile.OptimalDinnerTime = new TimeOnly(19, 0);
            }

            profile.LastRecalculatedAt = DateTime.UtcNow;
            _unitOfWork.ReminderProfiles.Update(profile);
            await _unitOfWork.CompleteAsync();
            return MapProfile(profile);
        }

        public async Task<IEnumerable<ScheduledReminderResponse>> GetScheduledRemindersAsync(Guid userId)
        {
            var now = DateTimeOffset.UtcNow;
            var notifications = await _unitOfWork.Notifications.FindAsync(x => 
                x.UserId == userId && 
                x.ScheduledAt > now && 
                x.SentAt == null);

            return notifications.OrderBy(x => x.ScheduledAt).Select(MapReminder).ToList();
        }

        public async Task<ScheduledReminderResponse> CreateReminderAsync(Guid userId, ScheduledReminderCreateRequest request)
        {
            if (request.ScheduledAt <= DateTimeOffset.UtcNow)
            {
                throw new ArgumentException("Reminder time must be in the future.");
            }

            var notification = new Notification
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = request.Title,
                Body = request.Body,
                Type = request.Type ?? "CUSTOM_REMINDER",
                IsRead = false,
                CreatedAt = DateTimeOffset.UtcNow,
                ScheduledAt = request.ScheduledAt,
                SentAt = null,
                ReadAt = null
            };

            await _unitOfWork.Notifications.AddAsync(notification);
            await _unitOfWork.CompleteAsync();
            return MapReminder(notification);
        }

        public async Task<ScheduledReminderResponse> UpdateReminderAsync(Guid userId, Guid reminderId, ScheduledReminderUpdateRequest request)
        {
            var notification = await GetOwnedReminderAsync(userId, reminderId);
            if (request.Title != null) notification.Title = request.Title;
            if (request.Body != null) notification.Body = request.Body;
            if (request.ScheduledAt.HasValue)
            {
                if (request.ScheduledAt.Value <= DateTimeOffset.UtcNow)
                {
                    throw new ArgumentException("Reminder time must be in the future.");
                }

                notification.ScheduledAt = request.ScheduledAt.Value;
            }

            if (request.IsEnabled.HasValue)
            {
                var isCurrentlyEnabled = !notification.Type?.StartsWith("DISABLED_", StringComparison.OrdinalIgnoreCase) ?? true;
                if (request.IsEnabled.Value && !isCurrentlyEnabled)
                {
                    if (notification.Type != null && notification.Type.StartsWith("DISABLED_", StringComparison.OrdinalIgnoreCase))
                    {
                        notification.Type = notification.Type.Substring("DISABLED_".Length);
                    }
                    else
                    {
                        notification.Type = "CUSTOM_REMINDER";
                    }
                }
                else if (!request.IsEnabled.Value && isCurrentlyEnabled)
                {
                    notification.Type = "DISABLED_" + (notification.Type ?? "CUSTOM_REMINDER");
                }
            }

            _unitOfWork.Notifications.Update(notification);
            await _unitOfWork.CompleteAsync();
            return MapReminder(notification);
        }

        public async Task DeleteReminderAsync(Guid userId, Guid reminderId)
        {
            var notification = await GetOwnedReminderAsync(userId, reminderId);
            _unitOfWork.Notifications.Remove(notification);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<ScheduledReminderResponse> SnoozeReminderAsync(Guid userId, Guid reminderId, int minutes)
        {
            if (minutes is < 1 or > 1440)
            {
                throw new ArgumentException("Snooze duration must be between 1 and 1440 minutes.");
            }

            var notification = await GetOwnedReminderAsync(userId, reminderId);
            if (notification.ScheduledAt.HasValue)
            {
                notification.ScheduledAt = notification.ScheduledAt.Value.AddMinutes(minutes);
            }
            else
            {
                notification.ScheduledAt = DateTimeOffset.UtcNow.AddMinutes(minutes);
            }

            _unitOfWork.Notifications.Update(notification);
            await _unitOfWork.CompleteAsync();
            return MapReminder(notification);
        }

        private static ReminderProfileResponse MapProfile(ReminderProfile profile)
        {
            return new ReminderProfileResponse
            {
                Id = profile.Id,
                UserId = profile.UserId,
                OptimalBreakfastTime = profile.OptimalBreakfastTime.ToString("HH:mm"),
                OptimalLunchTime = profile.OptimalLunchTime.ToString("HH:mm"),
                OptimalDinnerTime = profile.OptimalDinnerTime.ToString("HH:mm"),
                LastRecalculatedAt = profile.LastRecalculatedAt
            };
        }

        private static ScheduledReminderResponse MapReminder(Notification notification)
        {
            var isEnabled = !notification.Type?.StartsWith("DISABLED_", StringComparison.OrdinalIgnoreCase) ?? true;
            return new ScheduledReminderResponse
            {
                Id = notification.Id,
                UserId = notification.UserId,
                Title = notification.Title,
                Body = notification.Body,
                Type = notification.Type,
                IsRead = notification.IsRead,
                CreatedAt = notification.CreatedAt,
                ScheduledAt = notification.ScheduledAt,
                SentAt = notification.SentAt,
                IsEnabled = isEnabled
            };
        }

        private async Task<Notification> GetOwnedReminderAsync(Guid userId, Guid reminderId)
        {
            var notification = await _unitOfWork.Notifications.GetByIdAsync(reminderId);
            if (notification == null) throw new Exception("Reminder not found.");
            if (notification.UserId != userId) throw new Exception("Forbidden.");
            return notification;
        }
    }
}
