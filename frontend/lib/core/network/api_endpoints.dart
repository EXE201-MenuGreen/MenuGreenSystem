class ApiEndpoints {
  /// Backend production (AWS Lightsail + Nginx).
  static const String productionBaseUrl = 'https://api.menugreen.food/api';

  /// Ghi đè khi dev local: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api`
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _normalizeBaseUrl(_envBaseUrl);
    return productionBaseUrl;
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return productionBaseUrl;
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
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
  static String get cvAnalyze => '$baseUrl/Cv/analyze';
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
  static String recipeIngredients(String id) =>
      '$baseUrl/Recipe/$id/ingredients';
  static String get ingredientSearch => '$baseUrl/Ingredient/search';
  static String ingredientById(String id) => '$baseUrl/Ingredient/$id';
  static String ingredientRecipes(String id) =>
      '$baseUrl/Ingredient/$id/recipes';
  static String get recommendationCalories =>
      '$baseUrl/Recommendation/calories';
  static String get recommendationLunch => '$baseUrl/Recommendation/lunch';
  static String get recommendationEco => '$baseUrl/Recommendation/eco';
  static String get recommendationDailyMenu =>
      '$baseUrl/Recommendation/daily-menu';

  // Recommendation endpoints (Extended)
  static String get recommendationHistory => '$baseUrl/Recommendation/history';
  static String recommendationById(String id) => '$baseUrl/Recommendation/$id';
  static String get recommendationPreview => '$baseUrl/Recommendation/preview';
  static String get recommendationFeedback =>
      '$baseUrl/Recommendation/feedback';
  static String recommendationExplain(String id) =>
      '$baseUrl/Recommendation/explain/$id';
  static String get recommendationScores => '$baseUrl/Recommendation/scores';
  static String get recommendationRetrain => '$baseUrl/Recommendation/retrain';
  static String get recommendationGenerate =>
      '$baseUrl/Recommendation/generate';
  static String get recommendationGenerateSafe =>
      '$baseUrl/Recommendation/generate/safe';
  static String get recommendationGenerateWeeklyPlan =>
      '$baseUrl/Recommendation/generate/weekly-plan';
  static String get recommendationGenerateBudgetAware =>
      '$baseUrl/Recommendation/generate/budget-aware';
  static String get recommendationGenerateDailyMenu =>
      '$baseUrl/Recommendation/generate/daily-menu';
  static String recommendationUpdateFeedback(String id) =>
      '$baseUrl/Recommendation/feedback/$id';
  static String get recommendationFeedbackSummary =>
      '$baseUrl/Recommendation/feedback/summary';
  static String get recommendationSmartSchedule =>
      '$baseUrl/Recommendation/generate/smart-schedule';

  static String get userMealPlans => '$baseUrl/user-meal-plans';
  static String get userMealPlanAdherence =>
      '$baseUrl/user-meal-plans/adherence';
  static String userMealPlanById(String id) => '$baseUrl/user-meal-plans/$id';
  static String userMealPlanDelete(String id) => '$baseUrl/user-meal-plans/$id';
  static String get userMealPlansFromDailyMenu =>
      '$baseUrl/user-meal-plans/from-daily-menu';
  static String userMealPlanCompleteItem(String itemId) =>
      '$baseUrl/user-meal-plans/items/$itemId/complete';

  // MealPlan endpoints (Admin/Full CRUD)
  static String get mealPlans => '$baseUrl/MealPlan';
  static String get mealPlansCreateEmpty => '$baseUrl/MealPlan/empty';
  static String get mealPlansCreateWithItems => '$baseUrl/MealPlan';
  static String mealPlanById(String id) => '$baseUrl/MealPlan/$id';
  static String mealPlanItems(String planId) =>
      '$baseUrl/MealPlan/$planId/items';
  static String mealPlanItem(String planId, String itemId) =>
      '$baseUrl/MealPlan/$planId/items/$itemId';
  static String mealPlanItemStatus(String planId, String itemId) =>
      '$baseUrl/MealPlan/$planId/items/$itemId/status';
  static String mealPlanItemConvertToLog(String planId, String itemId) =>
      '$baseUrl/MealPlan/$planId/items/$itemId/convert-to-log';
  static String mealPlanCommit(String planId) =>
      '$baseUrl/MealPlan/$planId/commit';
  static String mealPlanDuplicate(String planId) =>
      '$baseUrl/MealPlan/$planId/duplicate';
  static String get mealPlanDashboard => '$baseUrl/MealPlan/dashboard';
  static String get mealPlanCompare => '$baseUrl/MealPlan/compare';
  static String get mealPlanStreaks => '$baseUrl/MealPlan/streaks';

  static String get notificationSettings => '$baseUrl/Notification/settings';
  static String get notificationSettingsReset =>
      '$baseUrl/Notification/settings/reset';
  static String get notificationChannels => '$baseUrl/Notification/channels';
  static String get notifications => '$baseUrl/Notification';
  static String notificationById(String id) => '$baseUrl/Notification/$id';
  static String get notificationUnreadCount =>
      '$baseUrl/Notification/unread-count';
  static String notificationMarkRead(String id) =>
      '$baseUrl/Notification/$id/read';
  static String get notificationMarkAllRead => '$baseUrl/Notification/read-all';
  static String notificationDelete(String id) => '$baseUrl/Notification/$id';
  static String get notificationDeleteBatch => '$baseUrl/Notification/batch';
  static String get notificationMealPlanRemind =>
      '$baseUrl/Notification/meal-plan-remind';
  static String get notificationSchedulePrepReminder =>
      '$baseUrl/Notification/schedule-prep-reminder';
  static String get notificationSend => '$baseUrl/Notification/send';
  static String notificationTrackOpen(String id) =>
      '$baseUrl/Notification/$id/track/open';
  static String notificationTrackClick(String id) =>
      '$baseUrl/Notification/$id/track/click';
  static String notificationTrackActionComplete(String id) =>
      '$baseUrl/Notification/$id/track/action-complete';
  static String get notificationAnalytics => '$baseUrl/Notification/analytics';
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

  // FCM Push Notification endpoints
  static String get fcmRegister => '$baseUrl/Fcm/register';
  static String get fcmRemove => '$baseUrl/Fcm/remove';
  static String get fcmTokens => '$baseUrl/Fcm/tokens';
  static String get fcmSend => '$baseUrl/Fcm/send';

  // AiAssistant endpoints
  static String get aiAssistantConversations =>
      '$baseUrl/AiAssistant/conversations';
  static String aiAssistantConversationById(String id) =>
      '$baseUrl/AiAssistant/conversations/$id';
  static String aiAssistantConversationMessages(String conversationId) =>
      '$baseUrl/AiAssistant/conversations/$conversationId/messages';
  static String aiAssistantConversationSummary(String conversationId) =>
      '$baseUrl/AiAssistant/conversations/$conversationId/summary';
  static String aiAssistantMessageFeedback(
    String conversationId,
    String messageId,
  ) =>
      '$baseUrl/AiAssistant/conversations/$conversationId/messages/$messageId/feedback';
  static String get aiAssistantContext => '$baseUrl/AiAssistant/context';
  static String get aiAssistantProfile => '$baseUrl/AiAssistant/profile';
  static String get aiAssistantSuggestions =>
      '$baseUrl/AiAssistant/suggestions';
}
