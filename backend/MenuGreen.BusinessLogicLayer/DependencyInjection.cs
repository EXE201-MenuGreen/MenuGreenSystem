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
            services.AddScoped<IFoodService, FoodService>();
            services.AddScoped<IIngredientService, IngredientService>();
            services.AddScoped<IRecipeService, RecipeService>();
            services.AddScoped<INutritionTrackingService, NutritionTrackingService>();
            services.AddScoped<IRecommendationService, RecommendationService>();
            services.AddScoped<IMealPlanService, MealPlanService>();
            services.AddHttpClient<IEmailService, EmailService>();
            return services;
        }
    }
}
