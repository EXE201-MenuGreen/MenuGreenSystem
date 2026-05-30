export interface MealPlanItemUpsertRequest {
  mealType: string;
  foodId?: string | null;
  recipeId?: string | null;
  plannedDate?: string | null;
  targetCalories?: number | null;
  isCompleted?: boolean;
}

export interface MealPlanUpsertRequest {
  title: string;
  planType: string;
  startDate?: string | null;
  endDate?: string | null;
  targetCalories?: number | null;
  generatedBy?: string | null;
  isActive?: boolean;
  items?: MealPlanItemUpsertRequest[];
}

export interface MealPlanItem {
  id: string;
  mealPlanId: string;
  mealType?: string | null;
  foodId?: string | null;
  recipeId?: string | null;
  plannedDate?: string | null;
  targetCalories?: number | null;
  isCompleted: boolean;
  foodName?: string | null;
  recipeName?: string | null;
}

export interface MealPlan {
  id: string;
  title: string;
  planType?: string | null;
  startDate?: string | null;
  endDate?: string | null;
  targetCalories?: number | null;
  generatedBy?: string | null;
  isActive: boolean;
  totalCalories: number;
  totalProteinG: number;
  totalCarbsG: number;
  totalFatG: number;
  items: MealPlanItem[];
}

export interface MealPlanListParams {
  isActive?: boolean;
}

export interface MealPlanDistributeParams {
  targetAudience: string;
  notes?: string | null;
}

export interface MealPlanDistributionResult {
  mealPlanId: string;
  message: string;
  targetAudience: string;
  distributedAt: string;
  completed: boolean;
}
