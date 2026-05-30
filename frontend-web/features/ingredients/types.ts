export interface IngredientUpsertRequest {
  nameVi: string;
  nameEn?: string | null;
  category?: string | null;
  caloriesKcal?: number | null;
  proteinG?: number | null;
  carbsG?: number | null;
  fatG?: number | null;
  estimatedPriceVnd?: number | null;
  unitDefault?: string | null;
  imageUrl?: string | null;
  isActive?: boolean | null;
}

export interface IngredientSearchParams {
  keyword?: string;
  category?: string;
  isActive?: boolean;
}

export interface IngredientSearchResult {
  items: Ingredient[];
  totalCount: number;
}

export interface Ingredient {
  id: string;
  nameVi: string;
  nameEn?: string | null;
  category?: string | null;
  caloriesKcal?: number | null;
  proteinG?: number | null;
  carbsG?: number | null;
  fatG?: number | null;
  estimatedPriceVnd?: number | null;
  unitDefault?: string | null;
  imageUrl?: string | null;
  isActive?: boolean | null;
}
