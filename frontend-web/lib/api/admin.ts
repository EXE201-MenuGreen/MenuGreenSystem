/**
 * Central export for all Admin Panel API clients.
 * Covers every backend endpoint that requires or supports admin operations.
 */
export { authApi } from "@/features/auth/api/auth-api";
export { userApi } from "@/features/users/api/user-api";
export { adminUserApi } from "@/features/users/api/admin-user-api";
export { dashboardApi } from "@/features/dashboard/api/dashboard-api";
export { foodApi } from "@/features/foods/api/food-api";
export { ingredientApi } from "@/features/ingredients/api/ingredient-api";
export { recipeApi } from "@/features/recipes/api/recipe-api";
export { subscriptionPlanApi } from "@/features/subscription-plans/api/subscription-plan-api";
export { mealPlanApi } from "@/features/meal-plans/api/meal-plan-api";

export { apiClient } from "@/lib/api/client";
export { apiEndpoints, withQuery } from "@/lib/api/endpoints";
export { ApiError, getErrorMessage } from "@/lib/api/errors";
export { tokenStorage } from "@/lib/auth/token-storage";
export {
  isAdminToken,
  tryGetRoleFromToken,
} from "@/lib/auth/jwt-utils";

export type * from "@/features/auth/types";
export type * from "@/features/users/types";
export type * from "@/features/dashboard/types";
export type * from "@/features/foods/types";
export type * from "@/features/ingredients/types";
export type * from "@/features/recipes/types";
export type * from "@/features/subscription-plans/types";
export type * from "@/features/meal-plans/types";
export type * from "@/types/common";
