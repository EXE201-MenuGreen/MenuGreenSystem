import { apiClient } from "@/lib/api/client";
import { apiEndpoints, withQuery } from "@/lib/api/endpoints";
import type {
  AnalyticsDashboard,
  AnalyticsSummary,
  MetricPoint,
  TopEvent,
  FunnelStep,
  CohortData,
  ChurnRiskUser,
  InactiveUser,
  ReactivationOpportunity,
  ActivityLogEntry,
  NutritionDashboardResponse,
  MacroDistributionResponse,
  GoalAchievementResponse,
  TopFoodsResponse,
  CalorieDistributionResponse,
  MealTypeBreakdownResponse,
  UserInsightsResponse,
  RevenueTimeSeriesPoint,
  RevenueByPlan,
} from "../types/analytics-types";

// ============================================
// GENERAL ANALYTICS
// ============================================

export async function getAnalyticsDashboard(): Promise<AnalyticsDashboard> {
  return apiClient.get<AnalyticsDashboard>(apiEndpoints.analytics.dashboard);
}

export async function getAnalyticsSummary(
  from: string,
  to: string
): Promise<AnalyticsSummary> {
  const url = withQuery(apiEndpoints.analytics.summary, { from, to });
  return apiClient.get<AnalyticsSummary>(url);
}

export async function getMetrics(
  from: string,
  to: string
): Promise<MetricPoint[]> {
  const url = withQuery(apiEndpoints.analytics.metrics, { from, to });
  return apiClient.get<MetricPoint[]>(url);
}

export async function getTopEvents(
  from: string,
  to: string
): Promise<TopEvent[]> {
  const url = withQuery(apiEndpoints.analytics.topEvents, { from, to });
  return apiClient.get<TopEvent[]>(url);
}

// ============================================
// FUNNEL ANALYTICS
// ============================================

export async function getFunnel(): Promise<FunnelStep[]> {
  return apiClient.get<FunnelStep[]>(apiEndpoints.analytics.funnel);
}

export async function getMealOnboardingFunnel(): Promise<FunnelStep[]> {
  return apiClient.get<FunnelStep[]>(
    apiEndpoints.analytics.mealOnboardingFunnel
  );
}

export async function getSubscriptionFunnel(): Promise<FunnelStep[]> {
  return apiClient.get<FunnelStep[]>(
    apiEndpoints.analytics.subscriptionFunnel
  );
}

// ============================================
// COHORT ANALYTICS
// ============================================

export async function getCohort(): Promise<CohortData[]> {
  return apiClient.get<CohortData[]>(apiEndpoints.analytics.cohort);
}

// ============================================
// CHURN & RETENTION
// ============================================

export async function getChurnRisk(): Promise<ChurnRiskUser[]> {
  return apiClient.get<ChurnRiskUser[]>(apiEndpoints.analytics.churnRisk);
}

export async function getInactiveUsers(): Promise<InactiveUser[]> {
  return apiClient.get<InactiveUser[]>(apiEndpoints.analytics.inactiveUsers);
}

export async function getReactivationOpportunities(): Promise<
  ReactivationOpportunity[]
> {
  return apiClient.get<ReactivationOpportunity[]>(
    apiEndpoints.analytics.reactivationOpportunities
  );
}

// ============================================
// ACTIVITY LOG
// ============================================

export async function getActivityLog(
  params?: {
    userId?: string;
    from?: string;
    to?: string;
    action?: string;
    page?: number;
    pageSize?: number;
  }
): Promise<ActivityLogEntry[]> {
  const url = withQuery(apiEndpoints.analytics.activityLog, {
    userId: params?.userId,
    from: params?.from,
    to: params?.to,
    action: params?.action,
  });
  return apiClient.get<ActivityLogEntry[]>(url);
}

// ============================================
// NUTRITION ANALYTICS
// ============================================

export async function getNutritionDashboard(
  from: string,
  to: string
): Promise<NutritionDashboardResponse> {
  const url = withQuery(apiEndpoints.analytics.nutritionDashboard, {
    from,
    to,
  });
  return apiClient.get<NutritionDashboardResponse>(url);
}

export async function getMacroDistribution(
  from: string,
  to: string
): Promise<MacroDistributionResponse> {
  const url = withQuery(apiEndpoints.analytics.nutritionMacroDistribution, {
    from,
    to,
  });
  return apiClient.get<MacroDistributionResponse>(url);
}

export async function getGoalAchievement(
  from: string,
  to: string
): Promise<GoalAchievementResponse> {
  const url = withQuery(apiEndpoints.analytics.nutritionGoalAchievement, {
    from,
    to,
  });
  return apiClient.get<GoalAchievementResponse>(url);
}

export async function getTopFoods(
  from: string,
  to: string,
  limit = 10,
  sortBy = "count"
): Promise<TopFoodsResponse> {
  const url = withQuery(apiEndpoints.analytics.nutritionTopFoods, {
    from,
    to,
    limit,
    sortBy,
  });
  return apiClient.get<TopFoodsResponse>(url);
}

export async function getCalorieDistribution(
  from: string,
  to: string
): Promise<CalorieDistributionResponse> {
  const url = withQuery(
    apiEndpoints.analytics.nutritionCalorieDistribution,
    { from, to }
  );
  return apiClient.get<CalorieDistributionResponse>(url);
}

export async function getMealTypeBreakdown(
  from: string,
  to: string
): Promise<MealTypeBreakdownResponse> {
  const url = withQuery(apiEndpoints.analytics.nutritionMealTypeBreakdown, {
    from,
    to,
  });
  return apiClient.get<MealTypeBreakdownResponse>(url);
}

export async function getUserInsights(
  from: string,
  to: string
): Promise<UserInsightsResponse> {
  const url = withQuery(apiEndpoints.analytics.nutritionUserInsights, {
    from,
    to,
  });
  return apiClient.get<UserInsightsResponse>(url);
}

// ============================================
// COMBINED NUTRITION DATA FETCHER
// ============================================

export interface NutritionDashboardData {
  dashboard: NutritionDashboardResponse | null;
  macroDistribution: MacroDistributionResponse | null;
  goalAchievement: GoalAchievementResponse | null;
  topFoods: TopFoodsResponse | null;
  calorieDistribution: CalorieDistributionResponse | null;
  mealTypeBreakdown: MealTypeBreakdownResponse | null;
  userInsights: UserInsightsResponse | null;
  isLoading: boolean;
  error: string | null;
}

export async function fetchAllNutritionAnalytics(
  from: string,
  to: string
): Promise<NutritionDashboardData> {
  const results = await Promise.allSettled([
    getNutritionDashboard(from, to),
    getMacroDistribution(from, to),
    getGoalAchievement(from, to),
    getTopFoods(from, to),
    getCalorieDistribution(from, to),
    getMealTypeBreakdown(from, to),
    getUserInsights(from, to),
  ]);

  const [dashboard, macroDistribution, goalAchievement, topFoods, calorieDistribution, mealTypeBreakdown, userInsights] =
    results.map((r) => (r.status === "fulfilled" ? r.value : null));

  const errors = results
    .filter((r) => r.status === "rejected")
    .map((r) => (r as PromiseRejectedResult).reason?.message || "Unknown error")
    .join(", ");

  return {
    dashboard: dashboard as NutritionDashboardResponse | null,
    macroDistribution: macroDistribution as MacroDistributionResponse | null,
    goalAchievement: goalAchievement as GoalAchievementResponse | null,
    topFoods: topFoods as TopFoodsResponse | null,
    calorieDistribution: calorieDistribution as CalorieDistributionResponse | null,
    mealTypeBreakdown: mealTypeBreakdown as MealTypeBreakdownResponse | null,
    userInsights: userInsights as UserInsightsResponse | null,
    isLoading: false,
    error: errors || null,
  };
}

// ============================================
// REVENUE ANALYTICS
// ============================================

export interface RevenueTimeSeriesResponse {
  points: RevenueTimeSeriesPoint[];
  totalRevenue: number;
  transactionCount: number;
  changeVsPrevious: number;
}

export interface RevenueByPlanResponse {
  plans: RevenueByPlan[];
  totalRevenue: number;
  totalSubscribers: number;
}

export async function getRevenueTimeSeries(
  from: string,
  to: string
): Promise<RevenueTimeSeriesResponse> {
  const url = withQuery(apiEndpoints.dashboard.revenueTimeSeries, { from, to });
  return apiClient.get<RevenueTimeSeriesResponse>(url);
}

export async function getRevenueByPlan(
  from: string,
  to: string
): Promise<RevenueByPlanResponse> {
  const url = withQuery(apiEndpoints.dashboard.revenueByPlan, { from, to });
  return apiClient.get<RevenueByPlanResponse>(url);
}
