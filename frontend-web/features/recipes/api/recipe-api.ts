import { apiClient } from "@/lib/api/client";
import { apiEndpoints, withQuery } from "@/lib/api/endpoints";
import type {
  Recipe,
  RecipeSearchParams,
  RecipeSearchResult,
  RecipeUpsertRequest,
} from "@/features/recipes/types";
import type { MessageResponse } from "@/types/common";

export const recipeApi = {
  search(params?: RecipeSearchParams): Promise<RecipeSearchResult> {
    return apiClient.get<RecipeSearchResult>(
      withQuery(apiEndpoints.recipe.search, {
        keyword: params?.keyword,
        mealType: params?.mealType,
        difficulty: params?.difficulty,
        isActive: params?.isActive,
      }),
    );
  },

  getById(id: string): Promise<Recipe> {
    return apiClient.get<Recipe>(apiEndpoints.recipe.byId(id));
  },

  create(payload: RecipeUpsertRequest): Promise<Recipe> {
    return apiClient.post<Recipe>(apiEndpoints.recipe.base, payload);
  },

  update(id: string, payload: RecipeUpsertRequest): Promise<Recipe> {
    return apiClient.put<Recipe>(apiEndpoints.recipe.byId(id), payload);
  },

  delete(id: string): Promise<MessageResponse> {
    return apiClient.delete<MessageResponse>(apiEndpoints.recipe.byId(id));
  },
};
