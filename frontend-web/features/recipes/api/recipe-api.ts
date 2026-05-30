import { apiClient } from "@/lib/api/client";
import { apiEndpoints } from "@/lib/api/endpoints";
import type { Recipe, RecipeUpsertRequest } from "@/features/recipes/types";
import type { MessageResponse } from "@/types/common";

export const recipeApi = {
  getById(id: string): Promise<Recipe> {
    return apiClient.get<Recipe>(apiEndpoints.recipe.byId(id), false);
  },

  create(payload: RecipeUpsertRequest): Promise<Recipe> {
    return apiClient.post<Recipe>(apiEndpoints.recipe.base, payload, false);
  },

  update(id: string, payload: RecipeUpsertRequest): Promise<Recipe> {
    return apiClient.put<Recipe>(apiEndpoints.recipe.byId(id), payload, false);
  },

  delete(id: string): Promise<MessageResponse> {
    return apiClient.delete<MessageResponse>(
      apiEndpoints.recipe.byId(id),
      false,
    );
  },
};
