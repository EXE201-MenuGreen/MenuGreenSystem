import type { MealPlan, MealPlanUpsertRequest } from "@/features/meal-plans/types";

export type MealPlanItemFormRow = {
  mealType: string;
  foodId: string;
  recipeId: string;
  plannedDate: string;
  targetCalories: string;
  isCompleted: boolean;
};

export type MealPlanFormState = {
  title: string;
  planType: string;
  startDate: string;
  endDate: string;
  targetCalories: string;
  generatedBy: string;
  isActive: boolean;
  items: MealPlanItemFormRow[];
};

export const emptyMealPlanItemRow = (): MealPlanItemFormRow => ({
  mealType: "Breakfast",
  foodId: "",
  recipeId: "",
  plannedDate: "",
  targetCalories: "",
  isCompleted: false,
});

export const emptyMealPlanForm = (): MealPlanFormState => ({
  title: "",
  planType: "weekly",
  startDate: "",
  endDate: "",
  targetCalories: "",
  generatedBy: "ADMIN",
  isActive: true,
  items: [emptyMealPlanItemRow()],
});

function parseOptionalNumber(value: string): number | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  const parsed = Number(trimmed);
  return Number.isNaN(parsed) ? null : parsed;
}

export function mealPlanToFormState(plan: MealPlan): MealPlanFormState {
  return {
    title: plan.title,
    planType: plan.planType ?? "weekly",
    startDate: plan.startDate ?? "",
    endDate: plan.endDate ?? "",
    targetCalories: plan.targetCalories?.toString() ?? "",
    generatedBy: plan.generatedBy ?? "ADMIN",
    isActive: plan.isActive,
    items:
      plan.items.length > 0
        ? plan.items.map((item) => ({
            mealType: item.mealType ?? "Breakfast",
            foodId: item.foodId ?? "",
            recipeId: item.recipeId ?? "",
            plannedDate: item.plannedDate ?? "",
            targetCalories: item.targetCalories?.toString() ?? "",
            isCompleted: item.isCompleted,
          }))
        : [emptyMealPlanItemRow()],
  };
}

export function formStateToPayload(form: MealPlanFormState): MealPlanUpsertRequest {
  return {
    title: form.title.trim(),
    planType: form.planType.trim(),
    startDate: form.startDate.trim() || null,
    endDate: form.endDate.trim() || null,
    targetCalories: parseOptionalNumber(form.targetCalories),
    generatedBy: form.generatedBy.trim() || "ADMIN",
    isActive: form.isActive,
    items: form.items.map((row) => ({
      mealType: row.mealType,
      foodId: row.foodId.trim() || null,
      recipeId: row.recipeId.trim() || null,
      plannedDate: row.plannedDate.trim() || null,
      targetCalories: parseOptionalNumber(row.targetCalories),
      isCompleted: row.isCompleted,
    })),
  };
}

export function validateMealPlanForm(form: MealPlanFormState): string | null {
  if (!form.title.trim()) return "Tiêu đề meal plan là bắt buộc.";
  if (!form.planType.trim()) return "Loại plan là bắt buộc.";

  const validItems = form.items.filter(
    (row) => row.foodId.trim() || row.recipeId.trim(),
  );

  if (validItems.length === 0) {
    return "Meal plan cần ít nhất một món (chọn Food hoặc Recipe).";
  }

  for (const row of validItems) {
    if (!row.foodId.trim() && !row.recipeId.trim()) {
      return "Mỗi món cần chọn Food hoặc Recipe.";
    }
    if (!row.mealType.trim()) return "Meal type là bắt buộc.";
  }

  return null;
}
