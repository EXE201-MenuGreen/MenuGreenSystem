import type {
  Recipe,
  RecipeIngredientUpsertRequest,
  RecipeUpsertRequest,
} from "@/features/recipes/types";

export type RecipeIngredientFormRow = {
  ingredientId: string;
  quantity: string;
  unit: string;
  notes: string;
};

export type RecipeFormState = {
  foodId: string;
  title: string;
  description: string;
  prepTimeMin: string;
  cookTimeMin: string;
  totalTimeMin: string;
  servings: string;
  difficulty: string;
  mealType: string;
  estimatedPriceVnd: string;
  instructions: string;
  imageUrl: string;
  videoUrl: string;
  isActive: boolean;
  ingredients: RecipeIngredientFormRow[];
};

export const emptyIngredientRow = (): RecipeIngredientFormRow => ({
  ingredientId: "",
  quantity: "",
  unit: "g",
  notes: "",
});

export const emptyRecipeForm = (): RecipeFormState => ({
  foodId: "",
  title: "",
  description: "",
  prepTimeMin: "",
  cookTimeMin: "",
  totalTimeMin: "",
  servings: "",
  difficulty: "",
  mealType: "",
  estimatedPriceVnd: "",
  instructions: "",
  imageUrl: "",
  videoUrl: "",
  isActive: true,
  ingredients: [emptyIngredientRow()],
});

function parseOptionalNumber(value: string): number | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  const parsed = Number(trimmed);
  return Number.isNaN(parsed) ? null : parsed;
}

export function recipeToFormState(recipe: Recipe): RecipeFormState {
  return {
    foodId: recipe.foodId ?? "",
    title: recipe.title,
    description: recipe.description ?? "",
    prepTimeMin: recipe.prepTimeMin?.toString() ?? "",
    cookTimeMin: recipe.cookTimeMin?.toString() ?? "",
    totalTimeMin: recipe.totalTimeMin?.toString() ?? "",
    servings: recipe.servings?.toString() ?? "",
    difficulty: recipe.difficulty ?? "",
    mealType: recipe.mealType ?? "",
    estimatedPriceVnd: recipe.estimatedPriceVnd?.toString() ?? "",
    instructions: recipe.instructions ?? "",
    imageUrl: recipe.imageUrl ?? "",
    videoUrl: recipe.videoUrl ?? "",
    isActive: recipe.isActive ?? true,
    ingredients:
      recipe.ingredients.length > 0
        ? recipe.ingredients.map((item) => ({
            ingredientId: item.ingredientId,
            quantity: item.quantity.toString(),
            unit: item.unit,
            notes: item.notes ?? "",
          }))
        : [emptyIngredientRow()],
  };
}

export function formStateToPayload(form: RecipeFormState): RecipeUpsertRequest {
  const ingredients: RecipeIngredientUpsertRequest[] = form.ingredients
    .filter((row) => row.ingredientId && row.quantity.trim())
    .map((row) => ({
      ingredientId: row.ingredientId,
      quantity: Number(row.quantity),
      unit: row.unit.trim() || "g",
      notes: row.notes.trim() || null,
    }));

  return {
    foodId: form.foodId.trim() || null,
    title: form.title.trim(),
    description: form.description.trim() || null,
    prepTimeMin: parseOptionalNumber(form.prepTimeMin),
    cookTimeMin: parseOptionalNumber(form.cookTimeMin),
    totalTimeMin: parseOptionalNumber(form.totalTimeMin),
    servings: parseOptionalNumber(form.servings),
    difficulty: form.difficulty.trim() || null,
    mealType: form.mealType.trim() || null,
    estimatedPriceVnd: parseOptionalNumber(form.estimatedPriceVnd),
    instructions: form.instructions.trim() || null,
    imageUrl: form.imageUrl.trim() || null,
    videoUrl: form.videoUrl.trim() || null,
    isActive: form.isActive,
    ingredients,
  };
}

export function validateRecipeForm(form: RecipeFormState): string | null {
  if (!form.title.trim()) return "Tiêu đề công thức là bắt buộc.";

  for (const row of form.ingredients) {
    if (!row.ingredientId && !row.quantity.trim()) continue;
    if (!row.ingredientId || !row.quantity.trim()) {
      return "Mỗi nguyên liệu cần chọn ingredient và số lượng.";
    }
    if (Number.isNaN(Number(row.quantity))) {
      return "Số lượng nguyên liệu phải là số.";
    }
  }

  return null;
}
