export interface RecipeIngredientUpsertRequest {
  ingredientId: string;
  quantity: number;
  unit: string;
  notes?: string | null;
}

export interface RecipeUpsertRequest {
  foodId?: string | null;
  title: string;
  description?: string | null;
  prepTimeMin?: number | null;
  cookTimeMin?: number | null;
  totalTimeMin?: number | null;
  servings?: number | null;
  difficulty?: string | null;
  mealType?: string | null;
  estimatedPriceVnd?: number | null;
  instructions?: string | null;
  imageUrl?: string | null;
  videoUrl?: string | null;
  isActive?: boolean | null;
  ingredients?: RecipeIngredientUpsertRequest[];
}

export interface RecipeIngredient {
  ingredientId: string;
  ingredientName: string;
  quantity: number;
  unit: string;
  notes?: string | null;
}

export interface Recipe {
  id: string;
  foodId?: string | null;
  title: string;
  description?: string | null;
  prepTimeMin?: number | null;
  cookTimeMin?: number | null;
  totalTimeMin?: number | null;
  servings?: number | null;
  difficulty?: string | null;
  mealType?: string | null;
  estimatedPriceVnd?: number | null;
  instructions?: string | null;
  imageUrl?: string | null;
  videoUrl?: string | null;
  isActive?: boolean | null;
  ingredients: RecipeIngredient[];
}
