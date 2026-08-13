using System;

namespace MenuGreen.BusinessLogicLayer.Helpers
{
    public static class CacheKeys
    {
        private const string Version = "v1";
        private const string MealPlanVersion = "v3";

        public static string FoodCatalog(string? keyword, string? category, int? minCal, int? maxCal)
            => $"food:catalog:{Version}:{keyword ?? ""}:{category ?? ""}:{minCal}:{maxCal}";

        public static string RecipeCatalog(string? keyword, string? mealType, string? difficulty)
            => $"recipe:catalog:{Version}:{keyword ?? ""}:{mealType ?? ""}:{difficulty ?? ""}";

        public static string IngredientCatalog(string? keyword, string? category)
            => $"ingredient:catalog:{Version}:{keyword ?? ""}:{category ?? ""}";

        public static string SubscriptionPlans() => $"subscription:plans:active:{Version}";

        public static string UserAllergenKeys(Guid userId) => $"user:{userId}:allergen-keys:{Version}";

        public static string FoodAllergenKeys(Guid foodId) => $"food:{foodId}:allergen-keys:{Version}";

        public static string UserSubscription(Guid userId) => $"user:{userId}:subscription:active:{Version}";

        public static string UserHealthTargets(Guid userId) => $"user:{userId}:health-targets:{Version}";

        public static string UserFcmTokens(Guid userId) => $"user:{userId}:fcm-tokens:{Version}";

        public static string RecipeNutrition(Guid recipeId) => $"recipe:{recipeId}:nutrition:{Version}";

        public static string DailyStarter(Guid userId, DateTime date)
            => $"user:{userId}:daily-starter:{date:yyyy-MM-dd}:{Version}";

        public static string DailyStarterByDate(Guid userId, DateOnly date)
            => $"user:{userId}:daily-starter:{date:yyyy-MM-dd}:{Version}";

        public static string FeaturedMeals(Guid userId) => $"user:{userId}:featured-meals:{Version}";

        public static string CaloriesRemaining(Guid userId, DateTime date)
            => $"user:{userId}:calories-remaining:{date:yyyy-MM-dd}:{Version}";

        public static string MealPlan(Guid userId, DateTime date)
            => $"user:{userId}:mealplan:{date:yyyy-MM-dd}:{MealPlanVersion}";

        public static string MealPlanByDate(Guid userId, DateOnly date)
            => $"user:{userId}:mealplan:{date:yyyy-MM-dd}:{MealPlanVersion}";

        public static string UserAiContext(Guid userId) => $"user:{userId}:ai-context:{Version}";

        public static string Conversation(Guid conversationId) => $"conversation:{conversationId}:messages:{Version}";

        public static string UserAiProfile(Guid userId) => $"user:{userId}:ai-profile:{Version}";

        public static string DashboardMetrics() => $"dashboard:metrics:{Version}";

        public static string FoodRanking(int count) => $"dashboard:food-ranking:{Version}:top:{count}";

        public static string PortionDefaults() => $"portion:defaults:{Version}";

        public static string CoachClients(Guid coachId) => $"coach:{coachId}:clients:{Version}";

        public static string CoachList(string? specialty, decimal? minPrice, decimal? maxPrice)
            => $"coaches:active:{Version}:{specialty ?? ""}:{minPrice}:{maxPrice}";

        public static string CoachProfile(Guid coachId) => $"coach:profile:{coachId}:{Version}";

        public static string SepayWebhookProcessed(string transactionId)
            => $"sepay:webhook:processed:{transactionId}:{Version}";

        public static string UserSnapshot(Guid userId, DateTime date)
            => $"user:{userId}:snapshot:{date:yyyy-MM-dd}:{Version}";

        public static string UserDailySummary(Guid userId, DateTime date)
            => $"user:{userId}:daily-summary:{date:yyyy-MM-dd}:{Version}";

        public static string CvAnalysisResult(Guid cvAnalysisId)
            => $"cv:analysis:{cvAnalysisId}:{Version}";
    }
}
