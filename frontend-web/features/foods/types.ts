export interface FoodUpsertRequest {
  nameVi: string;
  nameEn?: string | null;
  category?: string | null;
  description?: string | null;
  caloriesKcal?: number | null;
  proteinG?: number | null;
  carbsG?: number | null;
  fatG?: number | null;
  fiberG?: number | null;
  estimatedPriceVnd?: number | null;
  defaultServingG: number;
  imageUrl?: string | null;
  isActive?: boolean | null;
  /** Chỉ dùng phía client khi lưu — API Food upsert không nhận field này. */
  allergenKeys?: string[];
}

export interface Food {
  id: string;
  nameVi: string;
  nameEn?: string | null;
  category?: string | null;
  description?: string | null;
  caloriesKcal?: number | null;
  proteinG?: number | null;
  carbsG?: number | null;
  fatG?: number | null;
  fiberG?: number | null;
  estimatedPriceVnd?: number | null;
  defaultServingG?: number | null;
  imageUrl?: string | null;
  isActive?: boolean | null;
}

export interface FoodSearchParams {
  keyword?: string;
  minCalories?: number;
  maxCalories?: number;
  proteinLevel?: string;
  maxPriceVnd?: number;
  maxPrepTimeMin?: number;
  category?: string;
}

export interface FoodSearchResult {
  items: Food[];
  totalCount: number;
}
