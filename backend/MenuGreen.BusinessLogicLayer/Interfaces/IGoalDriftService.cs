using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IGoalDriftService
    {
        Task<IEnumerable<GoalDriftAlertResponse>> GetAlertsAsync(Guid userId);
        Task<GoalDriftAlertResponse?> GetCurrentAlertAsync(Guid userId);
        Task<GoalDriftSummaryResponse> GetSummaryAsync(Guid userId);
        Task<GoalDriftAlertResponse?> RecalculateDriftAsync(Guid userId);
        Task AcknowledgeAlertAsync(Guid userId, Guid alertId);
        Task DismissAlertAsync(Guid userId, Guid alertId);
        Task CreateNudgeAsync(Guid userId, Guid alertId);
    }
}
