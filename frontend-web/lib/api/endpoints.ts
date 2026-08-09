const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:5000/api";

export const apiEndpoints = {
  baseUrl: API_BASE_URL,
  auth: {
    login: `${API_BASE_URL}/Auth/login`,
    refreshToken: `${API_BASE_URL}/Auth/refresh-token`,
    logout: `${API_BASE_URL}/Auth/logout`,
  },
  user: {
    assignRole: (id: string) => `${API_BASE_URL}/User/${id}/assign-role`,
  },
  adminUser: {
    list: `${API_BASE_URL}/User`,
    byId: (id: string) => `${API_BASE_URL}/User/${id}`,
    lock: (id: string) => `${API_BASE_URL}/User/${id}/lock`,
    unlock: (id: string) => `${API_BASE_URL}/User/${id}/unlock`,
  },
  dashboard: {
    metrics: `${API_BASE_URL}/Dashboard/metrics`,
    revenue: `${API_BASE_URL}/Dashboard/revenue`,
    users: `${API_BASE_URL}/Dashboard/users`,
  },
  food: {
    base: `${API_BASE_URL}/Food`,
    byId: (id: string) => `${API_BASE_URL}/Food/${id}`,
  },
  adminFood: {
    allergies: (id: string) => `${API_BASE_URL}/admin/foods/${id}/allergies`,
  },
  ingredient: {
    base: `${API_BASE_URL}/Ingredient`,
    search: `${API_BASE_URL}/Ingredient/search`,
    byId: (id: string) => `${API_BASE_URL}/Ingredient/${id}`,
  },
  recipe: {
    base: `${API_BASE_URL}/Recipe`,
    search: `${API_BASE_URL}/Recipe/search`,
    byId: (id: string) => `${API_BASE_URL}/Recipe/${id}`,
  },
  subscriptionPlan: {
    base: `${API_BASE_URL}/SubscriptionPlan`,
    byId: (id: string) => `${API_BASE_URL}/SubscriptionPlan/${id}`,
    status: (id: string) => `${API_BASE_URL}/SubscriptionPlan/${id}/status`,
  },
  mealPlan: {
    base: `${API_BASE_URL}/MealPlan`,
    byId: (id: string) => `${API_BASE_URL}/MealPlan/${id}`,
    status: (id: string) => `${API_BASE_URL}/MealPlan/${id}/status`,
    distribute: (id: string) => `${API_BASE_URL}/MealPlan/${id}/distribute`,
  },
  aiAdmin: {
    overview: `${API_BASE_URL}/AiAdmin/overview`,
    health: `${API_BASE_URL}/AiAdmin/health`,
  },
  nutritionAssistant: {
    chat: `${API_BASE_URL}/NutritionAssistant/chat`,
    conversations: `${API_BASE_URL}/NutritionAssistant/conversations`,
    conversationById: (id: string) =>
      `${API_BASE_URL}/NutritionAssistant/conversations/${id}`,
  },
  analytics: {
    base: `${API_BASE_URL}/Analytics`,
    dashboard: `${API_BASE_URL}/Analytics/dashboard`,
    summary: `${API_BASE_URL}/Analytics/summary`,
    metrics: `${API_BASE_URL}/Analytics/metrics`,
    topEvents: `${API_BASE_URL}/Analytics/top-events`,
    funnel: `${API_BASE_URL}/Analytics/funnel`,
    mealOnboardingFunnel: `${API_BASE_URL}/Analytics/funnel/meal-onboarding`,
    subscriptionFunnel: `${API_BASE_URL}/Analytics/funnel/subscription`,
    cohort: `${API_BASE_URL}/Analytics/cohort`,
    churnRisk: `${API_BASE_URL}/Analytics/churn-risk`,
    inactiveUsers: `${API_BASE_URL}/Analytics/inactive-users`,
    reactivationOpportunities: `${API_BASE_URL}/Analytics/reactivation-opportunities`,
    activityLog: `${API_BASE_URL}/Analytics/activity-log`,
    // Nutrition Analytics
    nutritionDashboard: `${API_BASE_URL}/Analytics/nutrition/dashboard`,
    nutritionMacroDistribution: `${API_BASE_URL}/Analytics/nutrition/macro-distribution`,
    nutritionGoalAchievement: `${API_BASE_URL}/Analytics/nutrition/goal-achievement`,
    nutritionTopFoods: `${API_BASE_URL}/Analytics/nutrition/top-foods`,
    nutritionCalorieDistribution: `${API_BASE_URL}/Analytics/nutrition/calorie-distribution`,
    nutritionMealTypeBreakdown: `${API_BASE_URL}/Analytics/nutrition/meal-type-breakdown`,
    nutritionUserInsights: `${API_BASE_URL}/Analytics/nutrition/user-insights`,
  },
  notificationAdmin: {
    dispatch: `${API_BASE_URL}/admin/notifications/dispatch`,
    pending: `${API_BASE_URL}/admin/notifications/pending`,
  },
  jobs: {
    trigger: (jobName: string) => `${API_BASE_URL}/admin/jobs/trigger/${jobName}`,
  },
  migrations: {
    status: `${API_BASE_URL}/admin/migrations/status`,
    history: `${API_BASE_URL}/admin/migrations/history`,
    apply: `${API_BASE_URL}/admin/migrations/apply`,
  },
} as const;

export function withQuery(
  baseUrl: string,
  params: Record<string, string | number | boolean | null | undefined>,
): string {
  const query = new URLSearchParams();

  for (const [key, value] of Object.entries(params)) {
    if (value == null || value === "") continue;
    query.set(key, String(value));
  }

  const qs = query.toString();
  return qs ? `${baseUrl}?${qs}` : baseUrl;
}
