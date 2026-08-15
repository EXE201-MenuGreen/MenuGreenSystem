"use client";

import { useCallback, useEffect, useState } from "react";
import { dashboardApi } from "@/features/dashboard/api/dashboard-api";
import type {
  DashboardMetrics,
  RevenueDashboardMetrics,
  DashboardUserMetrics,
} from "@/features/dashboard/types";
import { getErrorMessage } from "@/lib/api/errors";

export function useDashboardMetrics(topCount = 10) {
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [revenue, setRevenue] = useState<RevenueDashboardMetrics | null>(null);
  const [userMetrics, setUserMetrics] = useState<DashboardUserMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const [metricsData, revenueData, userData] = await Promise.all([
        dashboardApi.getMetrics(topCount),
        dashboardApi.getRevenueMetrics(),
        dashboardApi.getUserMetrics(),
      ]);
      setMetrics(metricsData);
      setRevenue(revenueData);
      setUserMetrics(userData);
    } catch (err) {
      setError(getErrorMessage(err, "Không thể tải chỉ số tổng quan"));
    } finally {
      setLoading(false);
    }
  }, [topCount]);

  useEffect(() => {
    const timeoutId = window.setTimeout(reload, 0);
    return () => window.clearTimeout(timeoutId);
  }, [reload]);

  return { metrics, revenue, userMetrics, loading, error, reload };
}
