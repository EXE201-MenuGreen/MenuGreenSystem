"use client";

import { Users, Utensils, Flame, TrendingUp, TrendingDown, Award, Target } from "lucide-react";
import { KpiCard, DonutChart, Legend, ProgressBar, StatCard, KpiCardSkeleton } from "../components/analytics-cards";
import { DateRangePicker, Badge } from "../components/analytics-ui";
import { useNutritionAnalytics } from "../hooks/use-analytics";
import { cn } from "@/lib/utils/cn";

// Macro colors matching backend design
const MACRO_COLORS = {
  protein: "#a855f7", // purple-500
  carbs: "#f97316",    // orange-500
  fat: "#eab308",      // yellow-500
};

// ============================================
// NUTRITION ANALYTICS DASHBOARD
// ============================================

export function NutritionAnalyticsDashboard() {
  const {
    dashboard,
    macroDistribution,
    goalAchievement,
    topFoods,
    calorieDistribution,
    mealTypeBreakdown,
    userInsights,
    isLoading,
    error,
    datePreset,
    changePreset,
    refetch,
  } = useNutritionAnalytics({ enabled: true });

  const loading = isLoading || !dashboard;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">
            Nutrition Analytics
          </h1>
          <p className="mt-1 text-sm text-zinc-500">
            Theo dõi dinh dưỡng và hành vi ăn uống của người dùng
          </p>
        </div>
        <DateRangePicker value={datePreset} onChange={changePreset} />
      </div>

      {/* Error */}
      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 p-4 dark:border-red-900 dark:bg-red-950/30">
          <p className="text-sm text-red-700 dark:text-red-300">{error}</p>
        </div>
      )}

      {/* KPI Cards Row 1 */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <KpiCard
          label="Tổng Meal Logs"
          value={loading ? "—" : (dashboard?.summary.totalMealLogs ?? 0).toLocaleString()}
          change={dashboard?.comparisons.mealLogsChange}
          changeLabel="so với kỳ trước"
          icon={<Utensils className="h-5 w-5" />}
          loading={loading}
        />
        <KpiCard
          label="Calories TB/ngày"
          value={loading ? "—" : `${(dashboard?.summary.avgCaloriesPerUserPerDay ?? 0).toLocaleString()} kcal`}
          change={dashboard?.comparisons.caloriesChange}
          changeLabel="so với kỳ trước"
          icon={<Flame className="h-5 w-5" />}
          loading={loading}
        />
        <KpiCard
          label="Protein TB/ngày"
          value={loading ? "—" : `${(dashboard?.summary.avgProteinPerUserPerDay ?? 0).toFixed(0)}g`}
          change={dashboard?.comparisons.proteinChange}
          changeLabel="so với kỳ trước"
          icon={<Award className="h-5 w-5" />}
          loading={loading}
        />
        <KpiCard
          label="Active Users"
          value={loading ? "—" : (dashboard?.summary.activeUsersCount ?? 0).toLocaleString()}
          icon={<Users className="h-5 w-5" />}
          loading={loading}
        />
      </div>

      {/* KPI Cards Row 2 - Macros */}
      <div className="grid gap-4 sm:grid-cols-3">
        <KpiCard
          label="Carbs TB/ngày"
          value={loading ? "—" : `${(dashboard?.summary.avgCarbsPerUserPerDay ?? 0).toFixed(0)}g`}
          change={dashboard?.comparisons.carbsChange}
          changeLabel="so với kỳ trước"
          loading={loading}
        />
        <KpiCard
          label="Fat TB/ngày"
          value={loading ? "—" : `${(dashboard?.summary.avgFatPerUserPerDay ?? 0).toFixed(0)}g`}
          change={dashboard?.comparisons.fatChange}
          changeLabel="so với kỳ trước"
          loading={loading}
        />
        <KpiCard
          label="Calorie Target"
          value={loading ? "—" : `${(dashboard?.targets.avgCalorieTarget ?? 0).toLocaleString()} kcal`}
          icon={<Target className="h-5 w-5" />}
          loading={loading}
        />
      </div>

      {/* Charts Row */}
      <div className="grid gap-6 lg:grid-cols-2">
        {/* Macro Distribution */}
        <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
            Phân bổ Macro
          </h3>
          <p className="mt-1 text-sm text-zinc-500">
            Tỷ lệ Protein / Carbs / Fat trong chế độ ăn
          </p>

          <div className="mt-6 flex items-center justify-between">
            <DonutChart
              segments={[
                { name: "Protein", value: macroDistribution?.averageDistribution.proteinPercent ?? 0, color: MACRO_COLORS.protein },
                { name: "Carbs", value: macroDistribution?.averageDistribution.carbsPercent ?? 0, color: MACRO_COLORS.carbs },
                { name: "Fat", value: macroDistribution?.averageDistribution.fatPercent ?? 0, color: MACRO_COLORS.fat },
              ]}
              size={180}
              strokeWidth={24}
            />
            <Legend
              className="flex-1"
              items={[
                { name: "Protein", value: `${(macroDistribution?.averageDistribution.proteinPercent ?? 0).toFixed(1)}%`, color: MACRO_COLORS.protein },
                { name: "Carbs", value: `${(macroDistribution?.averageDistribution.carbsPercent ?? 0).toFixed(1)}%`, color: MACRO_COLORS.carbs },
                { name: "Fat", value: `${(macroDistribution?.averageDistribution.fatPercent ?? 0).toFixed(1)}%`, color: MACRO_COLORS.fat },
              ]}
            />
          </div>

          {macroDistribution?.recommendation && (
            <div className="mt-4 rounded-lg bg-emerald-50 p-3 dark:bg-emerald-950/30">
              <p className="text-sm text-emerald-700 dark:text-emerald-300">
                💡 {macroDistribution.recommendation}
              </p>
            </div>
          )}
        </div>

        {/* Calorie Distribution */}
        <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
            Phân bổ Calorie
          </h3>
          <p className="mt-1 text-sm text-zinc-500">
            Below / On / Above target
          </p>

          <div className="mt-6 space-y-4">
            <div>
              <div className="mb-2 flex items-center justify-between text-sm">
                <span className="flex items-center gap-2">
                  <span className="h-3 w-3 rounded-full bg-blue-500" />
                  Below Target
                </span>
                <span className="font-medium">{calorieDistribution?.dailyDistribution.belowTarget.percent.toFixed(1) ?? 0}%</span>
              </div>
              <div className="h-3 overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
                <div
                  className="h-full rounded-full bg-blue-500 transition-all"
                  style={{ width: `${calorieDistribution?.dailyDistribution.belowTarget.percent ?? 0}%` }}
                />
              </div>
            </div>

            <div>
              <div className="mb-2 flex items-center justify-between text-sm">
                <span className="flex items-center gap-2">
                  <span className="h-3 w-3 rounded-full bg-emerald-500" />
                  On Target
                </span>
                <span className="font-medium">{calorieDistribution?.dailyDistribution.onTarget.percent.toFixed(1) ?? 0}%</span>
              </div>
              <div className="h-3 overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
                <div
                  className="h-full rounded-full bg-emerald-500 transition-all"
                  style={{ width: `${calorieDistribution?.dailyDistribution.onTarget.percent ?? 0}%` }}
                />
              </div>
            </div>

            <div>
              <div className="mb-2 flex items-center justify-between text-sm">
                <span className="flex items-center gap-2">
                  <span className="h-3 w-3 rounded-full bg-red-500" />
                  Above Target
                </span>
                <span className="font-medium">{calorieDistribution?.dailyDistribution.aboveTarget.percent.toFixed(1) ?? 0}%</span>
              </div>
              <div className="h-3 overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
                <div
                  className="h-full rounded-full bg-red-500 transition-all"
                  style={{ width: `${calorieDistribution?.dailyDistribution.aboveTarget.percent ?? 0}%` }}
                />
              </div>
            </div>
          </div>

          {calorieDistribution?.recommendation && (
            <div className="mt-4 rounded-lg bg-amber-50 p-3 dark:bg-amber-950/30">
              <p className="text-sm text-amber-700 dark:text-amber-300">
                💡 {calorieDistribution.recommendation}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Goal Achievement */}
      <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
        <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
          Tỷ lệ đạt Goal
        </h3>
        <p className="mt-1 text-sm text-zinc-500">
          % người dùng đạt được mục tiêu dinh dưỡng hàng ngày
        </p>

        <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm">
              <span className="font-medium text-zinc-700 dark:text-zinc-300">Calorie</span>
              <Badge variant={goalAchievement?.overallAchievementRate.calorieGoal ? "success" : "warning"}>
                {goalAchievement?.overallAchievementRate.calorieGoal.toFixed(0) ?? 0}%
              </Badge>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
              <div
                className={cn(
                  "h-full rounded-full transition-all",
                  (goalAchievement?.overallAchievementRate.calorieGoal ?? 0) >= 70 ? "bg-emerald-500" : "bg-amber-500"
                )}
                style={{ width: `${goalAchievement?.overallAchievementRate.calorieGoal ?? 0}%` }}
              />
            </div>
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm">
              <span className="font-medium text-zinc-700 dark:text-zinc-300">Protein</span>
              <Badge variant={goalAchievement?.overallAchievementRate.proteinGoal ? "success" : "warning"}>
                {goalAchievement?.overallAchievementRate.proteinGoal.toFixed(0) ?? 0}%
              </Badge>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
              <div
                className={cn(
                  "h-full rounded-full transition-all",
                  (goalAchievement?.overallAchievementRate.proteinGoal ?? 0) >= 70 ? "bg-purple-500" : "bg-amber-500"
                )}
                style={{ width: `${goalAchievement?.overallAchievementRate.proteinGoal ?? 0}%` }}
              />
            </div>
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm">
              <span className="font-medium text-zinc-700 dark:text-zinc-300">Carbs</span>
              <Badge variant={goalAchievement?.overallAchievementRate.carbGoal ? "success" : "warning"}>
                {goalAchievement?.overallAchievementRate.carbGoal.toFixed(0) ?? 0}%
              </Badge>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
              <div
                className={cn(
                  "h-full rounded-full transition-all",
                  (goalAchievement?.overallAchievementRate.carbGoal ?? 0) >= 70 ? "bg-orange-500" : "bg-amber-500"
                )}
                style={{ width: `${goalAchievement?.overallAchievementRate.carbGoal ?? 0}%` }}
              />
            </div>
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm">
              <span className="font-medium text-zinc-700 dark:text-zinc-300">Fat</span>
              <Badge variant={goalAchievement?.overallAchievementRate.fatGoal ? "success" : "warning"}>
                {goalAchievement?.overallAchievementRate.fatGoal.toFixed(0) ?? 0}%
              </Badge>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
              <div
                className={cn(
                  "h-full rounded-full transition-all",
                  (goalAchievement?.overallAchievementRate.fatGoal ?? 0) >= 70 ? "bg-yellow-500" : "bg-amber-500"
                )}
                style={{ width: `${goalAchievement?.overallAchievementRate.fatGoal ?? 0}%` }}
              />
            </div>
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm">
              <span className="font-medium text-zinc-700 dark:text-zinc-300">Fiber</span>
              <Badge variant="warning">
                {goalAchievement?.overallAchievementRate.fiberGoal?.toFixed(0) ?? 0}%
              </Badge>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
              <div
                className="h-full rounded-full bg-green-500 transition-all"
                style={{ width: `${goalAchievement?.overallAchievementRate.fiberGoal ?? 0}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Top Foods & Meal Type */}
      <div className="grid gap-6 lg:grid-cols-2">
        {/* Top Foods */}
        <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
            Top Foods
          </h3>
          <p className="mt-1 text-sm text-zinc-500">
            {topFoods?.totalUniqueFoodsLogged ?? 0} món ăn duy nhất được log
          </p>

          <div className="mt-4 space-y-3">
            {topFoods?.topFoods.slice(0, 5).map((food, index) => (
              <div
                key={food.foodId}
                className="flex items-center justify-between rounded-lg bg-zinc-50 p-3 dark:bg-zinc-900/50"
              >
                <div className="flex items-center gap-3">
                  <span className="flex h-6 w-6 items-center justify-center rounded-full bg-emerald-100 text-xs font-bold text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
                    {index + 1}
                  </span>
                  <div>
                    <p className="font-medium text-zinc-900 dark:text-zinc-50">
                      {food.foodName}
                    </p>
                    <p className="text-xs text-zinc-500">
                      {food.logCount.toLocaleString()} lượt log
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium text-zinc-900 dark:text-zinc-50">
                    {food.avgCaloriesPerServing.toFixed(0)} kcal
                  </p>
                  <p className="text-xs text-zinc-500">
                    {food.percentOfTotalLogs.toFixed(1)}%
                  </p>
                </div>
              </div>
            ))}

            {!topFoods?.topFoods.length && !loading && (
              <p className="py-4 text-center text-sm text-zinc-500">
                Chưa có dữ liệu
              </p>
            )}
          </div>
        </div>

        {/* Meal Type Breakdown */}
        <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
            Phân bổ Meal Type
          </h3>
          <p className="mt-1 text-sm text-zinc-500">
            Tỷ lệ bữa ăn theo loại
          </p>

          <div className="mt-6 space-y-4">
            <div>
              <div className="mb-2 flex items-center justify-between text-sm">
                <span className="font-medium text-zinc-700 dark:text-zinc-300">Breakfast</span>
                <span className="font-medium">{mealTypeBreakdown?.averageDistribution.breakfast.toFixed(1) ?? 0}%</span>
              </div>
              <div className="h-4 overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
                <div
                  className="h-full rounded-full bg-amber-500 transition-all"
                  style={{ width: `${mealTypeBreakdown?.averageDistribution.breakfast ?? 0}%` }}
                />
              </div>
            </div>

            <div>
              <div className="mb-2 flex items-center justify-between text-sm">
                <span className="font-medium text-zinc-700 dark:text-zinc-300">Lunch</span>
                <span className="font-medium">{mealTypeBreakdown?.averageDistribution.lunch.toFixed(1) ?? 0}%</span>
              </div>
              <div className="h-4 overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
                <div
                  className="h-full rounded-full bg-emerald-500 transition-all"
                  style={{ width: `${mealTypeBreakdown?.averageDistribution.lunch ?? 0}%` }}
                />
              </div>
            </div>

            <div>
              <div className="mb-2 flex items-center justify-between text-sm">
                <span className="font-medium text-zinc-700 dark:text-zinc-300">Dinner</span>
                <span className="font-medium">{mealTypeBreakdown?.averageDistribution.dinner.toFixed(1) ?? 0}%</span>
              </div>
              <div className="h-4 overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
                <div
                  className="h-full rounded-full bg-blue-500 transition-all"
                  style={{ width: `${mealTypeBreakdown?.averageDistribution.dinner ?? 0}%` }}
                />
              </div>
            </div>

            <div>
              <div className="mb-2 flex items-center justify-between text-sm">
                <span className="font-medium text-zinc-700 dark:text-zinc-300">Snack</span>
                <span className="font-medium">{mealTypeBreakdown?.averageDistribution.snack.toFixed(1) ?? 0}%</span>
              </div>
              <div className="h-4 overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
                <div
                  className="h-full rounded-full bg-purple-500 transition-all"
                  style={{ width: `${mealTypeBreakdown?.averageDistribution.snack ?? 0}%` }}
                />
              </div>
            </div>
          </div>

          {mealTypeBreakdown?.insights && (
            <div className="mt-4 rounded-lg bg-blue-50 p-3 dark:bg-blue-950/30">
              <p className="text-sm text-blue-700 dark:text-blue-300">
                💡 {mealTypeBreakdown.insights}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* User Insights */}
      <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
        <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
          User Insights
        </h3>
        <p className="mt-1 text-sm text-zinc-500">
          Engagement va chat luong che do an
        </p>

        <div className="mt-6 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {/* Engagement */}
          <div className="space-y-3">
            <h4 className="text-sm font-medium uppercase tracking-wide text-zinc-500">
              Engagement
            </h4>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-zinc-600 dark:text-zinc-400">Logs/user/tuan</span>
                <span className="font-medium">{loading ? "—" : (userInsights?.engagementMetrics.avgMealLogsPerUserPerWeek ?? 0).toFixed(1)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-zinc-600 dark:text-zinc-400">Logs/user/ngay</span>
                <span className="font-medium">{loading ? "—" : (userInsights?.engagementMetrics.avgMealsLoggedPerDay ?? 0).toFixed(1)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-zinc-600 dark:text-zinc-400">User streak &gt;7 days</span>
                <span className="font-medium">{loading ? "—" : userInsights?.engagementMetrics.streakStats.usersWithStreakOver7Days ?? 0}</span>
              </div>
            </div>
          </div>

          {/* Diet Quality */}
          <div className="space-y-3">
            <h4 className="text-sm font-medium uppercase tracking-wide text-zinc-500">
              Diet Quality
            </h4>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-zinc-600 dark:text-zinc-400">Avg Diet Score</span>
                <Badge variant="success">{loading ? "—" : (userInsights?.dietQuality.avgDietScore ?? 0).toFixed(1)}</Badge>
              </div>
              <div className="flex justify-between">
                <span className="text-zinc-600 dark:text-zinc-400">Good Diet Users</span>
                <span className="font-medium">{loading ? "—" : userInsights?.dietQuality.usersWithGoodDiet ?? 0}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-zinc-600 dark:text-zinc-400">Improving</span>
                <span className="font-medium text-green-600">↑ {loading ? "—" : userInsights?.dietQuality.improvingUsers ?? 0}</span>
              </div>
            </div>
          </div>

          {/* Nutrient Adequacy */}
          <div className="space-y-3">
            <h4 className="text-sm font-medium uppercase tracking-wide text-zinc-500">
              Nutrient Adequacy
            </h4>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-zinc-600 dark:text-zinc-400">Adequate Protein</span>
                <Badge variant="success">{loading ? "—" : `${(userInsights?.nutrientAdequacy.adequateProtein ?? 0).toFixed(1)}%`}</Badge>
              </div>
              <div className="flex justify-between">
                <span className="text-zinc-600 dark:text-zinc-400">Adequate Fiber</span>
                <Badge variant="warning">{loading ? "—" : `${(userInsights?.nutrientAdequacy.adequateFiber ?? 0).toFixed(1)}%`}</Badge>
              </div>
              <div className="flex justify-between">
                <span className="text-zinc-600 dark:text-zinc-400">High Sodium</span>
                <Badge variant="danger">{loading ? "—" : `${(userInsights?.nutrientAdequacy.highSodium ?? 0).toFixed(1)}%`}</Badge>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
