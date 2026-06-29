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
    public class GoalDriftService : IGoalDriftService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INotificationService _notificationService;

        public GoalDriftService(IUnitOfWork unitOfWork, INotificationService notificationService)
        {
            _unitOfWork = unitOfWork;
            _notificationService = notificationService;
        }

        public async Task<IEnumerable<GoalDriftAlertResponse>> GetAlertsAsync(Guid userId)
        {
            var alerts = await _unitOfWork.GoalDriftAlerts.FindAsync(a => a.UserId == userId);
            return alerts.OrderByDescending(a => a.CreatedAt).Select(MapToResponse);
        }

        public async Task<GoalDriftAlertResponse?> GetCurrentAlertAsync(Guid userId)
        {
            var alerts = await _unitOfWork.GoalDriftAlerts.FindAsync(a => a.UserId == userId && !a.IsAcknowledged && !a.IsDismissed);
            var latest = alerts.OrderByDescending(a => a.CreatedAt).FirstOrDefault();
            return latest != null ? MapToResponse(latest) : null;
        }

        public async Task<GoalDriftSummaryResponse> GetSummaryAsync(Guid userId)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var startDate = today.AddDays(-7);

            var healthProfile = (await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId)).FirstOrDefault();
            var targetCal = healthProfile?.TargetCalories ?? 0;

            var cutoffDate = DateTime.UtcNow.AddDays(-7);
            var mealLogs = await _unitOfWork.MealLogs.FindAsync(ml => ml.UserId == userId && ml.LoggedAt >= cutoffDate);
            var totalCalories = mealLogs.Sum(ml => ml.CaloriesKcal ?? 0m);
            var avgCalories = totalCalories / 7m;

            var calDeviationPercent = targetCal > 0 ? ((avgCalories - (decimal)targetCal) / (decimal)targetCal) * 100m : 0m;

            var activeAlertEntities = await _unitOfWork.GoalDriftAlerts.FindAsync(a => a.UserId == userId && !a.IsAcknowledged && !a.IsDismissed);
            var activeAlertsSummary = activeAlertEntities.OrderByDescending(a => a.CreatedAt).Select(a => a.Message).ToList();

            return new GoalDriftSummaryResponse
            {
                UserId = userId,
                StartDate = startDate,
                EndDate = today,
                AvgCaloriesKcal = Math.Round(avgCalories, 1),
                TargetCaloriesKcal = targetCal,
                CalorieDeviationPercent = Math.Round(calDeviationPercent, 1),
                ActiveAlertsSummary = activeAlertsSummary
            };
        }

        public async Task<GoalDriftAlertResponse?> RecalculateDriftAsync(Guid userId)
        {
            var healthProfile = (await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId)).FirstOrDefault();
            if (healthProfile == null)
            {
                return null;
            }

            var cutoffDate = DateTime.UtcNow.AddDays(-7);
            var mealLogs = (await _unitOfWork.MealLogs.FindAsync(ml => ml.UserId == userId && ml.LoggedAt >= cutoffDate)).ToList();
            if (!mealLogs.Any())
            {
                return null;
            }

            var days = 7m;
            var avgCal = mealLogs.Sum(ml => ml.CaloriesKcal ?? 0m) / days;
            var avgProtein = mealLogs.Sum(ml => ml.ProteinG ?? 0m) / days;
            var avgCarbs = mealLogs.Sum(ml => ml.CarbsG ?? 0m) / days;
            var avgFat = mealLogs.Sum(ml => ml.FatG ?? 0m) / days;

            var targetCal = (decimal)(healthProfile.TargetCalories ?? 0);
            var targetProtein = (decimal)(healthProfile.TargetProteinG ?? 0);
            var targetCarbs = (decimal)(healthProfile.TargetCarbsG ?? 0);
            var targetFat = (decimal)(healthProfile.TargetFatG ?? 0);

            var calDev = targetCal > 0 ? ((avgCal - targetCal) / targetCal) * 100m : 0m;
            var protDev = targetProtein > 0 ? ((avgProtein - targetProtein) / targetProtein) * 100m : 0m;
            var carbDev = targetCarbs > 0 ? ((avgCarbs - targetCarbs) / targetCarbs) * 100m : 0m;
            var fatDev = targetFat > 0 ? ((avgFat - targetFat) / targetFat) * 100m : 0m;

            var hasCalDrift = targetCal > 0 && Math.Abs(calDev) > 8m;
            var hasMacroDrift = (targetProtein > 0 && Math.Abs(protDev) > 15m) ||
                                (targetCarbs > 0 && Math.Abs(carbDev) > 15m) ||
                                (targetFat > 0 && Math.Abs(fatDev) > 15m);

            if (!hasCalDrift && !hasMacroDrift)
            {
                return null;
            }

            // Dismiss old active alerts to avoid duplicate spam
            var activeAlerts = await _unitOfWork.GoalDriftAlerts.FindAsync(a => a.UserId == userId && !a.IsAcknowledged && !a.IsDismissed);
            foreach (var activeAlert in activeAlerts)
            {
                activeAlert.IsDismissed = true;
                activeAlert.DismissedAt = DateTime.UtcNow;
                _unitOfWork.GoalDriftAlerts.Update(activeAlert);
            }

            GoalDriftAlert? representativeAlert = null;

            if (hasCalDrift)
            {
                var direction = calDev > 0 ? "exceeds" : "is below";
                representativeAlert = new GoalDriftAlert
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    AlertType = "CalorieDrift",
                    AverageValue = avgCal,
                    TargetValue = targetCal,
                    PercentDeviation = Math.Round(calDev, 1),
                    Message = $"Your average calorie intake over the past 7 days ({Math.Round(avgCal, 0)} kcal) {direction} your target by {Math.Round(Math.Abs(calDev), 1)}% ({targetCal} kcal).",
                    CreatedAt = DateTime.UtcNow
                };
                await _unitOfWork.GoalDriftAlerts.AddAsync(representativeAlert);
            }

            if (hasMacroDrift)
            {
                var details = new List<string>();
                decimal maxDeviation = 0m;
                decimal representativeDev = 0m;
                decimal repAverage = 0m;
                decimal repTarget = 0m;

                if (targetProtein > 0 && Math.Abs(protDev) > 15m)
                {
                    details.Add($"Protein {(protDev > 0 ? "excess" : "deficit")} {Math.Round(Math.Abs(protDev), 1)}%");
                    if (Math.Abs(protDev) > maxDeviation)
                    {
                        maxDeviation = Math.Abs(protDev);
                        representativeDev = protDev;
                        repAverage = avgProtein;
                        repTarget = targetProtein;
                    }
                }
                if (targetCarbs > 0 && Math.Abs(carbDev) > 15m)
                {
                    details.Add($"Carbs {(carbDev > 0 ? "excess" : "deficit")} {Math.Round(Math.Abs(carbDev), 1)}%");
                    if (Math.Abs(carbDev) > maxDeviation)
                    {
                        maxDeviation = Math.Abs(carbDev);
                        representativeDev = carbDev;
                        repAverage = avgCarbs;
                        repTarget = targetCarbs;
                    }
                }
                if (targetFat > 0 && Math.Abs(fatDev) > 15m)
                {
                    details.Add($"Fat {(fatDev > 0 ? "excess" : "deficit")} {Math.Round(Math.Abs(fatDev), 1)}%");
                    if (Math.Abs(fatDev) > maxDeviation)
                    {
                        maxDeviation = Math.Abs(fatDev);
                        representativeDev = fatDev;
                        repAverage = avgFat;
                        repTarget = targetFat;
                    }
                }

                var macroAlert = new GoalDriftAlert
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    AlertType = "MacroDrift",
                    AverageValue = repAverage,
                    TargetValue = repTarget,
                    PercentDeviation = Math.Round(representativeDev, 1),
                    Message = $"Your average macro nutrient ratio over the past 7 days shows significant deviation: {string.Join(", ", details)}.",
                    CreatedAt = DateTime.UtcNow
                };
                await _unitOfWork.GoalDriftAlerts.AddAsync(macroAlert);

                if (representativeAlert == null)
                {
                    representativeAlert = macroAlert;
                }
            }

            await _unitOfWork.CompleteAsync();

            return MapToResponse(representativeAlert!);
        }

        public async Task AcknowledgeAlertAsync(Guid userId, Guid alertId)
        {
            var alert = await _unitOfWork.GoalDriftAlerts.GetByIdAsync(alertId);
            if (alert == null || alert.UserId != userId)
            {
                throw new KeyNotFoundException("Goal drift alert not found.");
            }

            alert.IsAcknowledged = true;
            alert.AcknowledgedAt = DateTime.UtcNow;

            _unitOfWork.GoalDriftAlerts.Update(alert);
            await _unitOfWork.CompleteAsync();
        }

        public async Task DismissAlertAsync(Guid userId, Guid alertId)
        {
            var alert = await _unitOfWork.GoalDriftAlerts.GetByIdAsync(alertId);
            if (alert == null || alert.UserId != userId)
            {
                throw new KeyNotFoundException("Goal drift alert not found.");
            }

            alert.IsDismissed = true;
            alert.DismissedAt = DateTime.UtcNow;

            _unitOfWork.GoalDriftAlerts.Update(alert);
            await _unitOfWork.CompleteAsync();
        }

        public async Task CreateNudgeAsync(Guid userId, Guid alertId)
        {
            var alert = await _unitOfWork.GoalDriftAlerts.GetByIdAsync(alertId);
            if (alert == null || alert.UserId != userId)
            {
                throw new KeyNotFoundException("Goal drift alert not found.");
            }

            await _notificationService.SendAsync(new NotificationSendRequest
            {
                UserId = userId,
                Type = "GoalDriftNudge",
                Title = "Điều chỉnh mục tiêu dinh dưỡng",
                Body = alert.Message
            });
        }

        private static GoalDriftAlertResponse MapToResponse(GoalDriftAlert alert)
        {
            return new GoalDriftAlertResponse
            {
                Id = alert.Id,
                UserId = alert.UserId,
                AlertType = alert.AlertType,
                Message = alert.Message,
                AverageValue = alert.AverageValue,
                TargetValue = alert.TargetValue,
                PercentDeviation = alert.PercentDeviation,
                IsAcknowledged = alert.IsAcknowledged,
                IsDismissed = alert.IsDismissed,
                CreatedAt = alert.CreatedAt,
                AcknowledgedAt = alert.AcknowledgedAt,
                DismissedAt = alert.DismissedAt
            };
        }
    }
}
