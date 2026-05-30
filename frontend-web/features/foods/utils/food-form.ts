import type { Food, FoodUpsertRequest } from "@/features/foods/types";

export type FoodFormState = {
  nameVi: string;
  nameEn: string;
  category: string;
  description: string;
  caloriesKcal: string;
  proteinG: string;
  carbsG: string;
  fatG: string;
  fiberG: string;
  estimatedPriceVnd: string;
  defaultServingG: string;
  imageUrl: string;
  isActive: boolean;
};

export const emptyFoodForm = (): FoodFormState => ({
  nameVi: "",
  nameEn: "",
  category: "",
  description: "",
  caloriesKcal: "",
  proteinG: "",
  carbsG: "",
  fatG: "",
  fiberG: "",
  estimatedPriceVnd: "",
  defaultServingG: "",
  imageUrl: "",
  isActive: true,
});

function parseOptionalNumber(value: string): number | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  const parsed = Number(trimmed);
  return Number.isNaN(parsed) ? null : parsed;
}

export function foodToFormState(food: Food): FoodFormState {
  return {
    nameVi: food.nameVi,
    nameEn: food.nameEn ?? "",
    category: food.category ?? "",
    description: food.description ?? "",
    caloriesKcal: food.caloriesKcal?.toString() ?? "",
    proteinG: food.proteinG?.toString() ?? "",
    carbsG: food.carbsG?.toString() ?? "",
    fatG: food.fatG?.toString() ?? "",
    fiberG: food.fiberG?.toString() ?? "",
    estimatedPriceVnd: food.estimatedPriceVnd?.toString() ?? "",
    defaultServingG: food.defaultServingG?.toString() ?? "",
    imageUrl: food.imageUrl ?? "",
    isActive: food.isActive ?? true,
  };
}

export function formStateToPayload(form: FoodFormState): FoodUpsertRequest {
  return {
    nameVi: form.nameVi.trim(),
    nameEn: form.nameEn.trim() || null,
    category: form.category.trim() || null,
    description: form.description.trim() || null,
    caloriesKcal: parseOptionalNumber(form.caloriesKcal),
    proteinG: parseOptionalNumber(form.proteinG),
    carbsG: parseOptionalNumber(form.carbsG),
    fatG: parseOptionalNumber(form.fatG),
    fiberG: parseOptionalNumber(form.fiberG),
    estimatedPriceVnd: parseOptionalNumber(form.estimatedPriceVnd),
    defaultServingG: parseOptionalNumber(form.defaultServingG),
    imageUrl: form.imageUrl.trim() || null,
    isActive: form.isActive,
  };
}

export function validateFoodForm(form: FoodFormState): string | null {
  if (!form.nameVi.trim()) return "Tên tiếng Việt là bắt buộc.";
  return null;
}
