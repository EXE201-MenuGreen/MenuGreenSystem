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
        IGenericRepository<Entities.UserAllergy> UserAllergies { get; }
        IGenericRepository<Entities.MealLog> MealLogs { get; }
        IGenericRepository<Entities.WeightLog> WeightLogs { get; }
        IGenericRepository<Entities.MealPlanHeader> MealPlanHeaders { get; }
        IGenericRepository<Entities.MealPlanItem> MealPlanItems { get; }
        IGenericRepository<Entities.MealTemplate> MealTemplates { get; }
        IGenericRepository<Entities.MealTemplateItem> MealTemplateItems { get; }
        IGenericRepository<Entities.UserAiProfile> UserAiProfiles { get; }
        IGenericRepository<Entities.NutritionSnapshot> NutritionSnapshots { get; }
        IGenericRepository<Entities.RecommendationHistory> RecommendationHistories { get; }
        IGenericRepository<Entities.RecommendationFeedback> RecommendationFeedbacks { get; }
        IGenericRepository<Entities.ActivityLog> ActivityLogs { get; }
        IGenericRepository<Entities.Notification> Notifications { get; }
        IGenericRepository<Entities.NotificationSetting> NotificationSettings { get; }
        IGenericRepository<Entities.Campaign> Campaigns { get; }
        IGenericRepository<Entities.SubscriptionPlan> SubscriptionPlans { get; }
        IGenericRepository<Entities.UserSubscription> UserSubscriptions { get; }
        IGenericRepository<Entities.SubscriptionTransaction> SubscriptionTransactions { get; }
        IGenericRepository<Entities.Payment> Payments { get; }
        IGenericRepository<Entities.SepayTransaction> SepayTransactions { get; }
        IGenericRepository<Entities.ReminderProfile> ReminderProfiles { get; }
        IGenericRepository<Entities.GoalDriftAlert> GoalDriftAlerts { get; }
        IGenericRepository<Entities.BudgetRequest> BudgetRequests { get; }
        IGenericRepository<Entities.FoodAllergy> FoodAllergies { get; }
        IGenericRepository<Entities.UserSubstitutionPreference> UserSubstitutionPreferences { get; }
        IGenericRepository<Entities.MealPlanItemSubstitution> MealPlanItemSubstitutions { get; }
        IGenericRepository<Entities.MealLogSubstitution> MealLogSubstitutions { get; }
        IGenericRepository<Entities.MicroLearningCard> MicroLearningCards { get; }
        IGenericRepository<Entities.UserCardInteraction> UserCardInteractions { get; }
        IGenericRepository<Entities.FoodPortionMapping> FoodPortionMappings { get; }
        IGenericRepository<Entities.CustomUserPortion> CustomUserPortions { get; }
        IGenericRepository<Entities.DefaultPortionUnit> DefaultPortionUnits { get; }
        IGenericRepository<Entities.PremiumProgram> PremiumPrograms { get; }
        IGenericRepository<Entities.UserPremiumProgram> UserPremiumPrograms { get; }
        IGenericRepository<Entities.UserProgramMilestone> UserProgramMilestones { get; }
        IGenericRepository<Entities.CoachProfile> CoachProfiles { get; }
        IGenericRepository<Entities.CoachConnection> CoachConnections { get; }
        IGenericRepository<Entities.CoachFeedback> CoachFeedbacks { get; }
        IGenericRepository<Entities.CoachChatMessage> CoachChatMessages { get; }
        IGenericRepository<Entities.PtReviewRequest> PtReviewRequests { get; }
        IGenericRepository<Entities.DeviceToken> DeviceTokens { get; }
        IGenericRepository<Entities.MealPlanProposal> MealPlanProposals { get; }
        IGenericRepository<Entities.MealPlanProposalItem> MealPlanProposalItems { get; }
        
        Task<int> CompleteAsync();
    }
}
