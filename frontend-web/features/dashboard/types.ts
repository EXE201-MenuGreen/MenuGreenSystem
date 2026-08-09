export interface DashboardFoodRankingItem {
  foodId: string;
  foodName: string;
  useCount: number;
  caloriesKcal: number;
  estimatedPriceVnd: number;
}

export interface DashboardMetrics {
  totalUsers: number;
  activeUsers: number;
  premiumUsers: number;
  proUsers: number;
  totalRevenueVnd: number;
  topFoods: DashboardFoodRankingItem[];
  generatedAt: string;
}

export interface RevenueDashboardMetrics {
  totalRevenueVnd: number;
  subscribeRevenueVnd: number;
  renewRevenueVnd: number;
  transactionCount: number;
}

export interface DashboardUserMetrics {
  totalUsers: number;
  activeUsers: number;
  premiumUsers: number;
  proUsers: number;
}
