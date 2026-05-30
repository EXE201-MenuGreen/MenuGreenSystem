import type { Ingredient, IngredientUpsertRequest } from "@/features/ingredients/types";

export type IngredientFormState = {
  nameVi: string;
  nameEn: string;
  category: string;
  caloriesKcal: string;
  proteinG: string;
  carbsG: string;
  fatG: string;
  estimatedPriceVnd: string;
  unitDefault: string;
  imageUrl: string;
  isActive: boolean;
};

export const emptyIngredientForm = (): IngredientFormState => ({
  nameVi: "",
  nameEn: "",
  category: "",
  caloriesKcal: "",
  proteinG: "",
  carbsG: "",
  fatG: "",
  estimatedPriceVnd: "",
  unitDefault: "g",
  imageUrl: "",
  isActive: true,
});

function parseOptionalNumber(value: string): number | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  const parsed = Number(trimmed);
  return Number.isNaN(parsed) ? null : parsed;
}

export function ingredientToFormState(
  ingredient: Ingredient,
): IngredientFormState {
  return {
    nameVi: ingredient.nameVi,
    nameEn: ingredient.nameEn ?? "",
    category: ingredient.category ?? "",
    caloriesKcal: ingredient.caloriesKcal?.toString() ?? "",
    proteinG: ingredient.proteinG?.toString() ?? "",
    carbsG: ingredient.carbsG?.toString() ?? "",
    fatG: ingredient.fatG?.toString() ?? "",
    estimatedPriceVnd: ingredient.estimatedPriceVnd?.toString() ?? "",
    unitDefault: ingredient.unitDefault ?? "g",
    imageUrl: ingredient.imageUrl ?? "",
    isActive: ingredient.isActive ?? true,
  };
}

export function formStateToPayload(
  form: IngredientFormState,
): IngredientUpsertRequest {
  return {
    nameVi: form.nameVi.trim(),
    nameEn: form.nameEn.trim() || null,
    category: form.category.trim() || null,
    caloriesKcal: parseOptionalNumber(form.caloriesKcal),
    proteinG: parseOptionalNumber(form.proteinG),
    carbsG: parseOptionalNumber(form.carbsG),
    fatG: parseOptionalNumber(form.fatG),
    estimatedPriceVnd: parseOptionalNumber(form.estimatedPriceVnd),
    unitDefault: form.unitDefault.trim() || null,
    imageUrl: form.imageUrl.trim() || null,
    isActive: form.isActive,
  };
}

export function validateIngredientForm(form: IngredientFormState): string | null {
  if (!form.nameVi.trim()) return "Tên tiếng Việt là bắt buộc.";
  return null;
}
