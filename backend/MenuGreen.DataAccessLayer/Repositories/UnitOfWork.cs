using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.DataAccessLayer.Repositories
{
    public class UnitOfWork : IUnitOfWork
    {
        private readonly ApplicationDbContext _context;
        private IGenericRepository<Entities.User>? _users;
        private IGenericRepository<Entities.Profile>? _profiles;
        private IGenericRepository<Entities.Session>? _sessions;
        private IGenericRepository<Entities.Role>? _roles;
        private IGenericRepository<Entities.HealthProfile>? _healthProfiles;
        private IGenericRepository<Entities.EmailVerification>? _emailVerifications;
        private IGenericRepository<Entities.Food>? _foods;
        private IGenericRepository<Entities.Ingredient>? _ingredients;
        private IGenericRepository<Entities.Recipe>? _recipes;
        private IGenericRepository<Entities.RecipeIngredient>? _recipeIngredients;
        private IGenericRepository<Entities.Allergy>? _allergies;
        private IGenericRepository<Entities.UserAllergy>? _userAllergies;
        private IGenericRepository<Entities.MealLog>? _mealLogs;
        private IGenericRepository<Entities.WeightLog>? _weightLogs;
        private IGenericRepository<Entities.MealPlanHeader>? _mealPlanHeaders;
        private IGenericRepository<Entities.MealPlanItem>? _mealPlanItems;
        private IGenericRepository<Entities.UserAiProfile>? _userAiProfiles;
        private IGenericRepository<Entities.NutritionSnapshot>? _nutritionSnapshots;
        private IGenericRepository<Entities.RecommendationHistory>? _recommendationHistories;
        private IGenericRepository<Entities.RecommendationFeedback>? _recommendationFeedbacks;
        private IGenericRepository<Entities.Notification>? _notifications;
        private IGenericRepository<Entities.NotificationSetting>? _notificationSettings;
        private IGenericRepository<Entities.SubscriptionPlan>? _subscriptionPlans;
        private IGenericRepository<Entities.UserSubscription>? _userSubscriptions;
        private IGenericRepository<Entities.SubscriptionTransaction>? _subscriptionTransactions;
        private IGenericRepository<Entities.Payment>? _payments;
        private IGenericRepository<Entities.SepayTransaction>? _sepayTransactions;

        public UnitOfWork(ApplicationDbContext context) { _context = context; }

        public IGenericRepository<Entities.User> Users => _users ??= new GenericRepository<Entities.User>(_context);
        public IGenericRepository<Entities.Profile> Profiles => _profiles ??= new GenericRepository<Entities.Profile>(_context);
        public IGenericRepository<Entities.Session> Sessions => _sessions ??= new GenericRepository<Entities.Session>(_context);
        public IGenericRepository<Entities.Role> Roles => _roles ??= new GenericRepository<Entities.Role>(_context);
        public IGenericRepository<Entities.HealthProfile> HealthProfiles => _healthProfiles ??= new GenericRepository<Entities.HealthProfile>(_context);
        public IGenericRepository<Entities.EmailVerification> EmailVerifications => _emailVerifications ??= new GenericRepository<Entities.EmailVerification>(_context);
        public IGenericRepository<Entities.Food> Foods => _foods ??= new GenericRepository<Entities.Food>(_context);
        public IGenericRepository<Entities.Ingredient> Ingredients => _ingredients ??= new GenericRepository<Entities.Ingredient>(_context);
        public IGenericRepository<Entities.Recipe> Recipes => _recipes ??= new GenericRepository<Entities.Recipe>(_context);
        public IGenericRepository<Entities.RecipeIngredient> RecipeIngredients => _recipeIngredients ??= new GenericRepository<Entities.RecipeIngredient>(_context);
        public IGenericRepository<Entities.Allergy> Allergies => _allergies ??= new GenericRepository<Entities.Allergy>(_context);
        public IGenericRepository<Entities.UserAllergy> UserAllergies => _userAllergies ??= new GenericRepository<Entities.UserAllergy>(_context);
        public IGenericRepository<Entities.MealLog> MealLogs => _mealLogs ??= new GenericRepository<Entities.MealLog>(_context);
        public IGenericRepository<Entities.WeightLog> WeightLogs => _weightLogs ??= new GenericRepository<Entities.WeightLog>(_context);
        public IGenericRepository<Entities.MealPlanHeader> MealPlanHeaders => _mealPlanHeaders ??= new GenericRepository<Entities.MealPlanHeader>(_context);
        public IGenericRepository<Entities.MealPlanItem> MealPlanItems => _mealPlanItems ??= new GenericRepository<Entities.MealPlanItem>(_context);
        public IGenericRepository<Entities.UserAiProfile> UserAiProfiles => _userAiProfiles ??= new GenericRepository<Entities.UserAiProfile>(_context);
        public IGenericRepository<Entities.NutritionSnapshot> NutritionSnapshots => _nutritionSnapshots ??= new GenericRepository<Entities.NutritionSnapshot>(_context);
        public IGenericRepository<Entities.RecommendationHistory> RecommendationHistories => _recommendationHistories ??= new GenericRepository<Entities.RecommendationHistory>(_context);
        public IGenericRepository<Entities.RecommendationFeedback> RecommendationFeedbacks => _recommendationFeedbacks ??= new GenericRepository<Entities.RecommendationFeedback>(_context);
        public IGenericRepository<Entities.Notification> Notifications => _notifications ??= new GenericRepository<Entities.Notification>(_context);
        public IGenericRepository<Entities.NotificationSetting> NotificationSettings => _notificationSettings ??= new GenericRepository<Entities.NotificationSetting>(_context);
        public IGenericRepository<Entities.SubscriptionPlan> SubscriptionPlans => _subscriptionPlans ??= new GenericRepository<Entities.SubscriptionPlan>(_context);
        public IGenericRepository<Entities.UserSubscription> UserSubscriptions => _userSubscriptions ??= new GenericRepository<Entities.UserSubscription>(_context);
        public IGenericRepository<Entities.SubscriptionTransaction> SubscriptionTransactions => _subscriptionTransactions ??= new GenericRepository<Entities.SubscriptionTransaction>(_context);
        public IGenericRepository<Entities.Payment> Payments => _payments ??= new GenericRepository<Entities.Payment>(_context);
        public IGenericRepository<Entities.SepayTransaction> SepayTransactions => _sepayTransactions ??= new GenericRepository<Entities.SepayTransaction>(_context);

        public async Task<int> CompleteAsync() => await _context.SaveChangesAsync();
        public void Dispose() { _context.Dispose(); GC.SuppressFinalize(this); }
    }
}
