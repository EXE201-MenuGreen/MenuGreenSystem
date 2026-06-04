class ApiEndpoints {
  /// Backend production (Render).
  static const String productionBaseUrl =
      'https://menugreensystem.onrender.com/api';

  /// Ghi đè khi dev local: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api`
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _normalizeBaseUrl(_envBaseUrl);
    return productionBaseUrl;
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return productionBaseUrl;
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  static String get login => '$baseUrl/Auth/login';
  static String get googleLogin => '$baseUrl/Auth/google';
  static String get register => '$baseUrl/Auth/register';
  static String get verifyOtp => '$baseUrl/Auth/verify-otp';
  static String get forgotPassword => '$baseUrl/Auth/forgot-password';
  static String get resetPassword => '$baseUrl/Auth/reset-password';
  static String get refreshToken => '$baseUrl/Auth/refresh-token';
  static String get logout => '$baseUrl/Auth/logout';
  static String get getProfile => '$baseUrl/Profile/me';
  static String get updateAvatar => '$baseUrl/Profile/me/avatar';
  static String get removeAvatar => '$baseUrl/Profile/me/avatar';
  static String get changePassword => '$baseUrl/User/change-password';
  static String get healthProfileMe => '$baseUrl/HealthProfile/me';
  static String get nutritionDaily => '$baseUrl/NutritionTracking/daily';
  static String get nutritionDashboard =>
      '$baseUrl/NutritionTracking/dashboard';
  static String get nutritionWeightLogs =>
      '$baseUrl/NutritionTracking/weight-logs';
  static String nutritionMealLogById(String mealLogId) =>
      '$baseUrl/NutritionTracking/meal-logs/$mealLogId';
  static String nutritionWeightLogById(String weightLogId) =>
      '$baseUrl/NutritionTracking/weight-logs/$weightLogId';
  static String get foods => '$baseUrl/Food';
  static String foodById(String id) => '$baseUrl/Food/$id';
  static String foodRecipes(String foodId) => '$baseUrl/Food/$foodId/recipes';
  static String foodFavorite(String foodId) => '$baseUrl/Food/$foodId/favorite';
  static String get foodFavorites => '$baseUrl/Food/favorites';
  static String get recipeSearch => '$baseUrl/Recipe/search';
  static String recipeById(String id) => '$baseUrl/Recipe/$id';
  static String recipeIngredients(String id) => '$baseUrl/Recipe/$id/ingredients';
  static String get ingredientSearch => '$baseUrl/Ingredient/search';
  static String ingredientById(String id) => '$baseUrl/Ingredient/$id';
  static String ingredientRecipes(String id) => '$baseUrl/Ingredient/$id/recipes';
  static String get recommendationCalories => '$baseUrl/Recommendation/calories';
  static String get recommendationLunch => '$baseUrl/Recommendation/lunch';
  static String get recommendationEco => '$baseUrl/Recommendation/eco';
  static String get recommendationDailyMenu => '$baseUrl/Recommendation/daily-menu';
  static String get profileSummary => '$baseUrl/Profile/me/summary';
  static String get profileCompletion => '$baseUrl/Profile/me/completion';
  static String get userAiProfileMe => '$baseUrl/UserAiProfile/me';
  static String get onboardingComplete => '$baseUrl/Onboarding/complete';
  static String get recipes => '$baseUrl/Recipe';
  static String get nutritionMealLogs => '$baseUrl/NutritionTracking/meal-logs';

  static String get subscriptionPlans => '$baseUrl/UserSubscription/plans';
  static String get subscriptionSubscribe =>
      '$baseUrl/UserSubscription/subscribe';
  static String get subscriptionRenew => '$baseUrl/UserSubscription/renew';
  static String get subscriptionCancel => '$baseUrl/UserSubscription/cancel';
  static String get subscriptionCurrent => '$baseUrl/UserSubscription/me';
  static String get subscriptionHistory =>
      '$baseUrl/UserSubscription/me/history';

  static String get sepayCreateOrder => '$baseUrl/payments/sepay/create-order';
  static String get sepayCreateRenewOrder =>
      '$baseUrl/payments/sepay/create-renew-order';
  static String get sepayPendingOrders => '$baseUrl/payments/sepay/pending';
  static String sepayPaymentStatus(String paymentId) =>
      '$baseUrl/payments/sepay/$paymentId';

  static String get allergies => '$baseUrl/Allergy';
  static String allergyById(String allergyId) => '$baseUrl/Allergy/$allergyId';
}
