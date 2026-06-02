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
        IGenericRepository<Entities.SubscriptionPlan> SubscriptionPlans { get; }
        IGenericRepository<Entities.UserSubscription> UserSubscriptions { get; }
        IGenericRepository<Entities.SubscriptionTransaction> SubscriptionTransactions { get; }
        IGenericRepository<Entities.Payment> Payments { get; }
        IGenericRepository<Entities.SepayTransaction> SepayTransactions { get; }
        
        Task<int> CompleteAsync();
    }
}
