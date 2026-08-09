"use client";

import { useState, useCallback, useEffect } from "react";
import {
  fetchAllNutritionAnalytics,
  getAnalyticsDashboard,
  getMetrics,
  getTopEvents,
  getFunnel,
  getMealOnboardingFunnel,
  getSubscriptionFunnel,
  getCohort,
  getChurnRisk,
  getInactiveUsers,
  getActivityLog,
  getRevenueTimeSeries,
  getRevenueByPlan,
  type NutritionDashboardData,
} from "../api/analytics-api";
import type {
  AnalyticsDashboard,
  MetricPoint,
  TopEvent,
  FunnelStep,
  CohortData,
  ChurnRiskUser,
  InactiveUser,
  ActivityLogEntry,
  DatePreset,
  DateRange,
  RevenueTimeSeriesPoint,
  RevenueByPlan,
} from "../types/analytics-types";

const DEFAULT_PRESET: DatePreset = "30days";

function getDateRangeFromPreset(preset: DatePreset): DateRange {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  switch (preset) {
    case "today":
      return { from: today, to: new Date(today.getTime() + 86400000 - 1) };
    case "7days":
      return {
        from: new Date(today.getTime() - 7 * 86400000),
        to: new Date(today.getTime() + 86400000 - 1),
      };
    case "30days":
    default:
      return {
        from: new Date(today.getTime() - 30 * 86400000),
        to: new Date(today.getTime() + 86400000 - 1),
      };
    case "90days":
      return {
        from: new Date(today.getTime() - 90 * 86400000),
        to: new Date(today.getTime() + 86400000 - 1),
      };
  }
}

function formatDate(date: Date): string {
  return date.toISOString();
}

// ============================================
// NUTRITION ANALYTICS HOOK
// ============================================

export interface UseNutritionAnalyticsOptions {
  preset?: DatePreset;
  customRange?: DateRange;
  enabled?: boolean;
}

export function useNutritionAnalytics(
  options: UseNutritionAnalyticsOptions = {}
) {
  const { preset = DEFAULT_PRESET, customRange, enabled = true } = options;

  const [data, setData] = useState<NutritionDashboardData>({
    dashboard: null,
    macroDistribution: null,
    goalAchievement: null,
    topFoods: null,
    calorieDistribution: null,
    mealTypeBreakdown: null,
    userInsights: null,
    isLoading: enabled,
    error: null,
  });

  const [datePreset, setDatePreset] = useState<DatePreset>(preset);
  const [dateRange, setDateRange] = useState<DateRange>(
    customRange || getDateRangeFromPreset(preset)
  );

  const fetchData = useCallback(async () => {
    if (!enabled) return;

    setData((prev) => ({ ...prev, isLoading: true, error: null }));

    try {
      const range = customRange || getDateRangeFromPreset(datePreset);
      setDateRange(range);

      const from = formatDate(range.from);
      const to = formatDate(range.to);

      const result = await fetchAllNutritionAnalytics(from, to);
      setData({ ...result, isLoading: false });
    } catch (error) {
      setData((prev) => ({
        ...prev,
        isLoading: false,
        error: error instanceof Error ? error.message : "Failed to fetch data",
      }));
    }
  }, [datePreset, customRange, enabled]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const changePreset = useCallback((newPreset: DatePreset) => {
    setDatePreset(newPreset);
    if (newPreset !== "custom") {
      setDateRange(getDateRangeFromPreset(newPreset));
    }
  }, []);

  const changeDateRange = useCallback((range: DateRange) => {
    setDatePreset("custom");
    setDateRange(range);
  }, []);

  return {
    ...data,
    datePreset,
    dateRange,
    changePreset,
    changeDateRange,
    refetch: fetchData,
  };
}

// ============================================
// GENERAL ANALYTICS HOOKS
// ============================================

export function useAnalyticsDashboard() {
  const [dashboard, setDashboard] = useState<AnalyticsDashboard | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await getAnalyticsDashboard();
      setDashboard(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch dashboard");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { dashboard, isLoading, error, refetch: fetch };
}

export function useAnalyticsMetrics(datePreset: DatePreset = "30days") {
  const [metrics, setMetrics] = useState<MetricPoint[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const range = getDateRangeFromPreset(datePreset);
      const data = await getMetrics(formatDate(range.from), formatDate(range.to));
      setMetrics(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch metrics");
    } finally {
      setIsLoading(false);
    }
  }, [datePreset]);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { metrics, isLoading, error, refetch: fetch };
}

export function useTopEvents(datePreset: DatePreset = "30days") {
  const [events, setEvents] = useState<TopEvent[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const range = getDateRangeFromPreset(datePreset);
      const data = await getTopEvents(
        formatDate(range.from),
        formatDate(range.to)
      );
      setEvents(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch top events");
    } finally {
      setIsLoading(false);
    }
  }, [datePreset]);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { events, isLoading, error, refetch: fetch };
}

export function useFunnel(type: "onboarding" | "subscription" = "onboarding") {
  const [funnel, setFunnel] = useState<FunnelStep[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data =
        type === "subscription"
          ? await getSubscriptionFunnel()
          : await getMealOnboardingFunnel();
      setFunnel(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch funnel");
    } finally {
      setIsLoading(false);
    }
  }, [type]);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { funnel, isLoading, error, refetch: fetch };
}

export function useCohort() {
  const [cohorts, setCohorts] = useState<CohortData[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await getCohort();
      setCohorts(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch cohort");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { cohorts, isLoading, error, refetch: fetch };
}

export function useChurnRisk() {
  const [users, setUsers] = useState<ChurnRiskUser[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await getChurnRisk();
      setUsers(data);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to fetch churn risk"
      );
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { users, isLoading, error, refetch: fetch };
}

export function useInactiveUsers() {
  const [users, setUsers] = useState<InactiveUser[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await getInactiveUsers();
      setUsers(data);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to fetch inactive users"
      );
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { users, isLoading, error, refetch: fetch };
}

export function useActivityLog(params?: {
  userId?: string;
  action?: string;
  pageSize?: number;
}) {
  const [logs, setLogs] = useState<ActivityLogEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await getActivityLog(params);
      setLogs(data);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to fetch activity log"
      );
    } finally {
      setIsLoading(false);
    }
  }, [params?.userId, params?.action, params?.pageSize]);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { logs, isLoading, error, refetch: fetch };
}

// ============================================
// REVENUE ANALYTICS HOOKS
// ============================================

export function useRevenueTimeSeries(datePreset: DatePreset = "30days") {
  const [data, setData] = useState<RevenueTimeSeriesPoint[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const range = getDateRangeFromPreset(datePreset);
      const result = await getRevenueTimeSeries(
        formatDate(range.from),
        formatDate(range.to)
      );
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch revenue time series");
    } finally {
      setIsLoading(false);
    }
  }, [datePreset]);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { data, isLoading, error, refetch: fetch };
}

export function useRevenueByPlan(datePreset: DatePreset = "30days") {
  const [data, setData] = useState<RevenueByPlan[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const range = getDateRangeFromPreset(datePreset);
      const result = await getRevenueByPlan(
        formatDate(range.from),
        formatDate(range.to)
      );
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch revenue by plan");
    } finally {
      setIsLoading(false);
    }
  }, [datePreset]);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { data, isLoading, error, refetch: fetch };
}
