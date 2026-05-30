using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.BusinessLogicLayer.Services;
using Microsoft.Extensions.DependencyInjection;

namespace MenuGreen.BusinessLogicLayer
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddBusinessLogicLayer(this IServiceCollection services)
        {
            services.AddScoped<IAuthService, AuthService>();
            services.AddScoped<IProfileService, ProfileService>();
            services.AddScoped<IHealthProfileService, HealthProfileService>();
            services.AddScoped<IAllergyService, AllergyService>();
            services.AddScoped<IUserService, UserService>();
            services.AddScoped<IAdminUserService, AdminUserService>();
            services.AddScoped<IAdminFoodService, AdminFoodService>();
            services.AddScoped<IAdminIngredientService, AdminIngredientService>();
            services.AddScoped<IAdminRecipeService, AdminRecipeService>();
            services.AddScoped<IFoodService, FoodService>();
            services.AddScoped<IIngredientService, IngredientService>();
            services.AddScoped<IRecipeService, RecipeService>();
            services.AddScoped<INutritionTrackingService, NutritionTrackingService>();
            services.AddScoped<IRecommendationService, RecommendationService>();
            services.AddScoped<IMealPlanService, MealPlanService>();
            services.AddScoped<ISubscriptionPlanService, SubscriptionPlanService>();
            services.AddScoped<IUserSubscriptionService, UserSubscriptionService>();
            services.AddScoped<IDashboardService, DashboardService>();
            services.AddScoped<IUserMetricsService, UserMetricsService>();
            services.AddScoped<IRevenueMetricsService, RevenueMetricsService>();
            services.AddScoped<IFoodRankingService, FoodRankingService>();
            services.AddScoped<INotificationService, NotificationService>();
            services.AddScoped<ICatalogService, CatalogService>();
            services.AddScoped<IFoodCatalogService, FoodCatalogService>();
            services.AddScoped<IIngredientCatalogService, IngredientCatalogService>();
            services.AddScoped<IRecipeCatalogService, RecipeCatalogService>();
            services.AddHttpClient<IEmailService, EmailService>();
            return services;
        }
    }
}
