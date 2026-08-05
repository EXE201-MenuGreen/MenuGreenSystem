using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Helpers;
using MenuGreen.BusinessLogicLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface ICacheInvalidationService
    {
        Task InvalidateUserCacheAsync(Guid userId);

        Task InvalidateCatalogCacheAsync();

        Task InvalidateRecipeCacheAsync(Guid recipeId);

        Task InvalidateFoodCacheAsync(Guid foodId);

        Task InvalidateAllUserDataAsync(Guid userId);
    }
}
