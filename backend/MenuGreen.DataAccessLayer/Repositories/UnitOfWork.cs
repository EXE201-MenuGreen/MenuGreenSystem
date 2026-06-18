using System;
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
        private IGenericRepository<Entities.MealTemplate>? _mealTemplates;
        private IGenericRepository<Entities.MealTemplateItem>? _mealTemplateItems;
        private IGenericRepository<Entities.UserAiProfile>? _userAiProfiles;
        private IGenericRepository<Entities.NutritionSnapshot>? _nutritionSnapshots;
        private IGenericRepository<Entities.RecommendationHistory>? _recommendationHistories;
        private IGenericRepository<Entities.RecommendationFeedback>? _recommendationFeedbacks;
        private IGenericRepository<Entities.ActivityLog>? _activityLogs;
        private IGenericRepository<Entities.Notification>? _notifications;
        private IGenericRepository<Entities.NotificationSetting>? _notificationSettings;
        private IGenericRepository<Entities.Campaign>? _campaigns;
        private IGenericRepository<Entities.SubscriptionPlan>? _subscriptionPlans;
        private IGenericRepository<Entities.UserSubscription>? _userSubscriptions;
        private IGenericRepository<Entities.SubscriptionTransaction>? _subscriptionTransactions;
        private IGenericRepository<Entities.Payment>? _payments;
        private IGenericRepository<Entities.SepayTransaction>? _sepayTransactions;
        private IGenericRepository<Entities.ReminderProfile>? _reminderProfiles;
        private IGenericRepository<Entities.GoalDriftAlert>? _goalDriftAlerts;
        private IGenericRepository<Entities.BudgetRequest>? _budgetRequests;
        private IGenericRepository<Entities.FoodAllergy>? _foodAllergies;
        private IGenericRepository<Entities.UserSubstitutionPreference>? _userSubstitutionPreferences;
        private IGenericRepository<Entities.MealPlanItemSubstitution>? _mealPlanItemSubstitutions;
        private IGenericRepository<Entities.MealLogSubstitution>? _mealLogSubstitutions;
        private IGenericRepository<Entities.MicroLearningCard>? _microLearningCards;
        private IGenericRepository<Entities.UserCardInteraction>? _userCardInteractions;
        private IGenericRepository<Entities.FoodPortionMapping>? _foodPortionMappings;
        private IGenericRepository<Entities.CustomUserPortion>? _customUserPortions;
        private IGenericRepository<Entities.PremiumProgram>? _premiumPrograms;
        private IGenericRepository<Entities.UserPremiumProgram>? _userPremiumPrograms;
        private IGenericRepository<Entities.UserProgramMilestone>? _userProgramMilestones;
        private IGenericRepository<Entities.CoachProfile>? _coachProfiles;
        private IGenericRepository<Entities.CoachConnection>? _coachConnections;
        private IGenericRepository<Entities.CoachFeedback>? _coachFeedbacks;

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
        public IGenericRepository<Entities.MealTemplate> MealTemplates => _mealTemplates ??= new GenericRepository<Entities.MealTemplate>(_context);
        public IGenericRepository<Entities.MealTemplateItem> MealTemplateItems => _mealTemplateItems ??= new GenericRepository<Entities.MealTemplateItem>(_context);
        public IGenericRepository<Entities.UserAiProfile> UserAiProfiles => _userAiProfiles ??= new GenericRepository<Entities.UserAiProfile>(_context);
        public IGenericRepository<Entities.NutritionSnapshot> NutritionSnapshots => _nutritionSnapshots ??= new GenericRepository<Entities.NutritionSnapshot>(_context);
        public IGenericRepository<Entities.RecommendationHistory> RecommendationHistories => _recommendationHistories ??= new GenericRepository<Entities.RecommendationHistory>(_context);
        public IGenericRepository<Entities.RecommendationFeedback> RecommendationFeedbacks => _recommendationFeedbacks ??= new GenericRepository<Entities.RecommendationFeedback>(_context);
        public IGenericRepository<Entities.ActivityLog> ActivityLogs => _activityLogs ??= new GenericRepository<Entities.ActivityLog>(_context);
        public IGenericRepository<Entities.Notification> Notifications => _notifications ??= new GenericRepository<Entities.Notification>(_context);
        public IGenericRepository<Entities.NotificationSetting> NotificationSettings => _notificationSettings ??= new GenericRepository<Entities.NotificationSetting>(_context);
        public IGenericRepository<Entities.Campaign> Campaigns => _campaigns ??= new GenericRepository<Entities.Campaign>(_context);
        public IGenericRepository<Entities.SubscriptionPlan> SubscriptionPlans => _subscriptionPlans ??= new GenericRepository<Entities.SubscriptionPlan>(_context);
        public IGenericRepository<Entities.UserSubscription> UserSubscriptions => _userSubscriptions ??= new GenericRepository<Entities.UserSubscription>(_context);
        public IGenericRepository<Entities.SubscriptionTransaction> SubscriptionTransactions => _subscriptionTransactions ??= new GenericRepository<Entities.SubscriptionTransaction>(_context);
        public IGenericRepository<Entities.Payment> Payments => _payments ??= new GenericRepository<Entities.Payment>(_context);
        public IGenericRepository<Entities.SepayTransaction> SepayTransactions => _sepayTransactions ??= new GenericRepository<Entities.SepayTransaction>(_context);
        public IGenericRepository<Entities.ReminderProfile> ReminderProfiles => _reminderProfiles ??= new GenericRepository<Entities.ReminderProfile>(_context);
        public IGenericRepository<Entities.GoalDriftAlert> GoalDriftAlerts => _goalDriftAlerts ??= new GenericRepository<Entities.GoalDriftAlert>(_context);
        public IGenericRepository<Entities.BudgetRequest> BudgetRequests => _budgetRequests ??= new GenericRepository<Entities.BudgetRequest>(_context);
        public IGenericRepository<Entities.FoodAllergy> FoodAllergies => _foodAllergies ??= new GenericRepository<Entities.FoodAllergy>(_context);
        public IGenericRepository<Entities.UserSubstitutionPreference> UserSubstitutionPreferences => _userSubstitutionPreferences ??= new GenericRepository<Entities.UserSubstitutionPreference>(_context);
        public IGenericRepository<Entities.MealPlanItemSubstitution> MealPlanItemSubstitutions => _mealPlanItemSubstitutions ??= new GenericRepository<Entities.MealPlanItemSubstitution>(_context);
        public IGenericRepository<Entities.MealLogSubstitution> MealLogSubstitutions => _mealLogSubstitutions ??= new GenericRepository<Entities.MealLogSubstitution>(_context);
        public IGenericRepository<Entities.MicroLearningCard> MicroLearningCards => _microLearningCards ??= new GenericRepository<Entities.MicroLearningCard>(_context);
        public IGenericRepository<Entities.UserCardInteraction> UserCardInteractions => _userCardInteractions ??= new GenericRepository<Entities.UserCardInteraction>(_context);
        public IGenericRepository<Entities.FoodPortionMapping> FoodPortionMappings => _foodPortionMappings ??= new GenericRepository<Entities.FoodPortionMapping>(_context);
        public IGenericRepository<Entities.CustomUserPortion> CustomUserPortions => _customUserPortions ??= new GenericRepository<Entities.CustomUserPortion>(_context);
        public IGenericRepository<Entities.PremiumProgram> PremiumPrograms => _premiumPrograms ??= new GenericRepository<Entities.PremiumProgram>(_context);
        public IGenericRepository<Entities.UserPremiumProgram> UserPremiumPrograms => _userPremiumPrograms ??= new GenericRepository<Entities.UserPremiumProgram>(_context);
        public IGenericRepository<Entities.UserProgramMilestone> UserProgramMilestones => _userProgramMilestones ??= new GenericRepository<Entities.UserProgramMilestone>(_context);
        public IGenericRepository<Entities.CoachProfile> CoachProfiles => _coachProfiles ??= new GenericRepository<Entities.CoachProfile>(_context);
        public IGenericRepository<Entities.CoachConnection> CoachConnections => _coachConnections ??= new GenericRepository<Entities.CoachConnection>(_context);
        public IGenericRepository<Entities.CoachFeedback> CoachFeedbacks => _coachFeedbacks ??= new GenericRepository<Entities.CoachFeedback>(_context);

        public async Task<int> CompleteAsync() => await _context.SaveChangesAsync();
        public void Dispose() { _context.Dispose(); GC.SuppressFinalize(this); }
    }
}
