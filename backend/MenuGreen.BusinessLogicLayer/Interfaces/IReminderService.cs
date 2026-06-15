using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IReminderService
    {
        Task<ReminderProfileResponse> GetProfileAsync(Guid userId);
        Task<ReminderProfileResponse> RecalculateProfileAsync(Guid userId);
        Task<ReminderProfileResponse> UpdateProfileAsync(Guid userId, ReminderProfileUpdateRequest request);
        
        Task<IEnumerable<ScheduledReminderResponse>> GetScheduledRemindersAsync(Guid userId);
        Task<ScheduledReminderResponse> CreateReminderAsync(Guid userId, ScheduledReminderCreateRequest request);
        Task<ScheduledReminderResponse> UpdateReminderAsync(Guid userId, Guid reminderId, ScheduledReminderUpdateRequest request);
        Task DeleteReminderAsync(Guid userId, Guid reminderId);
        Task<ScheduledReminderResponse> SnoozeReminderAsync(Guid userId, Guid reminderId, int minutes);
    }
}
