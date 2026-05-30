import { apiClient } from "@/lib/api/client";
import { apiEndpoints } from "@/lib/api/endpoints";
import type {
  Food,
  FoodSearchParams,
  FoodSearchResult,
  FoodUpsertRequest,
} from "@/features/foods/types";
import type { MessageResponse } from "@/types/common";

function buildFoodSearchUrl(params?: FoodSearchParams): string {
  if (!params) return apiEndpoints.food.base;

  const query = new URLSearchParams();

  if (params.keyword) query.set("keyword", params.keyword);
  if (params.minCalories != null) {
    query.set("minCalories", String(params.minCalories));
  }
  if (params.maxCalories != null) {
    query.set("maxCalories", String(params.maxCalories));
  }
  if (params.proteinLevel) query.set("proteinLevel", params.proteinLevel);
  if (params.maxPriceVnd != null) {
    query.set("maxPriceVnd", String(params.maxPriceVnd));
  }
  if (params.maxPrepTimeMin != null) {
    query.set("maxPrepTimeMin", String(params.maxPrepTimeMin));
  }
  if (params.category) query.set("category", params.category);

  const qs = query.toString();
  return qs ? `${apiEndpoints.food.base}?${qs}` : apiEndpoints.food.base;
}

export const foodApi = {
  search(params?: FoodSearchParams): Promise<FoodSearchResult> {
    return apiClient.get<FoodSearchResult>(buildFoodSearchUrl(params), false);
  },

  getById(id: string): Promise<Food> {
    return apiClient.get<Food>(apiEndpoints.food.byId(id), false);
  },

  create(payload: FoodUpsertRequest): Promise<Food> {
    return apiClient.post<Food>(apiEndpoints.food.base, payload, false);
  },

  update(id: string, payload: FoodUpsertRequest): Promise<Food> {
    return apiClient.put<Food>(apiEndpoints.food.byId(id), payload, false);
  },

  delete(id: string): Promise<MessageResponse> {
    return apiClient.delete<MessageResponse>(apiEndpoints.food.byId(id), false);
  },
};
