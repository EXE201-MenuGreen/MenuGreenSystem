using System;
using System.Threading.Tasks;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface INutritionSnapshotService
    {
        Task<bool> EnsureInitialSnapshotAsync(Guid userId, DateOnly? date = null);

        /// <summary>Upsert daily totals from meal logs (dashboard baseline).</summary>
        Task SyncDailySnapshotAsync(Guid userId, DateOnly date);
    }
}
