using System;
using System.Threading.Tasks;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface INutritionSnapshotService
    {
        Task<bool> EnsureInitialSnapshotAsync(Guid userId, DateOnly? date = null);
    }
}
