import { apiClient } from "@/lib/api/client";
import { apiEndpoints } from "@/lib/api/endpoints";
import type {
  Ingredient,
  IngredientUpsertRequest,
} from "@/features/ingredients/types";
import type { MessageResponse } from "@/types/common";

export const ingredientApi = {
  getById(id: string): Promise<Ingredient> {
    return apiClient.get<Ingredient>(apiEndpoints.ingredient.byId(id), false);
  },

  create(payload: IngredientUpsertRequest): Promise<Ingredient> {
    return apiClient.post<Ingredient>(
      apiEndpoints.ingredient.base,
      payload,
      false,
    );
  },

  update(id: string, payload: IngredientUpsertRequest): Promise<Ingredient> {
    return apiClient.put<Ingredient>(
      apiEndpoints.ingredient.byId(id),
      payload,
      false,
    );
  },

  delete(id: string): Promise<MessageResponse> {
    return apiClient.delete<MessageResponse>(
      apiEndpoints.ingredient.byId(id),
      false,
    );
  },
};
