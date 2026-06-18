import { apiClient } from "@/lib/api/client";
import { apiEndpoints, withQuery } from "@/lib/api/endpoints";
import type {
  Ingredient,
  IngredientSearchParams,
  IngredientSearchResult,
  IngredientUpsertRequest,
} from "@/features/ingredients/types";
import type { MessageResponse } from "@/types/common";

export const ingredientApi = {
  search(params?: IngredientSearchParams): Promise<IngredientSearchResult> {
    return apiClient.get<IngredientSearchResult>(
      withQuery(apiEndpoints.ingredient.search, {
        keyword: params?.keyword,
        category: params?.category,
        isActive: params?.isActive,
      }),
    );
  },

  getById(id: string): Promise<Ingredient> {
    return apiClient.get<Ingredient>(apiEndpoints.ingredient.byId(id));
  },

  create(payload: IngredientUpsertRequest): Promise<Ingredient> {
    return apiClient.post<Ingredient>(apiEndpoints.ingredient.base, payload);
  },

  update(id: string, payload: IngredientUpsertRequest): Promise<Ingredient> {
    return apiClient.put<Ingredient>(
      apiEndpoints.ingredient.byId(id),
      payload,
    );
  },

  delete(id: string): Promise<MessageResponse> {
    return apiClient.delete<MessageResponse>(
      apiEndpoints.ingredient.byId(id),
    );
  },
};
