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
            services.AddScoped<IUserService, UserService>();
            services.AddScoped<IFoodService, FoodService>();
            services.AddScoped<IIngredientService, IngredientService>();
            services.AddScoped<IRecipeService, RecipeService>();
            services.AddHttpClient<IEmailService, EmailService>();
            return services;
        }
    }
}
