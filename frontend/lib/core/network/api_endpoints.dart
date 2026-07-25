import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  /// Backend production (AWS Lightsail + Nginx).
  static const String productionBaseUrl = 'https://api.menugreen.food/api';

  /// Backend local mặc định cho Android Emulator.
  static const String localBaseUrl = 'http://10.0.2.2:5000/api';

  /// Ưu tiên: env file > environment variable > default
  static String get baseUrl {
    // 1. Check dotenv file first
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return _normalizeBaseUrl(envUrl);
    }

    // 2. Fallback to default production
    return productionBaseUrl;
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return productionBaseUrl;
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static String get realtimeBaseUrl {
    final uri = Uri.parse(baseUrl);
    final segments = uri.pathSegments.toList();
    if (segments.isNotEmpty && segments.last.toLowerCase() == 'api') {
      segments.removeLast();
    }
    return uri
        .replace(path: segments.isEmpty ? '' : '/${segments.join('/')}')
        .toString()
        .replaceFirst(RegExp(r'/$'), '');
  }

  static String get notificationHub => '$realtimeBaseUrl/notificationHub';

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
  static String mealPlanScanMeals(String planId) =>
      '$baseUrl/MealPlan/$planId/scan-meals';
  static String get ingredientSearch => '$baseUrl/Ingredient/search';
  static String ingredientById(String id) => '$baseUrl/Ingredient/$id';
  static String ingredientRecipes(String id) =>
      '$baseUrl/Ingredient/$id/recipes';
  // Recommendation endpoints
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
  static String get userMealPlansFromDailyMenu =>
      '$baseUrl/user-meal-plans/from-daily-menu';
  static String userMealPlanCompleteItem(String itemId) =>
      '$baseUrl/user-meal-plans/items/$itemId/complete';
  static String userMealPlanToggleItem(String itemId, bool isCompleted) =>
      '$baseUrl/user-meal-plans/items/$itemId/toggle?isCompleted=$isCompleted';

  // MealPlan endpoints (Admin/Full CRUD)
  static String get mealPlans => '$baseUrl/MealPlan';
  static String get mealPlansCreateEmpty => '$baseUrl/MealPlan/empty';
  static String get mealPlansCreateWithItems => '$baseUrl/MealPlan';
  static String mealPlanById(String id) => '$baseUrl/MealPlan/$id';
  static String get mealPlanGenerateByBudget =>
      '$baseUrl/MealPlan/generate-by-budget';
  static String mealPlanGroceryList(String id) =>
      '${mealPlanById(id)}/grocery-list';
  static String mealPlanAlternatives(String planId, String itemId) =>
      '${mealPlanById(planId)}/alternatives/$itemId';
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
  static String mealPlanBudgetStatus(String planId) =>
      '$baseUrl/MealPlan/$planId/budget-status';
  static String mealPlanSaveOfficeScan(String planId) =>
      '$baseUrl/MealPlan/$planId/save-office-scan';
  static String mealPlanReplaceItem(String planId, String itemId) =>
      '$baseUrl/MealPlan/$planId/items/$itemId/replace';
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
  static String get mealTemplates => '$baseUrl/MealTemplate';
  static String mealTemplateById(String id) => '$mealTemplates/$id';
  static String mealTemplateLog(String id) => '${mealTemplateById(id)}/log';
  static String mealTemplateDuplicate(String id) =>
      '${mealTemplateById(id)}/duplicate';
  static String mealTemplateUsage(String id) => '${mealTemplateById(id)}/usage';
  static String mealTemplateFromLog(String mealLogId) =>
      '$mealTemplates/from-log/$mealLogId';
  static String get microLearningRecommended =>
      '$baseUrl/MicroLearning/cards/recommended';
  static String get microLearningLibrary =>
      '$baseUrl/MicroLearning/cards/library';
  static String microLearningCardById(String id) =>
      '$baseUrl/MicroLearning/cards/$id';
  static String get microLearningCategories =>
      '$baseUrl/MicroLearning/categories';
  static String microLearningCardAction(String id) =>
      '${microLearningCardById(id)}/action';
  static String get microLearningSavedCards =>
      '$baseUrl/MicroLearning/cards/saved';
  static String microLearningSubmitQuiz(String id) =>
      '${microLearningCardById(id)}/quiz/submit';

  static String get reminderProfile => '$baseUrl/Reminder/profile';
  static String get reminderProfileRecalculate =>
      '$reminderProfile/recalculate';
  static String get scheduledReminders => '$baseUrl/Reminder/scheduled';
  static String scheduledReminderById(String id) => '$scheduledReminders/$id';
  static String scheduledReminderSnooze(String id) =>
      '${scheduledReminderById(id)}/snooze';

  static String get subscriptionPlans => '$baseUrl/UserSubscription/plans';
  static String get subscriptionSubscribe =>
      '$baseUrl/UserSubscription/subscribe';
  static String get subscriptionRenew => '$baseUrl/UserSubscription/renew';
  static String get subscriptionCancel => '$baseUrl/UserSubscription/cancel';
  static String get subscriptionCurrent => '$baseUrl/UserSubscription/me';
  static String get subscriptionActive => '$baseUrl/UserSubscription/me/active';
  static String get subscriptionEntitlements =>
      '$baseUrl/UserSubscription/me/entitlements';
  static String get subscriptionHistory =>
      '$baseUrl/UserSubscription/me/history';

  // Premium Programs endpoints (catalog purchases - legacy; catalog seeded empty in Phase 8)
  static String get premiumPrograms => '$baseUrl/PremiumPrograms';
  static String premiumProgramCheckout(String id) =>
      '$baseUrl/PremiumPrograms/$id/checkout';
  static String premiumProgramActivate(String id) =>
      '$baseUrl/PremiumPrograms/$id/activate';
  static String get myActivePremiumProgram =>
      '$baseUrl/PremiumPrograms/my-active';
  static String get myPremiumPrograms => '$baseUrl/PremiumPrograms/my-programs';
  static String get premiumProgramCheckIn => '$baseUrl/PremiumPrograms/checkin';
  static String premiumProgramWeekCheckIn(int weekNumber) =>
      '$baseUrl/PremiumPrograms/my-active/milestones/$weekNumber/checkin';
  static String get premiumProgramGraduate =>
      '$baseUrl/PremiumPrograms/my-active/graduate';
  static String premiumProgramReport(String userProgramId) =>
      '$baseUrl/PremiumPrograms/my-programs/$userProgramId/wrap-up-report';
  static String premiumProgramCertificate(String userProgramId) =>
      '$baseUrl/PremiumPrograms/my-programs/$userProgramId/certificate';

  // PT Review endpoints (Phase 8: split into Gymer-side + Coach-side)
  static String get ptReviewMyRequests => '$baseUrl/PtReview/my-requests';
  static String get ptReviewReports => '$baseUrl/PtReview/reports';
  static String ptReviewResult(String requestId) =>
      '$baseUrl/PtReview/requests/$requestId/result';
  static String ptReviewApply(String requestId) =>
      '$baseUrl/PtReview/requests/$requestId/apply';
  static String ptReviewReject(String requestId) =>
      '$baseUrl/PtReview/requests/$requestId/reject';
  static String get ptReviewMyPersonalPrograms =>
      '$baseUrl/PtReview/my-personal-programs';
  static String ptReviewAcceptPersonalProgram(String requestId) =>
      '$baseUrl/PtReview/personal-programs/$requestId/accept';

  // Coach-side endpoints (Phase 8: coach creates PersonalProgram)
  static String get coachCreatePersonalProgram =>
      '$baseUrl/PtReview/coach/personal-programs';
  static String coachListSentPersonalPrograms([String? clientId]) {
    final base = '$baseUrl/PtReview/coach/personal-programs';
    if (clientId == null || clientId.isEmpty) return base;
    return '$base?clientId=$clientId';
  }

  static String get sepayCreateOrder => '$baseUrl/payments/sepay/create-order';
  static String get sepayCreateRenewOrder =>
      '$baseUrl/payments/sepay/create-renew-order';
  static String get sepayPendingOrders => '$baseUrl/payments/sepay/pending';
  static String sepayPaymentStatus(String paymentId) =>
      '$baseUrl/payments/sepay/$paymentId';

  static String get allergies => '$baseUrl/Allergy';
  static String get allergyCatalog => '$baseUrl/Allergy/catalog';
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

  // Vietnam Local Features (10-vietnam-local-features.md)
  // Daily Starter (2.12)
  static String get dailyStarterToday => '$baseUrl/DailyStarter/today';
  static String get dailyStarterFeaturedMeals =>
      '$baseUrl/DailyStarter/featured-meals';
  static String get dailyStarterSelectMeal =>
      '$baseUrl/DailyStarter/select-meal';
  static String get dailyStarterStartLog => '$baseUrl/DailyStarter/start-log';
  static String get dailyStarterRecommendations =>
      '$baseUrl/DailyStarter/recommendations';
  static String get dailyStarterPersonalization =>
      '$baseUrl/DailyStarter/personalization';
  static String get dailyStarterSavePreference =>
      '$baseUrl/DailyStarter/save-preference';

  // Gym/PT Goals (2.13)
  static String get gymGoalsMe => '$baseUrl/GymGoals/me';
  static String get gymGoals => '$baseUrl/GymGoals';
  static String get gymGoalsSetup => '$baseUrl/GymGoals/setup';
  static String get gymGoalsPlan => '$baseUrl/GymGoals/plan';
  static String get gymGoalsRecalibrate => '$baseUrl/GymGoals/recalibrate';
  static String get gymGoalsAlerts => '$baseUrl/GymGoals/alerts';
  static String get gymGoalsCoachReport => '$baseUrl/GymGoals/coach-report';

  // Food Capture (2.14)
  static String get foodCaptureQuickTemplate =>
      '$baseUrl/Nutrition/food-capture/quick-template';
  static String get foodCaptureTemplateFromPlan =>
      '$baseUrl/Nutrition/food-capture/template-from-plan';
  static String get foodCaptureFallbackEstimate =>
      '$baseUrl/Nutrition/food-capture/fallback-estimate';
  static String get foodCaptureSaveAsQuickAdd =>
      '$baseUrl/Nutrition/food-capture/save-as-quick-add';

  // Safety/Compliance (2.15)
  static String get safetyDisclaimer => '$baseUrl/Safety/disclaimer';
  static String get safetyConsent => '$baseUrl/Safety/consent';
  static String get safetyAlerts => '$baseUrl/Safety/alerts';
  static String get safetyExportData => '$baseUrl/Safety/export-data';
  static String get safetyDeleteData => '$baseUrl/Safety/delete-data';
  static String get safetyReportIssue => '$baseUrl/Safety/report-issue';

  // Local Preferences (2.11) — alias trên UserAiProfile
  static String get localPreferences => '$baseUrl/Nutrition/local-preferences';
  static String get localRecommendationsBudgetAware =>
      '$baseUrl/Nutrition/recommendations/budget-aware';
  static String get localRecommendationsLocalFriendly =>
      '$baseUrl/Nutrition/recommendations/local-friendly';
  static String get localRecommendationsFeedback =>
      '$baseUrl/Nutrition/recommendations/feedback';
  static String get mealLogVnSuggestions =>
      '$baseUrl/Nutrition/meal-log/vn/suggestions';
  static String get mealLogVnQuickAdd =>
      '$baseUrl/Nutrition/meal-log/vn/quick-add';
  static String get mealLogVnHistory =>
      '$baseUrl/Nutrition/meal-log/vn/history';
  static String get mealLogVn => '$baseUrl/Nutrition/meal-log/vn';
  static String get nutritionDiscoveryLocal =>
      '$baseUrl/Nutrition/discovery/local';
  static String get nutritionDiscoveryLocalByBudget =>
      '$baseUrl/Nutrition/discovery/local/by-budget';

  // Planned vs Actual (2.17)
  static String get plannedVsActualSummary =>
      '$baseUrl/Analytics/planned-vs-actual';
  static String get plannedVsActualAdherenceScore =>
      '$baseUrl/Analytics/planned-vs-actual/adherence-score';
  static String get plannedVsActualDriftAnalysis =>
      '$baseUrl/Analytics/planned-vs-actual/drift-analysis';
  static String get plannedVsActualRecommendations =>
      '$baseUrl/Analytics/planned-vs-actual/recommendations';
  static String get plannedVsActualMonthlyReport =>
      '$baseUrl/Analytics/planned-vs-actual/monthly-report';
  static String get plannedVsActualRecalibrate =>
      '$baseUrl/Analytics/planned-vs-actual/recalibrate';

  // Ingredient Substitution Preference (2.18)
  static String get ingredientSubstitutesPreferences =>
      '$baseUrl/Ingredient/preferences/substitutes';
  static String ingredientSubstitutePreferenceById(String id) =>
      '$baseUrl/Ingredient/preferences/substitutes/$id';

  // Lucky Wheel (2.20)
  static String get luckyWheelFoods => '$baseUrl/LuckyWheel/foods';
  static String get luckyWheelApply => '$baseUrl/LuckyWheel/apply';
}
