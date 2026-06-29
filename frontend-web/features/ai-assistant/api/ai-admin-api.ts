import type { AiAdminOverview, AiBridgeHealth } from "@/features/ai-assistant/types";
import { apiClient } from "@/lib/api/client";
import { apiEndpoints, withQuery } from "@/lib/api/endpoints";

export const aiAdminApi = {
  getOverview(recentTake = 10): Promise<AiAdminOverview> {
    return apiClient.get<AiAdminOverview>(
      withQuery(apiEndpoints.aiAdmin.overview, { recentTake }),
    );
  },

  getHealth(): Promise<AiBridgeHealth> {
    return apiClient.get<AiBridgeHealth>(apiEndpoints.aiAdmin.health);
  },
};
