export interface SubscriptionPlanUpsertRequest {
  name: string;
  description?: string | null;
  durationDays: number;
  priceVnd: number;
  featureGroup?: string | null;
  isActive?: boolean;
}

export interface SubscriptionPlan {
  id: string;
  name: string;
  description?: string | null;
  durationDays: number;
  priceVnd: number;
  featureGroup?: string | null;
  isActive: boolean;
  tierLabel: string;
}

export interface SubscriptionPlanListParams {
  isActive?: boolean;
}
