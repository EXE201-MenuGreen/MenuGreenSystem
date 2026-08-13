using System;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.BusinessLogicLayer.Helpers;
using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class NutritionSnapshotService : INutritionSnapshotService
    {
        private readonly ApplicationDbContext _db;

        public NutritionSnapshotService(ApplicationDbContext db)
        {
            _db = db;
        }

        public async Task<bool> EnsureInitialSnapshotAsync(Guid userId, DateOnly? date = null)
        {
            // Guard: skip if user doesn't exist (e.g. Coach accounts without HealthProfile)
            var userExists = await _db.Users.AsNoTracking().AnyAsync(u => u.Id == userId);
            if (!userExists) return false;

            var snapshotDate = date ?? DateOnly.FromDateTime(DateTime.UtcNow);
            var exists = await _db.NutritionSnapshots.AsNoTracking()
                .AnyAsync(x => x.UserId == userId && x.SnapshotDate == snapshotDate);

            if (exists)
            {
                return false;
            }

            var health = await _db.HealthProfiles.AsNoTracking()
                .FirstOrDefaultAsync(x => x.UserId == userId);

            var snapshot = new NutritionSnapshot
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                SnapshotDate = snapshotDate,
                TotalCalories = 0,
                TotalProteinG = 0,
                TotalCarbsG = 0,
                TotalFatG = 0,
                GoalCompletionPercent = health?.TargetCalories > 0 ? 0 : null
            };

            await _db.NutritionSnapshots.AddAsync(snapshot);
            await _db.SaveChangesAsync();
            return true;
        }

        public async Task SyncDailySnapshotAsync(Guid userId, DateOnly date)
        {
            // Guard: skip if user doesn't exist (e.g. Coach accounts, deleted users)
            var userExists = await _db.Users.AsNoTracking().AnyAsync(u => u.Id == userId);
            if (!userExists) return;
            var startUtc = VietnamTime.RangeStartUtc(date.AddDays(-1));
            var endUtc = VietnamTime.RangeEndUtc(date.AddDays(1));
            var logs = (await _db.MealLogs.AsNoTracking()
                .Where(x => x.UserId == userId && x.LoggedAt.HasValue
                    && x.LoggedAt.Value >= startUtc
                    && x.LoggedAt.Value <= endUtc)
                .ToListAsync())
                .Where(x => x.LoggedAt.HasValue
                    && VietnamTime.ToDate(x.LoggedAt.Value) == date)
                .ToList();

            var health = await _db.HealthProfiles.AsNoTracking()
                .FirstOrDefaultAsync(x => x.UserId == userId);

            var totalCalories = logs.Sum(x => x.CaloriesKcal ?? 0);
            var totalProtein = logs.Sum(x => x.ProteinG ?? 0);
            var totalCarbs = logs.Sum(x => x.CarbsG ?? 0);
            var totalFat = logs.Sum(x => x.FatG ?? 0);
            var targetCalories = health?.TargetCalories ?? 0;
            decimal? goalPercent = targetCalories > 0
                ? Math.Round(totalCalories / targetCalories * 100m, 2)
                : null;

            var snapshot = await _db.NutritionSnapshots
                .FirstOrDefaultAsync(x => x.UserId == userId && x.SnapshotDate == date);

            if (snapshot == null)
            {
                snapshot = new NutritionSnapshot
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    SnapshotDate = date
                };
                await _db.NutritionSnapshots.AddAsync(snapshot);
            }

            snapshot.TotalCalories = totalCalories;
            snapshot.TotalProteinG = totalProtein;
            snapshot.TotalCarbsG = totalCarbs;
            snapshot.TotalFatG = totalFat;
            snapshot.GoalCompletionPercent = goalPercent;

            await _db.SaveChangesAsync();
        }
    }
}
