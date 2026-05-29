namespace MenuGreen.DataAccessLayer.Interfaces
{
    public interface IUnitOfWork : IDisposable
    {
        IGenericRepository<Entities.User> Users { get; }
        IGenericRepository<Entities.Profile> Profiles { get; }
        IGenericRepository<Entities.Session> Sessions { get; }
        IGenericRepository<Entities.Role> Roles { get; }
        IGenericRepository<Entities.HealthProfile> HealthProfiles { get; }
        IGenericRepository<Entities.EmailVerification> EmailVerifications { get; }
        IGenericRepository<Entities.Food> Foods { get; }
        IGenericRepository<Entities.Ingredient> Ingredients { get; }
        IGenericRepository<Entities.Recipe> Recipes { get; }
        IGenericRepository<Entities.RecipeIngredient> RecipeIngredients { get; }
        IGenericRepository<Entities.Allergy> Allergies { get; }
        IGenericRepository<Entities.MealLog> MealLogs { get; }
        IGenericRepository<Entities.WeightLog> WeightLogs { get; }
        IGenericRepository<Entities.MealPlanHeader> MealPlanHeaders { get; }
        IGenericRepository<Entities.MealPlanItem> MealPlanItems { get; }
        IGenericRepository<Entities.Notification> Notifications { get; }
        IGenericRepository<Entities.NotificationSetting> NotificationSettings { get; }
        
        Task<int> CompleteAsync();
    }
}
