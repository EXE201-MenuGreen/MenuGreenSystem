using System;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
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
    }
}
