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
        public DbSet<FoodAllergenTag> FoodAllergenTags { get; set; }
        public DbSet<Recipe> Recipes { get; set; }
        public DbSet<RecipeIngredient> RecipeIngredients { get; set; }
        public DbSet<FavoriteFood> FavoriteFoods { get; set; }
        public DbSet<MealLog> MealLogs { get; set; }
        public DbSet<WeightLog> WeightLogs { get; set; }
        public DbSet<NutritionSnapshot> NutritionSnapshots { get; set; }
        public DbSet<MealPlanHeader> MealPlanHeaders { get; set; }
        public DbSet<MealPlanItem> MealPlanItems { get; set; }
        public DbSet<MealTemplate> MealTemplates { get; set; }
        public DbSet<MealTemplateItem> MealTemplateItems { get; set; }
        public DbSet<AiConversation> AiConversations { get; set; }
        public DbSet<AiMessage> AiMessages { get; set; }
        public DbSet<RecommendationHistory> RecommendationHistories { get; set; }
        public DbSet<RecommendationFeedback> RecommendationFeedbacks { get; set; }
        public DbSet<UserAiProfile> UserAiProfiles { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<NotificationSetting> NotificationSettings { get; set; }
        public DbSet<Campaign> Campaigns { get; set; }
        public DbSet<UserSubstitutionPreference> UserSubstitutionPreferences { get; set; }
        public DbSet<MealPlanItemSubstitution> MealPlanItemSubstitutions { get; set; }
        public DbSet<MealLogSubstitution> MealLogSubstitutions { get; set; }
        public DbSet<SubscriptionPlan> SubscriptionPlans { get; set; }
        public DbSet<UserSubscription> UserSubscriptions { get; set; }
        public DbSet<SubscriptionTransaction> SubscriptionTransactions { get; set; }
        public DbSet<Subscription> Subscriptions { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<SepayTransaction> SepayTransactions { get; set; }
        public DbSet<ActivityLog> ActivityLogs { get; set; }
        public DbSet<BudgetRequest> BudgetRequests { get; set; }
        public DbSet<ReminderProfile> ReminderProfiles { get; set; }
        public DbSet<GoalDriftAlert> GoalDriftAlerts { get; set; }
        public DbSet<MicroLearningCard> MicroLearningCards { get; set; }
        public DbSet<UserCardInteraction> UserCardInteractions { get; set; }
        public DbSet<FoodPortionMapping> FoodPortionMappings { get; set; }
        public DbSet<CustomUserPortion> CustomUserPortions { get; set; }
        public DbSet<DefaultPortionUnit> DefaultPortionUnits { get; set; }
        public DbSet<PremiumProgram> PremiumPrograms { get; set; }
        public DbSet<UserPremiumProgram> UserPremiumPrograms { get; set; }
        public DbSet<UserProgramMilestone> UserProgramMilestones { get; set; }
        public DbSet<CoachProfile> CoachProfiles { get; set; }
        public DbSet<CoachConnection> CoachConnections { get; set; }
        public DbSet<CoachFeedback> CoachFeedbacks { get; set; }
        public DbSet<PtReviewRequest> PtReviewRequests { get; set; }
        public DbSet<DeviceToken> DeviceTokens { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);

            // Global Query Filters for Soft Deletion
            // Filter User by DeletedAt (soft delete)
            modelBuilder.Entity<User>().HasQueryFilter(u => u.DeletedAt == null);

            // Filter entities with required relationship to User
            modelBuilder.Entity<UserAllergy>().HasQueryFilter(ua => ua.User == null || EF.Property<DateTime?>(ua.User, "DeletedAt") == null);
            modelBuilder.Entity<UserCardInteraction>().HasQueryFilter(uci => uci.User == null || EF.Property<DateTime?>(uci.User, "DeletedAt") == null);
            modelBuilder.Entity<UserPremiumProgram>().HasQueryFilter(upp => upp.User == null || EF.Property<DateTime?>(upp.User, "DeletedAt") == null);
            modelBuilder.Entity<UserSubscription>().HasQueryFilter(us => us.User == null || EF.Property<DateTime?>(us.User, "DeletedAt") == null);
            modelBuilder.Entity<UserSubstitutionPreference>().HasQueryFilter(usp => usp.User == null || EF.Property<DateTime?>(usp.User, "DeletedAt") == null);
            modelBuilder.Entity<WeightLog>().HasQueryFilter(wl => wl.User == null || EF.Property<DateTime?>(wl.User, "DeletedAt") == null);
        }
    }
}
