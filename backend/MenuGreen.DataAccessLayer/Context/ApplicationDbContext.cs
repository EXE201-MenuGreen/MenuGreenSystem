using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;

namespace MenuGreen.DataAccessLayer.Context
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        {
        }

        public DbSet<Role> Roles { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<Session> Sessions { get; set; }
        public DbSet<EmailVerification> EmailVerifications { get; set; }
        public DbSet<PasswordResetToken> PasswordResetTokens { get; set; }
        public DbSet<Profile> Profiles { get; set; }
        public DbSet<HealthProfile> HealthProfiles { get; set; }
        public DbSet<Allergy> Allergies { get; set; }
        public DbSet<UserAllergy> UserAllergies { get; set; }
        public DbSet<Ingredient> Ingredients { get; set; }
        public DbSet<Food> Foods { get; set; }
        public DbSet<FoodAllergy> FoodAllergies { get; set; }
        public DbSet<Recipe> Recipes { get; set; }
        public DbSet<RecipeIngredient> RecipeIngredients { get; set; }
        public DbSet<FavoriteFood> FavoriteFoods { get; set; }
        public DbSet<MealLog> MealLogs { get; set; }
        public DbSet<WeightLog> WeightLogs { get; set; }
        public DbSet<NutritionSnapshot> NutritionSnapshots { get; set; }
        public DbSet<MealPlanHeader> MealPlanHeaders { get; set; }
        public DbSet<MealPlanItem> MealPlanItems { get; set; }
        public DbSet<AiConversation> AiConversations { get; set; }
        public DbSet<AiMessage> AiMessages { get; set; }
        public DbSet<RecommendationHistory> RecommendationHistories { get; set; }
        public DbSet<RecommendationFeedback> RecommendationFeedbacks { get; set; }
        public DbSet<UserAiProfile> UserAiProfiles { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<NotificationSetting> NotificationSettings { get; set; }
        public DbSet<SubscriptionPlan> SubscriptionPlans { get; set; }
        public DbSet<UserSubscription> UserSubscriptions { get; set; }
        public DbSet<SubscriptionTransaction> SubscriptionTransactions { get; set; }
        public DbSet<Subscription> Subscriptions { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<SepayTransaction> SepayTransactions { get; set; }
        public DbSet<ActivityLog> ActivityLogs { get; set; }
        public DbSet<BudgetRequest> BudgetRequests { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);
        }
    }
}
