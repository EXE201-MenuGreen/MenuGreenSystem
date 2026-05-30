import { apiClient } from "@/lib/api/client";
import { apiEndpoints, withQuery } from "@/lib/api/endpoints";
import type {
  MealPlan,
  MealPlanDistributeParams,
  MealPlanDistributionResult,
  MealPlanListParams,
  MealPlanUpsertRequest,
} from "@/features/meal-plans/types";
import type { MessageResponse, StatusRequest } from "@/types/common";

export const mealPlanApi = {
  getAll(params?: MealPlanListParams): Promise<MealPlan[]> {
    return apiClient.get<MealPlan[]>(
      withQuery(apiEndpoints.mealPlan.base, { isActive: params?.isActive }),
    );
  },

  getById(id: string): Promise<MealPlan> {
    return apiClient.get<MealPlan>(apiEndpoints.mealPlan.byId(id));
  },

  create(payload: MealPlanUpsertRequest): Promise<MealPlan> {
    return apiClient.post<MealPlan>(apiEndpoints.mealPlan.base, payload);
  },

  update(id: string, payload: MealPlanUpsertRequest): Promise<MealPlan> {
    return apiClient.put<MealPlan>(apiEndpoints.mealPlan.byId(id), payload);
  },

  delete(id: string): Promise<MessageResponse> {
    return apiClient.delete<MessageResponse>(apiEndpoints.mealPlan.byId(id));
  },

  updateStatus(id: string, payload: StatusRequest): Promise<MealPlan> {
    return apiClient.patch<MealPlan>(
      apiEndpoints.mealPlan.status(id),
      payload,
    );
  },

  distribute(
    id: string,
    params: MealPlanDistributeParams,
  ): Promise<MealPlanDistributionResult> {
    return apiClient.post<MealPlanDistributionResult>(
      withQuery(apiEndpoints.mealPlan.distribute(id), {
        targetAudience: params.targetAudience,
        notes: params.notes,
      }),
    );
  },
};
