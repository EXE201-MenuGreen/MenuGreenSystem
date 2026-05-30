import { apiClient } from "@/lib/api/client";
import { apiEndpoints, withQuery } from "@/lib/api/endpoints";
import type {
  Food,
  FoodSearchParams,
  FoodSearchResult,
  FoodUpsertRequest,
} from "@/features/foods/types";
import type { MessageResponse } from "@/types/common";

export const foodApi = {
  search(params?: FoodSearchParams): Promise<FoodSearchResult> {
    return apiClient.get<FoodSearchResult>(
      withQuery(apiEndpoints.food.base, {
        keyword: params?.keyword,
        minCalories: params?.minCalories,
        maxCalories: params?.maxCalories,
        proteinLevel: params?.proteinLevel,
        maxPriceVnd: params?.maxPriceVnd,
        maxPrepTimeMin: params?.maxPrepTimeMin,
        category: params?.category,
      }),
    );
  },

  getById(id: string): Promise<Food> {
    return apiClient.get<Food>(apiEndpoints.food.byId(id));
  },

  create(payload: FoodUpsertRequest): Promise<Food> {
    return apiClient.post<Food>(apiEndpoints.food.base, payload);
  },

  update(id: string, payload: FoodUpsertRequest): Promise<Food> {
    return apiClient.put<Food>(apiEndpoints.food.byId(id), payload);
  },

  delete(id: string): Promise<MessageResponse> {
    return apiClient.delete<MessageResponse>(apiEndpoints.food.byId(id));
  },
};
