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
            modelBuilder.Entity<UserProgramMilestone>().HasQueryFilter(upm => upm.UserPremiumProgram == null || upm.UserPremiumProgram.User == null || EF.Property<DateTime?>(upm.UserPremiumProgram.User, "DeletedAt") == null);
            modelBuilder.Entity<UserSubscription>().HasQueryFilter(us => us.User == null || EF.Property<DateTime?>(us.User, "DeletedAt") == null);
            modelBuilder.Entity<UserSubstitutionPreference>().HasQueryFilter(usp => usp.User == null || EF.Property<DateTime?>(usp.User, "DeletedAt") == null);
            modelBuilder.Entity<WeightLog>().HasQueryFilter(wl => wl.User == null || EF.Property<DateTime?>(wl.User, "DeletedAt") == null);
            modelBuilder.Entity<Session>().HasQueryFilter(s => s.User == null || EF.Property<DateTime?>(s.User, "DeletedAt") == null);
            modelBuilder.Entity<Subscription>().HasQueryFilter(sub => sub.User == null || EF.Property<DateTime?>(sub.User, "DeletedAt") == null);
            modelBuilder.Entity<SubscriptionTransaction>().HasQueryFilter(st => st.User == null || EF.Property<DateTime?>(st.User, "DeletedAt") == null);
            modelBuilder.Entity<UserAiProfile>().HasQueryFilter(uap => uap.User == null || EF.Property<DateTime?>(uap.User, "DeletedAt") == null);
            modelBuilder.Entity<Payment>().HasQueryFilter(p => p.User == null || EF.Property<DateTime?>(p.User, "DeletedAt") == null);
            modelBuilder.Entity<Profile>().HasQueryFilter(p => p.User == null || EF.Property<DateTime?>(p.User, "DeletedAt") == null);
            modelBuilder.Entity<PtReviewRequest>().HasQueryFilter(pr => pr.User == null || EF.Property<DateTime?>(pr.User, "DeletedAt") == null);
            modelBuilder.Entity<RecommendationHistory>().HasQueryFilter(rh => rh.User == null || EF.Property<DateTime?>(rh.User, "DeletedAt") == null);
            modelBuilder.Entity<ReminderProfile>().HasQueryFilter(rp => rp.User == null || EF.Property<DateTime?>(rp.User, "DeletedAt") == null);
            modelBuilder.Entity<NotificationSetting>().HasQueryFilter(ns => ns.User == null || EF.Property<DateTime?>(ns.User, "DeletedAt") == null);
            modelBuilder.Entity<NutritionSnapshot>().HasQueryFilter(ns => ns.User == null || EF.Property<DateTime?>(ns.User, "DeletedAt") == null);
            modelBuilder.Entity<PasswordResetToken>().HasQueryFilter(prt => prt.User == null || EF.Property<DateTime?>(prt.User, "DeletedAt") == null);
            modelBuilder.Entity<RecommendationFeedback>().HasQueryFilter(rf => rf.Recommendation == null || rf.Recommendation.User == null || EF.Property<DateTime?>(rf.Recommendation.User, "DeletedAt") == null);
            modelBuilder.Entity<SepayTransaction>().HasQueryFilter(st => st.Payment == null || st.Payment.User == null || EF.Property<DateTime?>(st.Payment.User, "DeletedAt") == null);
            modelBuilder.Entity<HealthProfile>().HasQueryFilter(hp => hp.User == null || EF.Property<DateTime?>(hp.User, "DeletedAt") == null);
            modelBuilder.Entity<MealLog>().HasQueryFilter(ml => ml.User == null || EF.Property<DateTime?>(ml.User, "DeletedAt") == null);
            modelBuilder.Entity<MealPlanHeader>().HasQueryFilter(mph => mph.User == null || EF.Property<DateTime?>(mph.User, "DeletedAt") == null);
            modelBuilder.Entity<MealTemplate>().HasQueryFilter(mt => mt.User == null || EF.Property<DateTime?>(mt.User, "DeletedAt") == null);
            modelBuilder.Entity<Notification>().HasQueryFilter(n => n.User == null || EF.Property<DateTime?>(n.User, "DeletedAt") == null);
            modelBuilder.Entity<FavoriteFood>().HasQueryFilter(ff => ff.User == null || EF.Property<DateTime?>(ff.User, "DeletedAt") == null);
            modelBuilder.Entity<CoachConnection>().HasQueryFilter(cc => (cc.Client == null || EF.Property<DateTime?>(cc.Client, "DeletedAt") == null) && (cc.Coach == null || EF.Property<DateTime?>(cc.Coach, "DeletedAt") == null));
            modelBuilder.Entity<EmailVerification>().HasQueryFilter(ev => ev.User == null || EF.Property<DateTime?>(ev.User, "DeletedAt") == null);
            modelBuilder.Entity<Allergy>().HasQueryFilter(a => a.User == null || EF.Property<DateTime?>(a.User, "DeletedAt") == null);
            modelBuilder.Entity<AiConversation>().HasQueryFilter(ac => ac.User == null || EF.Property<DateTime?>(ac.User, "DeletedAt") == null);
            modelBuilder.Entity<AiMessage>().HasQueryFilter(am => am.Conversation == null || am.Conversation.User == null || EF.Property<DateTime?>(am.Conversation.User, "DeletedAt") == null);
            modelBuilder.Entity<ActivityLog>().HasQueryFilter(al => al.User == null || EF.Property<DateTime?>(al.User, "DeletedAt") == null);
            modelBuilder.Entity<BudgetRequest>().HasQueryFilter(br => br.User == null || EF.Property<DateTime?>(br.User, "DeletedAt") == null);
            modelBuilder.Entity<GoalDriftAlert>().HasQueryFilter(gda => gda.User == null || EF.Property<DateTime?>(gda.User, "DeletedAt") == null);
            modelBuilder.Entity<CustomUserPortion>().HasQueryFilter(cup => cup.User == null || EF.Property<DateTime?>(cup.User, "DeletedAt") == null);
            modelBuilder.Entity<DeviceToken>().HasQueryFilter(dt => dt.User == null || EF.Property<DateTime?>(dt.User, "DeletedAt") == null);
            modelBuilder.Entity<CoachProfile>().HasQueryFilter(cp => cp.User == null || EF.Property<DateTime?>(cp.User, "DeletedAt") == null);
            modelBuilder.Entity<CoachFeedback>().HasQueryFilter(cf => (cf.Client == null || EF.Property<DateTime?>(cf.Client, "DeletedAt") == null) && (cf.Coach == null || EF.Property<DateTime?>(cf.Coach, "DeletedAt") == null));
            modelBuilder.Entity<MealPlanItem>().HasQueryFilter(mpi => mpi.MealPlanHeader == null || mpi.MealPlanHeader.User == null || EF.Property<DateTime?>(mpi.MealPlanHeader.User, "DeletedAt") == null);
            modelBuilder.Entity<MealTemplateItem>().HasQueryFilter(mti => mti.MealTemplate == null || mti.MealTemplate.User == null || EF.Property<DateTime?>(mti.MealTemplate.User, "DeletedAt") == null);
            // Food/Recipe dùng IsActive thay vì DeletedAt — query filter không tham chiếu cột không tồn tại.
            modelBuilder.Entity<RecipeIngredient>().HasQueryFilter(ri => true);
            modelBuilder.Entity<FoodAllergy>().HasQueryFilter(fa => true);
            modelBuilder.Entity<MealPlanItemSubstitution>().HasQueryFilter(mpis => mpis.MealPlanItem == null || mpis.MealPlanItem.MealPlanHeader == null || mpis.MealPlanItem.MealPlanHeader.User == null || EF.Property<DateTime?>(mpis.MealPlanItem.MealPlanHeader.User, "DeletedAt") == null);
            modelBuilder.Entity<MealLogSubstitution>().HasQueryFilter(mls => mls.MealLog == null || mls.MealLog.User == null || EF.Property<DateTime?>(mls.MealLog.User, "DeletedAt") == null);
        }
    }
}
