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
    list: `${API_BASE_URL}/AdminUser`,
    byId: (id: string) => `${API_BASE_URL}/AdminUser/${id}`,
    lock: (id: string) => `${API_BASE_URL}/AdminUser/${id}/lock`,
    unlock: (id: string) => `${API_BASE_URL}/AdminUser/${id}/unlock`,
  },
  dashboard: {
    metrics: `${API_BASE_URL}/Dashboard/metrics`,
    revenue: `${API_BASE_URL}/Dashboard/revenue`,
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
    byId: (id: string) => `${API_BASE_URL}/Ingredient/${id}`,
  },
  recipe: {
    base: `${API_BASE_URL}/Recipe`,
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
