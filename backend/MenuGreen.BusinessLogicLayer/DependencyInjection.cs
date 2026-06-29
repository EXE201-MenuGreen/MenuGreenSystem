using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.BusinessLogicLayer.Configuration;
using MenuGreen.BusinessLogicLayer.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace MenuGreen.BusinessLogicLayer
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddBusinessLogicLayer(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddCvServiceOptions(configuration);

            services.AddSingleton<ISepayPaymentStatusCache, SepayPaymentStatusCache>();

            services.AddScoped<IAuthService, AuthService>();
            services.AddScoped<IProfileService, ProfileService>();
            services.AddScoped<IHealthProfileService, HealthProfileService>();
            services.AddScoped<IUserAiProfileService, UserAiProfileService>();
            services.AddScoped<INutritionSnapshotService, NutritionSnapshotService>();
            services.AddScoped<IOnboardingService, OnboardingService>();
            services.AddScoped<IAllergyService, AllergyService>();
            services.AddScoped<IUserService, UserService>();
            services.AddScoped<IAllergenMatchingService, AllergenMatchingService>();
            services.AddScoped<IFoodService, FoodService>();
            services.AddScoped<IIngredientService, IngredientService>();
            services.AddScoped<IRecipeService, RecipeService>();
            services.AddScoped<INutritionTrackingService, NutritionTrackingService>();
            services.AddScoped<IRecommendationService, RecommendationService>();
            services.AddScoped<IMealPlanService, MealPlanService>();
            services.AddScoped<IBudgetRequestService, BudgetRequestService>();
            services.AddScoped<IMealTemplateService, MealTemplateService>();
            services.AddScoped<ISubscriptionPlanService, SubscriptionPlanService>();
            services.AddScoped<IUserSubscriptionService, UserSubscriptionService>();
            services.AddScoped<SepayWebhookHmacValidator>();
            services.AddScoped<SepayQrUrlBuilder>();
            services.AddScoped<SepayWebhookPaymentVerifier>();
            services.AddScoped<ISepayPaymentService, SepayPaymentService>();
            services.AddScoped<IDashboardService, DashboardService>();
            services.AddScoped<IUserDashboardService, UserDashboardService>();
            services.AddScoped<IUserMetricsService, UserMetricsService>();
            services.AddScoped<IRevenueMetricsService, RevenueMetricsService>();
            services.AddScoped<IFoodRankingService, FoodRankingService>();
            services.AddScoped<INotificationService, NotificationService>();
            services.AddScoped<IFcmService, FcmService>();
            services.AddScoped<INotificationDispatcherService, NotificationDispatcherService>();
            services.AddHostedService<NotificationDispatchBackgroundService>();
            services.AddScoped<IReminderService, ReminderService>();
            services.AddScoped<IGoalDriftService, GoalDriftService>();
            services.AddScoped<IDailyStarterService, DailyStarterService>();
            services.AddScoped<IAnalyticsService, AnalyticsService>();
            services.AddScoped<ICatalogService, CatalogService>();
            services.AddScoped<IIngredientSubstitutionService, IngredientSubstitutionService>();
            services.AddScoped<IFoodCatalogService, FoodCatalogService>();
            services.AddScoped<IIngredientCatalogService, IngredientCatalogService>();
            services.AddScoped<IRecipeCatalogService, RecipeCatalogService>();
            services.AddScoped<INutritionAssistantService, NutritionAssistantService>();
            services.AddScoped<IAiAssistantService, AiAssistantService>();
            services.AddScoped<ICvService, CvService>();
            services.AddScoped<IPlannedVsActualService, PlannedVsActualService>();
            services.AddScoped<IPtReviewService, PtReviewService>();
            services.AddScoped<IMicroLearningService, MicroLearningService>();
            services.AddScoped<IPortionConverterService, PortionConverterService>();
            services.AddScoped<IPremiumProgramService, PremiumProgramService>();
            services.AddScoped<ICoachService, CoachService>();
            services.AddScoped<IAnalyticsService, AnalyticsService>();
            services.AddHttpClient<IEmailService, EmailService>();
            services.AddHttpClient(nameof(NutritionAssistantService));
            services.AddHttpClient(nameof(CvService));
            return services;
        }
    }
}
