import { apiClient } from "@/lib/api/client";
import { apiEndpoints } from "@/lib/api/endpoints";

export interface NotificationStats {
  pendingProcessed: number;
  sent: number;
  failed: number;
  skipped: number;
}

export const notificationAdminApi = {
  dispatch(): Promise<{ message: string }> {
    return apiClient.post<{ message: string }>(
      apiEndpoints.notificationAdmin.dispatch,
      {},
    );
  },

  getPendingStats(): Promise<NotificationStats> {
    return apiClient.get<NotificationStats>(
      apiEndpoints.notificationAdmin.pending,
    );
  },
};
