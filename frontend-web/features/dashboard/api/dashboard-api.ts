import { apiClient } from "@/lib/api/client";
import { apiEndpoints, withQuery } from "@/lib/api/endpoints";
import type {
  DashboardMetrics,
  RevenueDashboardMetrics,
} from "@/features/dashboard/types";

export const dashboardApi = {
  getMetrics(topCount = 10): Promise<DashboardMetrics> {
    return apiClient.get<DashboardMetrics>(
      withQuery(apiEndpoints.dashboard.metrics, { topCount }),
    );
  },

  getRevenueMetrics(): Promise<RevenueDashboardMetrics> {
    return apiClient.get<RevenueDashboardMetrics>(
      apiEndpoints.dashboard.revenue,
    );
  },
};
