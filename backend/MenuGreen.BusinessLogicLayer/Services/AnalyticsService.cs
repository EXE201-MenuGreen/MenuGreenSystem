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
    public class AnalyticsService : IAnalyticsService
    {
        private readonly IUnitOfWork _unitOfWork;

        public AnalyticsService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<ActivityLogResponse> CreateActivityLogAsync(Guid userId, ActivityLogCreateRequest request)
        {
            var entity = new ActivityLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Action = request.Action,
                EntityType = request.EntityType,
                EntityId = request.EntityId,
                Metadata = request.Metadata,
                CreatedAt = request.CreatedAt ?? DateTimeOffset.UtcNow
            };

            await _unitOfWork.ActivityLogs.AddAsync(entity);
            await _unitOfWork.CompleteAsync();
            return Map(entity);
        }

        public async Task<IEnumerable<ActivityLogResponse>> CreateActivityLogsAsync(Guid userId, IEnumerable<ActivityLogCreateRequest> requests)
        {
            var results = new List<ActivityLogResponse>();
            foreach (var request in requests ?? Array.Empty<ActivityLogCreateRequest>())
            {
                results.Add(await CreateActivityLogAsync(userId, request));
            }
            return results;
        }

        public async Task<IEnumerable<ActivityLogResponse>> GetActivityLogsAsync(Guid? userId = null, DateTimeOffset? from = null, DateTimeOffset? to = null, string? action = null)
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            var query = logs.AsQueryable();
            if (userId.HasValue) query = query.Where(x => x.UserId == userId.Value);
            if (from.HasValue) query = query.Where(x => x.CreatedAt >= from.Value);
            if (to.HasValue) query = query.Where(x => x.CreatedAt <= to.Value);
            if (!string.IsNullOrWhiteSpace(action)) query = query.Where(x => x.Action == action);
            return query.OrderByDescending(x => x.CreatedAt).Select(Map).ToList();
        }

        public async Task<ActivityLogResponse> GetActivityLogByIdAsync(Guid id)
        {
            var log = await _unitOfWork.ActivityLogs.GetByIdAsync(id) ?? throw new Exception("Activity log not found.");
            return Map(log);
        }

        public async Task<AnalyticsDashboardResponse> GetDashboardAsync()
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync()).ToList();
            var users = await _unitOfWork.Users.GetAllAsync();
            var last7Days = DateTimeOffset.UtcNow.AddDays(-7);
            return new AnalyticsDashboardResponse
            {
                TotalEvents = logs.Count,
                TotalUsers = users.Count(),
                ActiveUsers = logs.Select(x => x.UserId).Distinct().Count(),
                ActiveUsersLast7Days = logs.Count(x => x.CreatedAt.HasValue && x.CreatedAt >= last7Days),
                MealLoggedEvents = logs.Count(x => string.Equals(x.Action, "meal_logged", StringComparison.OrdinalIgnoreCase)),
                NotificationOpenedEvents = logs.Count(x => string.Equals(x.Action, "notification_opened", StringComparison.OrdinalIgnoreCase)),
                SubscriptionStartedEvents = logs.Count(x => string.Equals(x.Action, "subscription_started", StringComparison.OrdinalIgnoreCase))
            };
        }

        public async Task<AnalyticsSummaryResponse> GetSummaryAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync()).Where(x => x.CreatedAt >= from && x.CreatedAt <= to).ToList();
            return new AnalyticsSummaryResponse
            {
                TotalEvents = logs.Count,
                TotalUsers = logs.Select(x => x.UserId).Distinct().Count(),
                ActiveUsers = logs.Select(x => x.UserId).Distinct().Count(),
                MealLoggedEvents = logs.Count(x => string.Equals(x.Action, "meal_logged", StringComparison.OrdinalIgnoreCase)),
                NotificationOpenedEvents = logs.Count(x => string.Equals(x.Action, "notification_opened", StringComparison.OrdinalIgnoreCase)),
                SubscriptionStartedEvents = logs.Count(x => string.Equals(x.Action, "subscription_started", StringComparison.OrdinalIgnoreCase)),
                From = from,
                To = to
            };
        }

        public async Task<IEnumerable<object>> GetMetricsAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync())
                .Where(x => x.CreatedAt >= from && x.CreatedAt <= to)
                .ToList();

            var grouped = logs
                .GroupBy(x => x.CreatedAt?.Date)
                .OrderBy(x => x.Key)
                .Select(g => new
                {
                    Date = g.Key,
                    Events = g.Count(),
                    Users = g.Select(x => x.UserId).Distinct().Count()
                });

            return grouped.Cast<object>().ToList();
        }

        public async Task<IEnumerable<AnalyticsTopEventResponse>> GetTopEventsAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync())
                .Where(x => x.CreatedAt >= from && x.CreatedAt <= to);

            return logs
                .GroupBy(x => x.Action)
                .OrderByDescending(g => g.Count())
                .Take(10)
                .Select(g => new AnalyticsTopEventResponse
                {
                    Action = g.Key,
                    Count = g.Count()
                })
                .ToList();
        }

        public async Task<IEnumerable<AnalyticsFunnelStepResponse>> GetFunnelAsync()
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync()).ToList();
            var steps = new[] { "register", "onboarding_completed", "health_profile_completed", "meal_logged" };
            return BuildFunnel(logs, steps);
        }

        public async Task<IEnumerable<AnalyticsFunnelStepResponse>> PreviewFunnelAsync(IEnumerable<string> steps)
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync()).ToList();
            var safeSteps = steps?.Where(x => !string.IsNullOrWhiteSpace(x)).ToArray() ?? Array.Empty<string>();
            return BuildFunnel(logs, safeSteps);
        }

        public async Task<IEnumerable<AnalyticsFunnelStepResponse>> GetMealOnboardingFunnelAsync()
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync()).ToList();
            return BuildFunnel(logs, new[] { "register", "onboarding_completed", "meal_logged" });
        }

        public async Task<IEnumerable<AnalyticsFunnelStepResponse>> GetSubscriptionFunnelAsync()
        {
            var logs = (await _unitOfWork.ActivityLogs.GetAllAsync()).ToList();
            return BuildFunnel(logs, new[] { "register", "subscription_started", "subscription_renewed" });
        }

        public async Task<IEnumerable<AnalyticsCohortResponse>> GetCohortAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            return logs
                .Where(x => x.CreatedAt.HasValue)
                .GroupBy(x => x.CreatedAt!.Value.Date)
                .OrderBy(g => g.Key)
                .Select(g => new AnalyticsCohortResponse
                {
                    CohortDate = DateOnly.FromDateTime(g.Key),
                    Users = g.Select(x => x.UserId).Distinct().Count(),
                    Events = g.Count()
                })
                .ToList();
        }

        public async Task<IEnumerable<object>> GetRetentionAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            var users = logs.GroupBy(x => x.UserId).ToList();
            return new[]
            {
                new { Day = "D1", Retention = users.Count(g => g.Any()) },
                new { Day = "D7", Retention = users.Count(g => g.Count() >= 2) },
                new { Day = "D30", Retention = users.Count(g => g.Count() >= 3) }
            }.Cast<object>();
        }

        public async Task<IEnumerable<AnalyticsCohortResponse>> GetCohortBySignupDateAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            return logs.Where(x => string.Equals(x.Action, "register", StringComparison.OrdinalIgnoreCase) && x.CreatedAt.HasValue)
                .GroupBy(x => x.CreatedAt!.Value.Date)
                .Select(g => new AnalyticsCohortResponse
                {
                    CohortDate = DateOnly.FromDateTime(g.Key),
                    Users = g.Select(x => x.UserId).Distinct().Count(),
                    Events = g.Count()
                })
                .ToList();
        }

        public async Task<IEnumerable<AnalyticsCohortResponse>> GetCohortByFirstMealLogAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            return logs.Where(x => string.Equals(x.Action, "meal_logged", StringComparison.OrdinalIgnoreCase) && x.CreatedAt.HasValue)
                .GroupBy(x => x.CreatedAt!.Value.Date)
                .Select(g => new AnalyticsCohortResponse
                {
                    CohortDate = DateOnly.FromDateTime(g.Key),
                    Users = g.Select(x => x.UserId).Distinct().Count(),
                    Events = g.Count()
                })
                .ToList();
        }

        public async Task<IEnumerable<AnalyticsCohortResponse>> GetCohortBySubscriptionAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            return logs.Where(x => !string.IsNullOrWhiteSpace(x.Action) && x.Action.Contains("subscription", StringComparison.OrdinalIgnoreCase) && x.CreatedAt.HasValue)
                .GroupBy(x => x.CreatedAt!.Value.Date)
                .Select(g => new AnalyticsCohortResponse
                {
                    CohortDate = DateOnly.FromDateTime(g.Key),
                    Users = g.Select(x => x.UserId).Distinct().Count(),
                    Events = g.Count()
                })
                .ToList();
        }

        public async Task<IEnumerable<AnalyticsFunnelStepResponse>> GetDropOffAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            var funnel = BuildFunnel(logs, new[] { "register", "onboarding_completed", "health_profile_completed", "meal_logged" }).ToList();

            for (var i = 0; i < funnel.Count; i++)
            {
                funnel[i].DropOffFromPrevious = i == 0 ? 0 : Math.Max(0, funnel[i - 1].Users - funnel[i].Users);
            }

            return funnel;
        }

        public async Task<IEnumerable<object>> GetChurnRiskAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            var threshold = DateTimeOffset.UtcNow.AddDays(-14);
            return logs.GroupBy(x => x.UserId)
                .Select(g => new { UserId = g.Key, Score = g.Max(x => x.CreatedAt) < threshold ? 90 : 10 })
                .OrderByDescending(x => x.Score)
                .Cast<object>()
                .ToList();
        }

        public async Task<IEnumerable<AnalyticsInactiveUserResponse>> GetInactiveUsersAsync()
        {
            var logs = await _unitOfWork.ActivityLogs.GetAllAsync();
            var threshold = DateTimeOffset.UtcNow.AddDays(-30);
            return logs.GroupBy(x => x.UserId)
                .Select(g => new AnalyticsInactiveUserResponse
                {
                    UserId = g.Key,
                    LastActivityAt = g.Max(x => x.CreatedAt)
                })
                .Where(x => !x.LastActivityAt.HasValue || x.LastActivityAt.Value < threshold)
                .ToList();
        }

        public async Task<IEnumerable<object>> GetReactivationOpportunitiesAsync()
        {
            var inactive = await GetInactiveUsersAsync();
            return inactive.Select(x => (object)new { x.UserId, Reason = "No activity in last 30 days" }).ToList();
        }

        public async Task<IEnumerable<ActivityLogResponse>> ExportActivityLogsAsync(DateTimeOffset? from = null, DateTimeOffset? to = null)
        {
            return await GetActivityLogsAsync(null, from, to, null);
        }

        public async Task<IEnumerable<AnalyticsFunnelStepResponse>> ExportFunnelAsync() => await GetFunnelAsync();
        public async Task<IEnumerable<AnalyticsCohortResponse>> ExportCohortAsync() => await GetCohortAsync();

        private static IEnumerable<AnalyticsFunnelStepResponse> BuildFunnel(IEnumerable<ActivityLog> logs, IEnumerable<string> steps)
        {
            var safeSteps = steps.Where(x => !string.IsNullOrWhiteSpace(x)).ToArray();
            var userSets = safeSteps
                .Select(step => logs.Where(x => string.Equals(x.Action, step, StringComparison.OrdinalIgnoreCase))
                    .Select(x => x.UserId)
                    .Distinct()
                    .ToHashSet())
                .ToList();

            return safeSteps.Select((step, index) => new AnalyticsFunnelStepResponse
            {
                Step = step,
                Order = index + 1,
                Users = userSets[index].Count,
                ConversionFromPrevious = index == 0 ? 1d : (userSets[index - 1].Count == 0 ? 0d : (double)userSets[index].Count / userSets[index - 1].Count),
                DropOffFromPrevious = index == 0 ? 0 : Math.Max(0, userSets[index - 1].Count - userSets[index].Count)
            }).ToList();
        }

        private static ActivityLogResponse Map(ActivityLog log) => new()
        {
            Id = log.Id,
            UserId = log.UserId,
            Action = log.Action,
            EntityType = log.EntityType,
            EntityId = log.EntityId,
            Metadata = log.Metadata,
            CreatedAt = log.CreatedAt
        };
    }
}
