import { apiClient } from "@/lib/api/client";
import { apiEndpoints, withQuery } from "@/lib/api/endpoints";
import type {
  SubscriptionPlan,
  SubscriptionPlanListParams,
  SubscriptionPlanUpsertRequest,
} from "@/features/subscription-plans/types";
import type { MessageResponse, StatusRequest } from "@/types/common";

export const subscriptionPlanApi = {
  getAll(params?: SubscriptionPlanListParams): Promise<SubscriptionPlan[]> {
    return apiClient.get<SubscriptionPlan[]>(
      withQuery(apiEndpoints.subscriptionPlan.base, {
        isActive: params?.isActive,
      }),
    );
  },

  getById(id: string): Promise<SubscriptionPlan> {
    return apiClient.get<SubscriptionPlan>(
      apiEndpoints.subscriptionPlan.byId(id),
    );
  },

  create(payload: SubscriptionPlanUpsertRequest): Promise<SubscriptionPlan> {
    return apiClient.post<SubscriptionPlan>(
      apiEndpoints.subscriptionPlan.base,
      payload,
    );
  },

  update(
    id: string,
    payload: SubscriptionPlanUpsertRequest,
  ): Promise<SubscriptionPlan> {
    return apiClient.put<SubscriptionPlan>(
      apiEndpoints.subscriptionPlan.byId(id),
      payload,
    );
  },

  delete(id: string): Promise<MessageResponse> {
    return apiClient.delete<MessageResponse>(
      apiEndpoints.subscriptionPlan.byId(id),
    );
  },

  updateStatus(id: string, payload: StatusRequest): Promise<SubscriptionPlan> {
    return apiClient.patch<SubscriptionPlan>(
      apiEndpoints.subscriptionPlan.status(id),
      payload,
    );
  },
};
