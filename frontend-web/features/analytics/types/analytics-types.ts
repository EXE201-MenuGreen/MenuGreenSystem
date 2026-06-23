// Analytics Types for Admin Dashboard

export interface DateRange {
  from: Date;
  to: Date;
}

// Dashboard Overview
export interface AnalyticsDashboard {
  totalEvents: number;
  totalUsers: number;
  activeUsers: number;
  activeUsersLast7Days: number;
  mealLoggedEvents: number;
  notificationOpenedEvents: number;
  subscriptionStartedEvents: number;
}

export interface AnalyticsSummary {
  totalEvents: number;
  totalUsers: number;
  activeUsers: number;
  mealLoggedEvents: number;
  notificationOpenedEvents: number;
  subscriptionStartedEvents: number;
  from: string;
  to: string;
}

// Metrics & Trends
export interface MetricPoint {
  date: string;
  events: number;
  users: number;
}

export interface TopEvent {
  action: string;
  count: number;
  percentage?: number;
}

// Funnel Analytics
export interface FunnelStep {
  step: string;
  order: number;
  users: number;
  conversionFromPrevious: number;
  dropOffFromPrevious: number;
}

// Cohort Analytics
export interface CohortData {
  cohortDate: string;
  users: number;
  events: number;
  retentionRates?: number[];
}

// Churn & Retention
export interface ChurnRiskUser {
  userId: string;
  email: string;
  name: string;
  riskLevel: 'high' | 'medium' | 'low';
  lastActivityAt?: string;
  inactivityDays?: number;
}

export interface InactiveUser {
  userId: string;
  email: string;
  name: string;
  lastActivityAt?: string;
  daysInactive?: number;
}

export interface ReactivationOpportunity {
  userId: string;
  email: string;
  name: string;
  daysSinceLastActive: number;
  recommendedAction: string;
}

// Activity Log
export interface ActivityLogEntry {
  id: string;
  userId: string;
  action: string;
  entityType: string;
  entityId?: string;
  metadata?: Record<string, unknown>;
  createdAt: string;
}

// ============================================
// NUTRITION ANALYTICS TYPES
// ============================================

export interface NutritionDashboardResponse {
  summary: NutritionSummarySection;
  targets: NutritionTargets;
  comparisons: NutritionComparisons;
}

export interface NutritionSummarySection {
  totalMealLogs: number;
  totalCaloriesConsumed: number;
  totalProteinG: number;
  totalCarbsG: number;
  totalFatG: number;
  avgCaloriesPerUserPerDay: number;
  avgProteinPerUserPerDay: number;
  avgCarbsPerUserPerDay: number;
  avgFatPerUserPerDay: number;
  activeUsersCount: number;
}

export interface NutritionTargets {
  avgCalorieTarget: number;
  avgProteinTarget: number;
  avgCarbTarget: number;
  avgFatTarget: number;
}

export interface NutritionComparisons {
  mealLogsChange: number;
  caloriesChange: number;
  proteinChange: number;
  carbsChange: number;
  fatChange: number;
}

// Macro Distribution
export interface MacroDistributionResponse {
  averageDistribution: MacroDistribution;
  distributionByUserSegment: Record<string, MacroDistribution>;
  recommendation: string;
}

export interface MacroDistribution {
  proteinPercent: number;
  carbsPercent: number;
  fatPercent: number;
}

// Goal Achievement
export interface GoalAchievementResponse {
  overallAchievementRate: AchievementRates;
  weeklyAchievementTrend: WeeklyAchievement[];
  achievementByUserSegment: Record<string, AchievementRates>;
}

export interface AchievementRates {
  calorieGoal: number;
  proteinGoal: number;
  carbGoal: number;
  fatGoal: number;
  fiberGoal?: number;
}

export interface WeeklyAchievement {
  week: string;
  calorieGoal: number;
  proteinGoal: number;
  carbGoal: number;
  fatGoal: number;
}

// Top Foods
export interface TopFoodsResponse {
  topFoods: TopFoodItem[];
  topFoodsByCalories: TopFoodItem[];
  topFoodsByProtein: TopFoodItem[];
  totalUniqueFoodsLogged: number;
}

export interface TopFoodItem {
  rank: number;
  foodId: string;
  foodName: string;
  foodNameEn: string;
  category: string;
  logCount: number;
  totalServings: number;
  avgServingSizeG: number;
  avgCaloriesPerServing: number;
  avgProteinPerServing: number;
  percentOfTotalLogs: number;
}

// Calorie Distribution
export interface CalorieDistributionResponse {
  dailyDistribution: CalorieDistributionDaily;
  weeklyTrend: WeeklyCalorieDistribution[];
  recommendation: string;
}

export interface CalorieDistributionDaily {
  belowTarget: CalorieSegment;
  onTarget: CalorieSegment;
  aboveTarget: CalorieSegment;
}

export interface CalorieSegment {
  percent: number;
  userCount: number;
  avgVariance: number;
}

export interface WeeklyCalorieDistribution {
  week: string;
  belowTarget: number;
  onTarget: number;
  aboveTarget: number;
}

// Meal Type Breakdown
export interface MealTypeBreakdownResponse {
  averageDistribution: MealTypeDistribution;
  byDayOfWeek: Record<string, MealTypeDistribution>;
  caloriesByMealType: Record<string, MealTypeCalories>;
  insights: string;
}

export interface MealTypeDistribution {
  breakfast: number;
  lunch: number;
  dinner: number;
  snack: number;
}

export interface MealTypeCalories {
  avg: number;
  target: number;
}

// User Insights
export interface UserInsightsResponse {
  engagementMetrics: EngagementMetrics;
  dietQuality: DietQuality;
  nutrientAdequacy: NutrientAdequacy;
}

export interface EngagementMetrics {
  avgMealLogsPerUserPerWeek: number;
  avgMealsLoggedPerDay: number;
  usersLoggingAllMeals: number;
  usersLoggingPartialMeals: number;
  streakStats: StreakStats;
}

export interface StreakStats {
  avgStreakDays: number;
  maxStreakDays: number;
  usersWithStreakOver7Days: number;
}

export interface DietQuality {
  avgDietScore: number;
  usersWithGoodDiet: number;
  usersWithPoorDiet: number;
  improvingUsers: number;
  decliningUsers: number;
}

export interface NutrientAdequacy {
  adequateProtein: number;
  adequateFiber: number;
  adequateVitamins: number;
  highSodium: number;
  lowWaterIntake: number;
}

// ============================================
// CHART DATA TYPES
// ============================================

export interface ChartDataPoint {
  date: string;
  value: number;
  label?: string;
}

export interface PieChartData {
  name: string;
  value: number;
  color: string;
}

export interface ProgressData {
  label: string;
  value: number;
  target: number;
  percent: number;
  color: string;
}

// ============================================
// FILTER TYPES
// ============================================

export type DatePreset = 'today' | '7days' | '30days' | '90days' | 'custom';

export interface AnalyticsFilters {
  datePreset: DatePreset;
  dateRange?: DateRange;
  funnelType?: 'onboarding' | 'subscription' | 'custom';
  userSegment?: 'all' | 'active' | 'inactive' | 'at-risk';
}
