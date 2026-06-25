using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class PlannedVsActualService : IPlannedVsActualService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IRecipeService _recipeService;

        public PlannedVsActualService(IUnitOfWork unitOfWork, IRecipeService recipeService)
        {
            _unitOfWork = unitOfWork;
            _recipeService = recipeService;
        }

        public async Task<PlannedVsActualSummaryResponse> GetSummaryAsync(Guid userId, DateOnly from, DateOnly to)
        {
            var userPlans = await _unitOfWork.MealPlanHeaders.FindAsync(h => h.UserId == userId);
            var planIds = userPlans.Select(h => h.Id).ToList();

            var planItems = planIds.Any()
                ? (await _unitOfWork.MealPlanItems.FindAsync(i => planIds.Contains(i.MealPlanId) && i.PlannedDate >= from && i.PlannedDate <= to)).ToList()
                : new List<MealPlanItem>();

            var logs = (await _unitOfWork.MealLogs.FindAsync(l =>
                l.UserId == userId &&
                l.LoggedAt.HasValue &&
                DateOnly.FromDateTime(l.LoggedAt.Value) >= from &&
                DateOnly.FromDateTime(l.LoggedAt.Value) <= to)).ToList();

            var foodIds = planItems.Where(i => i.FoodId.HasValue).Select(i => i.FoodId!.Value)
                .Concat(logs.Where(l => l.FoodId.HasValue).Select(l => l.FoodId!.Value))
                .Distinct()
                .ToList();

            var recipeIds = planItems.Where(i => i.RecipeId.HasValue).Select(i => i.RecipeId!.Value)
                .Concat(logs.Where(l => l.RecipeId.HasValue).Select(l => l.RecipeId!.Value))
                .Distinct()
                .ToList();

            var foods = foodIds.Any()
                ? (await _unitOfWork.Foods.FindAsync(f => foodIds.Contains(f.Id))).ToDictionary(f => f.Id)
                : new Dictionary<Guid, Food>();

            var recipes = recipeIds.Any()
                ? (await _unitOfWork.Recipes.FindAsync(r => recipeIds.Contains(r.Id))).ToDictionary(r => r.Id)
                : new Dictionary<Guid, Recipe>();

            var recipeNutrientCache = new Dictionary<Guid, RecipeNutritionResponse>();
            foreach (var rId in recipeIds)
            {
                try
                {
                    var nut = await _recipeService.GetNutritionAsync(rId);
                    recipeNutrientCache[rId] = nut;
                }
                catch
                {
                    recipeNutrientCache[rId] = new RecipeNutritionResponse();
                }
            }

            var response = new PlannedVsActualSummaryResponse
            {
                From = from,
                To = to
            };

            for (var date = from; date <= to; date = date.AddDays(1))
            {
                var dailyPlanned = new PlannedNutrition();
                var dailyActual = new ActualNutrition();

                var dailyItems = planItems.Where(i => i.PlannedDate == date).ToList();
                foreach (var item in dailyItems)
                {
                    decimal calories = item.TargetCalories ?? 0;
                    decimal protein = 0;
                    decimal carbs = 0;
                    decimal fat = 0;
                    decimal cost = 0;

                    if (item.FoodId.HasValue && foods.TryGetValue(item.FoodId.Value, out var food))
                    {
                        cost = food.EstimatedPriceVnd ?? 0;
                        var baseCal = food.CaloriesKcal ?? 0;
                        if (baseCal > 0 && calories > 0)
                        {
                            var ratio = calories / baseCal;
                            protein = (food.ProteinG ?? 0) * ratio;
                            carbs = (food.CarbsG ?? 0) * ratio;
                            fat = (food.FatG ?? 0) * ratio;
                        }
                        else
                        {
                            protein = food.ProteinG ?? 0;
                            carbs = food.CarbsG ?? 0;
                            fat = food.FatG ?? 0;
                            calories = baseCal;
                        }
                    }
                    else if (item.RecipeId.HasValue && recipes.TryGetValue(item.RecipeId.Value, out var recipe))
                    {
                        cost = recipe.EstimatedPriceVnd ?? 0;
                        if (recipeNutrientCache.TryGetValue(recipe.Id, out var nut))
                        {
                            var baseCal = nut.CaloriesKcal;
                            if (baseCal > 0 && calories > 0)
                            {
                                var ratio = calories / baseCal;
                                protein = nut.ProteinG * ratio;
                                carbs = nut.CarbsG * ratio;
                                fat = nut.FatG * ratio;
                            }
                            else
                            {
                                protein = nut.ProteinG;
                                carbs = nut.CarbsG;
                                fat = nut.FatG;
                                calories = baseCal;
                            }
                        }
                    }

                    dailyPlanned.CaloriesKcal += calories;
                    dailyPlanned.ProteinG += protein;
                    dailyPlanned.CarbsG += carbs;
                    dailyPlanned.FatG += fat;
                    dailyPlanned.CostVnd += cost;
                }

                var dailyLogs = logs.Where(l => DateOnly.FromDateTime(l.LoggedAt!.Value) == date).ToList();
                foreach (var log in dailyLogs)
                {
                    dailyActual.CaloriesKcal += log.CaloriesKcal ?? 0;
                    dailyActual.ProteinG += log.ProteinG ?? 0;
                    dailyActual.CarbsG += log.CarbsG ?? 0;
                    dailyActual.FatG += log.FatG ?? 0;

                    decimal cost = 0;
                    if (log.FoodId.HasValue && foods.TryGetValue(log.FoodId.Value, out var food))
                    {
                        var qtyRatio = (log.QuantityG ?? 100m) / 100m;
                        cost = (food.EstimatedPriceVnd ?? 0) * qtyRatio;
                    }
                    else if (log.RecipeId.HasValue && recipes.TryGetValue(log.RecipeId.Value, out var recipe))
                    {
                        var qtyRatio = (log.QuantityG ?? 100m) / 100m;
                        cost = (recipe.EstimatedPriceVnd ?? 0) * qtyRatio;
                    }
                    dailyActual.CostVnd += cost;
                }

                // Round values
                dailyPlanned.CaloriesKcal = Math.Round(dailyPlanned.CaloriesKcal, 1);
                dailyPlanned.ProteinG = Math.Round(dailyPlanned.ProteinG, 1);
                dailyPlanned.CarbsG = Math.Round(dailyPlanned.CarbsG, 1);
                dailyPlanned.FatG = Math.Round(dailyPlanned.FatG, 1);
                dailyPlanned.CostVnd = Math.Round(dailyPlanned.CostVnd, 0);

                dailyActual.CaloriesKcal = Math.Round(dailyActual.CaloriesKcal, 1);
                dailyActual.ProteinG = Math.Round(dailyActual.ProteinG, 1);
                dailyActual.CarbsG = Math.Round(dailyActual.CarbsG, 1);
                dailyActual.FatG = Math.Round(dailyActual.FatG, 1);
                dailyActual.CostVnd = Math.Round(dailyActual.CostVnd, 0);

                response.Details.Add(new PlannedVsActualDto
                {
                    Date = date,
                    Planned = dailyPlanned,
                    Actual = dailyActual
                });

                response.TotalPlanned.CaloriesKcal += dailyPlanned.CaloriesKcal;
                response.TotalPlanned.ProteinG += dailyPlanned.ProteinG;
                response.TotalPlanned.CarbsG += dailyPlanned.CarbsG;
                response.TotalPlanned.FatG += dailyPlanned.FatG;
                response.TotalPlanned.CostVnd += dailyPlanned.CostVnd;

                response.TotalActual.CaloriesKcal += dailyActual.CaloriesKcal;
                response.TotalActual.ProteinG += dailyActual.ProteinG;
                response.TotalActual.CarbsG += dailyActual.CarbsG;
                response.TotalActual.FatG += dailyActual.FatG;
                response.TotalActual.CostVnd += dailyActual.CostVnd;
            }

            response.TotalPlanned.CaloriesKcal = Math.Round(response.TotalPlanned.CaloriesKcal, 1);
            response.TotalPlanned.ProteinG = Math.Round(response.TotalPlanned.ProteinG, 1);
            response.TotalPlanned.CarbsG = Math.Round(response.TotalPlanned.CarbsG, 1);
            response.TotalPlanned.FatG = Math.Round(response.TotalPlanned.FatG, 1);
            response.TotalPlanned.CostVnd = Math.Round(response.TotalPlanned.CostVnd, 0);

            response.TotalActual.CaloriesKcal = Math.Round(response.TotalActual.CaloriesKcal, 1);
            response.TotalActual.ProteinG = Math.Round(response.TotalActual.ProteinG, 1);
            response.TotalActual.CarbsG = Math.Round(response.TotalActual.CarbsG, 1);
            response.TotalActual.FatG = Math.Round(response.TotalActual.FatG, 1);
            response.TotalActual.CostVnd = Math.Round(response.TotalActual.CostVnd, 0);

            return response;
        }

        public async Task<AdherenceScoreResponse> GetAdherenceScoreAsync(Guid userId, DateOnly from, DateOnly to)
        {
            var summary = await GetSummaryAsync(userId, from, to);

            var userPlans = await _unitOfWork.MealPlanHeaders.FindAsync(h => h.UserId == userId);
            var planIds = userPlans.Select(h => h.Id).ToList();

            var planItems = planIds.Any()
                ? (await _unitOfWork.MealPlanItems.FindAsync(i => planIds.Contains(i.MealPlanId) && i.PlannedDate >= from && i.PlannedDate <= to)).ToList()
                : new List<MealPlanItem>();

            var logs = (await _unitOfWork.MealLogs.FindAsync(l =>
                l.UserId == userId &&
                l.LoggedAt.HasValue &&
                DateOnly.FromDateTime(l.LoggedAt.Value) >= from &&
                DateOnly.FromDateTime(l.LoggedAt.Value) <= to)).ToList();

            // 1. Meal Completion Rate (40%)
            double mealCompletionRate = 100;
            if (planItems.Any())
            {
                var completedPlannedCount = planItems.Count(i => i.IsCompleted);
                mealCompletionRate = ((double)completedPlannedCount / planItems.Count) * 100.0;
            }

            // 2. Calorie Deviation Score (30%)
            double calorieDeviationScore = 100;
            if (summary.TotalPlanned.CaloriesKcal > 0)
            {
                var deviationPercent = (double)(Math.Abs(summary.TotalActual.CaloriesKcal - summary.TotalPlanned.CaloriesKcal) / summary.TotalPlanned.CaloriesKcal);
                calorieDeviationScore = Math.Max(0.0, 100.0 - (deviationPercent * 100.0));
            }
            else if (summary.TotalActual.CaloriesKcal > 0)
            {
                calorieDeviationScore = 0;
            }

            // 3. Macro Deviation Score (20%)
            double macroDeviationScore = 100;
            double proteinScore = 100, carbsScore = 100, fatScore = 100;

            if (summary.TotalPlanned.ProteinG > 0)
            {
                var protDev = (double)(Math.Abs(summary.TotalActual.ProteinG - summary.TotalPlanned.ProteinG) / summary.TotalPlanned.ProteinG);
                proteinScore = Math.Max(0.0, 100.0 - (protDev * 100.0));
            }
            else if (summary.TotalActual.ProteinG > 0) proteinScore = 0;

            if (summary.TotalPlanned.CarbsG > 0)
            {
                var carbDev = (double)(Math.Abs(summary.TotalActual.CarbsG - summary.TotalPlanned.CarbsG) / summary.TotalPlanned.CarbsG);
                carbsScore = Math.Max(0.0, 100.0 - (carbDev * 100.0));
            }
            else if (summary.TotalActual.CarbsG > 0) carbsScore = 0;

            if (summary.TotalPlanned.FatG > 0)
            {
                var fatDev = (double)(Math.Abs(summary.TotalActual.FatG - summary.TotalPlanned.FatG) / summary.TotalPlanned.FatG);
                fatScore = Math.Max(0.0, 100.0 - (fatDev * 100.0));
            }
            else if (summary.TotalActual.FatG > 0) fatScore = 0;

            if (summary.TotalPlanned.ProteinG > 0 || summary.TotalPlanned.CarbsG > 0 || summary.TotalPlanned.FatG > 0)
            {
                macroDeviationScore = (proteinScore + carbsScore + fatScore) / 3.0;
            }

            // 4. Unplanned Intake Penalty (10%)
            double unplannedPenaltyScore = 100;
            if (logs.Any())
            {
                var unplannedCount = logs.Count(l => !l.MealPlanItemId.HasValue);
                var unplannedRatio = (double)unplannedCount / logs.Count;
                unplannedPenaltyScore = Math.Max(0.0, 100.0 - (unplannedRatio * 100.0));
            }

            double overallScore = (mealCompletionRate * 0.4) + (calorieDeviationScore * 0.3) + (macroDeviationScore * 0.2) + (unplannedPenaltyScore * 0.1);
            overallScore = Math.Round(overallScore, 1);

            string rating;
            string feedback;

            if (overallScore >= 85)
            {
                rating = "EXCELLENT";
                feedback = "Excellent! You are closely following your meal plan. Keep up this great work.";
            }
            else if (overallScore >= 70)
            {
                rating = "GOOD";
                feedback = "Good job! You are fairly consistent with your plan. Try to reduce unplanned meals for better results.";
            }
            else if (overallScore >= 50)
            {
                rating = "FAIR";
                feedback = "Decent but there are some deviations. Make sure to check in on all your meals and limit unplanned snacks.";
            }
            else
            {
                rating = "POOR";
                feedback = "You are significantly off track. Review the drift analysis to understand the causes and reset your habits.";
            }

            return new AdherenceScoreResponse
            {
                From = from,
                To = to,
                OverallScore = overallScore,
                MealCompletionRate = Math.Round(mealCompletionRate, 1),
                CalorieDeviationScore = Math.Round(calorieDeviationScore, 1),
                MacroDeviationScore = Math.Round(macroDeviationScore, 1),
                UnplannedPenaltyScore = Math.Round(unplannedPenaltyScore, 1),
                Rating = rating,
                Feedback = feedback
            };
        }

        public async Task<DriftAnalysisResponse> GetDriftAnalysisAsync(Guid userId, DateOnly from, DateOnly to)
        {
            var userPlans = await _unitOfWork.MealPlanHeaders.FindAsync(h => h.UserId == userId);
            var planIds = userPlans.Select(h => h.Id).ToList();

            var planItems = planIds.Any()
                ? (await _unitOfWork.MealPlanItems.FindAsync(i => planIds.Contains(i.MealPlanId) && i.PlannedDate >= from && i.PlannedDate <= to)).ToList()
                : new List<MealPlanItem>();

            var logs = (await _unitOfWork.MealLogs.FindAsync(l =>
                l.UserId == userId &&
                l.LoggedAt.HasValue &&
                DateOnly.FromDateTime(l.LoggedAt.Value) >= from &&
                DateOnly.FromDateTime(l.LoggedAt.Value) <= to)).ToList();

            var foodIds = planItems.Where(i => i.FoodId.HasValue).Select(i => i.FoodId!.Value)
                .Concat(logs.Where(l => l.FoodId.HasValue).Select(l => l.FoodId!.Value))
                .Distinct()
                .ToList();

            var recipeIds = planItems.Where(i => i.RecipeId.HasValue).Select(i => i.RecipeId!.Value)
                .Concat(logs.Where(l => l.RecipeId.HasValue).Select(l => l.RecipeId!.Value))
                .Distinct()
                .ToList();

            var foods = foodIds.Any()
                ? (await _unitOfWork.Foods.FindAsync(f => foodIds.Contains(f.Id))).ToDictionary(f => f.Id)
                : new Dictionary<Guid, Food>();

            var recipes = recipeIds.Any()
                ? (await _unitOfWork.Recipes.FindAsync(r => recipeIds.Contains(r.Id))).ToDictionary(r => r.Id)
                : new Dictionary<Guid, Recipe>();

            var response = new DriftAnalysisResponse
            {
                From = from,
                To = to
            };

            // 1. Skipped meals & portion mismatch & substituted items
            foreach (var item in planItems)
            {
                string itemName = string.Empty;
                if (item.FoodId.HasValue && foods.TryGetValue(item.FoodId.Value, out var food))
                {
                    itemName = food.NameVi ?? "Thực phẩm";
                }
                else if (item.RecipeId.HasValue && recipes.TryGetValue(item.RecipeId.Value, out var recipe))
                {
                    itemName = recipe.Title ?? "Công thức";
                }

                var linkedLogs = logs.Where(l => l.MealPlanItemId == item.Id).ToList();

                if (!item.IsCompleted && !linkedLogs.Any())
                {
                    // Skipped
                    response.SkippedMeals.Add(new SkippedMealDetail
                    {
                        MealPlanItemId = item.Id,
                        Date = item.PlannedDate ?? from,
                        MealType = item.MealType ?? "Bữa ăn",
                        ItemName = itemName,
                        TargetCalories = item.TargetCalories ?? 0
                    });
                }
                else
                {
                    foreach (var log in linkedLogs)
                    {
                        string logItemName = string.Empty;
                        if (log.FoodId.HasValue && foods.TryGetValue(log.FoodId.Value, out var f))
                            logItemName = f.NameVi ?? "Thực phẩm";
                        else if (log.RecipeId.HasValue && recipes.TryGetValue(log.RecipeId.Value, out var r))
                            logItemName = r.Title ?? "Công thức";

                        if ((log.FoodId.HasValue && log.FoodId != item.FoodId) || (log.RecipeId.HasValue && log.RecipeId != item.RecipeId))
                        {
                            // Substituted
                            response.SubstitutedItems.Add(new SubstitutedItemDetail
                            {
                                MealPlanItemId = item.Id,
                                MealLogId = log.Id,
                                Date = item.PlannedDate ?? from,
                                MealType = item.MealType ?? "Bữa ăn",
                                PlannedItemName = itemName,
                                PlannedCalories = item.TargetCalories ?? 0,
                                ActualItemName = logItemName,
                                ActualCalories = log.CaloriesKcal ?? 0
                            });
                        }
                        else
                        {
                            // Portion mismatch check
                            var target = item.TargetCalories ?? 0;
                            var actual = log.CaloriesKcal ?? 0;
                            if (target > 0)
                            {
                                var deviation = (actual - target) / (decimal)target;
                                if (Math.Abs(deviation) > 0.1m)
                                {
                                    response.PortionMismatches.Add(new PortionMismatchDetail
                                    {
                                        MealPlanItemId = item.Id,
                                        MealLogId = log.Id,
                                        Date = item.PlannedDate ?? from,
                                        MealType = item.MealType ?? "Bữa ăn",
                                        ItemName = itemName,
                                        PlannedCalories = target,
                                        ActualCalories = actual,
                                        PercentDeviation = Math.Round(deviation * 100, 1)
                                    });
                                }
                            }
                        }
                    }
                }
            }

            // 2. Unplanned intake
            var unplannedLogs = logs.Where(l => !l.MealPlanItemId.HasValue).ToList();
            foreach (var log in unplannedLogs)
            {
                string logItemName = string.Empty;
                if (log.FoodId.HasValue && foods.TryGetValue(log.FoodId.Value, out var f))
                    logItemName = f.NameVi ?? "Thực phẩm";
                else if (log.RecipeId.HasValue && recipes.TryGetValue(log.RecipeId.Value, out var r))
                    logItemName = r.Title ?? "Công thức";

                response.UnplannedIntakes.Add(new UnplannedIntakeDetail
                {
                    MealLogId = log.Id,
                    LoggedAt = log.LoggedAt ?? DateTime.UtcNow,
                    MealType = log.MealType ?? "Bữa ăn tự do",
                    ItemName = string.IsNullOrEmpty(logItemName) ? "Bữa ăn tự do" : logItemName,
                    CaloriesKcal = log.CaloriesKcal ?? 0
                });
            }

            response.SkippedMealsCount = response.SkippedMeals.Count;
            response.UnplannedIntakeCount = response.UnplannedIntakes.Count;
            response.SubstitutedItemsCount = response.SubstitutedItems.Count;
            response.PortionMismatchesCount = response.PortionMismatches.Count;

            return response;
        }

        public async Task<RecommendationResponse> GetRecommendationsAsync(Guid userId)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var from = today.AddDays(-7);

            var score = await GetAdherenceScoreAsync(userId, from, today);
            var drift = await GetDriftAnalysisAsync(userId, from, today);

            var insights = new List<string>();
            var steps = new List<string>();
            string summaryMessage;

            if (score.OverallScore >= 85)
            {
                summaryMessage = "Excellent! You are maintaining perfect progress. Below is detailed analysis to further improve efficiency.";
                insights.Add("You are closely following your meal plan (Score: " + score.OverallScore + ").");
            }
            else
            {
                summaryMessage = "Your 7-day analysis shows opportunities to better align with your calorie/macro targets.";
            }

            // Skipped meals
            if (drift.SkippedMealsCount >= 2)
            {
                var favoriteSkippedMealType = drift.SkippedMeals
                    .GroupBy(x => x.MealType)
                    .OrderByDescending(g => g.Count())
                    .First().Key;
                insights.Add($"You tend to skip meals multiple times in the week ({drift.SkippedMealsCount} times), especially {favoriteSkippedMealType.ToLower()}.");
                steps.Add($"Try not to skip {favoriteSkippedMealType.ToLower()}. Set reminders or prepare quick meals like nuts or smoothies in advance.");
            }

            // Unplanned intake
            if (drift.UnplannedIntakeCount >= 3)
            {
                var totalUnplannedCal = drift.UnplannedIntakes.Sum(x => x.CaloriesKcal);
                insights.Add($"You logged many unplanned meals ({drift.UnplannedIntakeCount} times) totaling approximately {Math.Round(totalUnplannedCal, 0)} kcal.");
                steps.Add("Limit unplanned snacking. If you feel hungry between meals, add a healthy snack from your plan (e.g., yogurt, low-calorie fruit).");
            }

            // Portion mismatch
            if (drift.PortionMismatchesCount >= 2)
            {
                var avgPortionDev = drift.PortionMismatches.Average(x => x.PercentDeviation);
                string direction = avgPortionDev > 0 ? "more calories" : "fewer calories";
                insights.Add($"You ate the right dishes but portions deviated from plan (averaging {direction} {Math.Abs(Math.Round(avgPortionDev, 1))}% off).");
                steps.Add("Use a food scale or portion tools to ensure meals match your nutrition plan.");
            }

            // Substituted items
            if (drift.SubstitutedItemsCount >= 2)
            {
                insights.Add($"You often substitute dishes from the original plan ({drift.SubstitutedItemsCount} times).");
                steps.Add("If you need to substitute, use MenuGreen's 'Alternative food suggestions' to ensure replacement has equivalent calories and nutrition.");
            }

            // General steps if empty
            if (!steps.Any())
            {
                insights.Add("Your eating habits are closely aligned with your goals.");
                steps.Add("Continue preparing meals according to your plan.");
                steps.Add("Log your weight regularly in the morning so the algorithm can fine-tune calorie recommendations.");
            }

            return new RecommendationResponse
            {
                SummaryMessage = summaryMessage,
                Insights = insights,
                ActionableSteps = steps
            };
        }

        public async Task<RecalibrationResponse> RecalibrateNutritionAsync(Guid userId)
        {
            var healthProfile = (await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId)).FirstOrDefault();
            if (healthProfile == null)
            {
                return new RecalibrationResponse
                {
                    IsUpdated = false,
                    RecalibrationReason = "User health profile not found for recalibration."
                };
            }

            var today = DateTime.UtcNow;
            var cutoff = today.AddDays(-14);
            var weightLogs = (await _unitOfWork.WeightLogs.FindAsync(w => w.UserId == userId && w.RecordedAt >= cutoff)).ToList();

            var logsThisWeek = weightLogs.Where(w => w.RecordedAt >= today.AddDays(-7)).ToList();
            var logsLastWeek = weightLogs.Where(w => w.RecordedAt >= today.AddDays(-14) && w.RecordedAt < today.AddDays(-7)).ToList();

            decimal? weightThisWeek = logsThisWeek.Any() ? logsThisWeek.Average(w => w.WeightKg) : null;
            decimal? weightLastWeek = logsLastWeek.Any() ? logsLastWeek.Average(w => w.WeightKg) : null;

            decimal weightChange = 0;

            if (weightThisWeek.HasValue && weightLastWeek.HasValue)
            {
                weightChange = weightThisWeek.Value - weightLastWeek.Value;
            }
            else if (weightThisWeek.HasValue && healthProfile.WeightKg.HasValue)
            {
                weightChange = weightThisWeek.Value - healthProfile.WeightKg.Value;
            }
            else if (weightLogs.Any() && healthProfile.WeightKg.HasValue)
            {
                var latestWeight = weightLogs.OrderByDescending(w => w.RecordedAt).First().WeightKg;
                if (latestWeight.HasValue)
                {
                    weightChange = latestWeight.Value - healthProfile.WeightKg.Value;
                }
            }
            else
            {
                return new RecalibrationResponse
                {
                    IsUpdated = false,
                    RecalibrationReason = "Insufficient weight data (requires initial weight or logs from the last 7 days) to evaluate progress and recalibrate."
                };
            }

            var previousCal = healthProfile.TargetCalories ?? 2000;
            var previousProt = healthProfile.TargetProteinG ?? 120;
            var previousCarb = healthProfile.TargetCarbsG ?? 200;
            var previousFat = healthProfile.TargetFatG ?? 60;

            int newCal = previousCal;
            string reason = string.Empty;
            string goal = (healthProfile.Goal ?? "maintenance").ToLower();

            if (goal.Contains("loss") || goal.Contains("lose") || goal.Contains("giảm"))
            {
                if (weightChange >= -0.1m) // Cân nặng không giảm hoặc tăng
                {
                    newCal = previousCal - 100;
                    if (newCal < 1200) newCal = 1200; // Ngưỡng an toàn tối thiểu

                    reason = $"Mục tiêu giảm cân nhưng cân nặng của bạn hầu như không thay đổi trong tuần qua (Biến động: {Math.Round(weightChange, 2)} kg). Hệ thống giảm 100 kcal để kích hoạt lại quá trình giảm cân.";
                }
                else
                {
                    reason = $"Cân nặng của bạn đang giảm đều đặn và lành mạnh (Giảm: {Math.Round(Math.Abs(weightChange), 2)} kg). Không cần hiệu chỉnh mục tiêu calo.";
                }
            }
            else if (goal.Contains("gain") || goal.Contains("tăng"))
            {
                if (weightChange <= 0.1m) // Cân nặng không tăng hoặc giảm
                {
                    newCal = previousCal + 150;
                    reason = $"Mục tiêu tăng cân/tăng cơ nhưng cân nặng không đổi hoặc giảm trong tuần qua (Biến động: {Math.Round(weightChange, 2)} kg). Hệ thống tăng 150 kcal để kích thích tăng trưởng.";
                }
                else
                {
                    reason = $"Cân nặng của bạn đang tăng đúng tiến độ mục tiêu (Tăng: {Math.Round(weightChange, 2)} kg). Không cần hiệu chỉnh mục tiêu calo.";
                }
            }
            else // Maintenance - Giữ cân
            {
                if (Math.Abs(weightChange) > 0.8m)
                {
                    if (weightChange > 0)
                    {
                        newCal = previousCal - 100;
                        if (newCal < 1200) newCal = 1200;
                        reason = $"Mục tiêu giữ cân nhưng cân nặng bị tăng quá mức trong tuần qua (Tăng: {Math.Round(weightChange, 2)} kg). Hệ thống điều chỉnh giảm 100 kcal để ổn định cân nặng.";
                    }
                    else
                    {
                        newCal = previousCal + 100;
                        reason = $"Mục tiêu giữ cân nhưng cân nặng bị giảm quá mức trong tuần qua (Giảm: {Math.Round(Math.Abs(weightChange), 2)} kg). Hệ thống điều chỉnh tăng 100 kcal để ổn định cân nặng.";
                    }
                }
                else
                {
                    reason = $"Cân nặng của bạn đang duy trì rất ổn định ở mức mong muốn (Biến động: {Math.Round(weightChange, 2)} kg). Không cần điều chỉnh.";
                }
            }

            bool isUpdated = newCal != previousCal;

            int newProt = previousProt;
            int newCarb = previousCarb;
            int newFat = previousFat;

            if (isUpdated && previousCal > 0)
            {
                decimal ratio = (decimal)newCal / previousCal;
                newProt = (int)Math.Round(previousProt * ratio);
                newCarb = (int)Math.Round(previousCarb * ratio);
                newFat = (int)Math.Round(previousFat * ratio);

                healthProfile.TargetCalories = newCal;
                healthProfile.TargetProteinG = newProt;
                healthProfile.TargetCarbsG = newCarb;
                healthProfile.TargetFatG = newFat;
                healthProfile.UpdatedAt = DateTime.UtcNow;

                _unitOfWork.HealthProfiles.Update(healthProfile);
                await _unitOfWork.CompleteAsync();
            }

            return new RecalibrationResponse
            {
                PreviousTargetCalories = previousCal,
                NewTargetCalories = newCal,
                PreviousTargetProteinG = previousProt,
                NewTargetProteinG = newProt,
                PreviousTargetCarbsG = previousCarb,
                NewTargetCarbsG = newCarb,
                PreviousTargetFatG = previousFat,
                NewTargetFatG = newFat,
                RecalibrationReason = reason,
                WeightChangeKg = Math.Round(weightChange, 2),
                IsUpdated = isUpdated
            };
        }

        public async Task<string> GenerateMonthlyReportHtmlAsync(Guid userId, int month, int year)
        {
            var from = new DateOnly(year, month, 1);
            var to = from.AddMonths(1).AddDays(-1);
            if (to > DateOnly.FromDateTime(DateTime.UtcNow))
            {
                to = DateOnly.FromDateTime(DateTime.UtcNow);
            }

            var summary = await GetSummaryAsync(userId, from, to);
            var score = await GetAdherenceScoreAsync(userId, from, to);
            var drift = await GetDriftAnalysisAsync(userId, from, to);

            var sb = new StringBuilder();
            sb.Append("<!DOCTYPE html>");
            sb.Append("<html>");
            sb.Append("<head>");
            sb.Append("<meta charset='utf-8' />");
            sb.Append("<title>Báo cáo bám sát kế hoạch ăn uống</title>");
            sb.Append("<style>");
            sb.Append("body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #333; line-height: 1.6; padding: 20px; max-width: 800px; margin: 0 auto; background-color: #f9f9f9; }");
            sb.Append(".card { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 20px; }");
            sb.Append(".header { text-align: center; border-bottom: 2px solid #2ecc71; padding-bottom: 15px; margin-bottom: 25px; }");
            sb.Append(".header h1 { color: #27ae60; margin: 0; font-size: 26px; }");
            sb.Append(".score-circle { width: 120px; height: 120px; border-radius: 50%; background: #2ecc71; color: white; display: flex; flex-direction: column; justify-content: center; align-items: center; margin: 0 auto 15px; font-weight: bold; }");
            sb.Append(".score-value { font-size: 36px; line-height: 1; }");
            sb.Append(".score-label { font-size: 11px; text-transform: uppercase; letter-spacing: 1px; opacity: 0.9; }");
            sb.Append(".badge { display: inline-block; padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: bold; color: white; }");
            sb.Append(".badge-excellent { background: #2ecc71; }");
            sb.Append(".badge-good { background: #3498db; }");
            sb.Append(".badge-fair { background: #f1c40f; }");
            sb.Append(".badge-poor { background: #e74c3c; }");
            sb.Append(".flex-container { display: flex; justify-content: space-between; gap: 15px; }");
            sb.Append(".flex-child { flex: 1; min-width: 0; }");
            sb.Append("table { width: 100%; border-collapse: collapse; margin-top: 10px; }");
            sb.Append("th, td { border: 1px solid #ddd; padding: 10px; text-align: center; }");
            sb.Append("th { background-color: #f2f2f2; font-weight: bold; }");
            sb.Append(".text-left { text-align: left; }");
            sb.Append(".highlight { font-weight: bold; color: #27ae60; }");
            sb.Append(".section-title { font-size: 18px; color: #2c3e50; border-left: 4px solid #2ecc71; padding-left: 10px; margin-bottom: 15px; }");
            sb.Append(".list-unstyled { list-style: none; padding-left: 0; }");
            sb.Append(".list-unstyled li { margin-bottom: 8px; position: relative; padding-left: 20px; }");
            sb.Append(".list-unstyled li::before { content: '•'; color: #2ecc71; font-weight: bold; display: inline-block; width: 1em; margin-left: -1em; }");
            sb.Append("</style>");
            sb.Append("</head>");
            sb.Append("<body>");

            sb.Append("<div class='card header'>");
            sb.Append($"<h1>BÁO CÁO DINH DƯỠNG & ĐỘ BÁM SÁT KẾ HOẠCH</h1>");
            sb.Append($"<p style='color:#7f8c8d; margin-top:5px;'>Thời gian: {from:dd/MM/yyyy} - {to:dd/MM/yyyy}</p>");
            sb.Append("</div>");

            sb.Append("<div class='card' style='text-align: center;'>");
            string badgeClass = score.Rating switch
            {
                "EXCELLENT" => "badge-excellent",
                "GOOD" => "badge-good",
                "FAIR" => "badge-fair",
                _ => "badge-poor"
            };
            sb.Append($"<div class='score-circle' style='background-color: {(score.Rating == "EXCELLENT" ? "#2ecc71" : score.Rating == "GOOD" ? "#3498db" : score.Rating == "FAIR" ? "#f1c40f" : "#e74c3c")}'>");
            sb.Append($"<div class='score-value'>{score.OverallScore}</div>");
            sb.Append("<div class='score-label'>Điểm bám sát</div>");
            sb.Append("</div>");
            sb.Append($"<div>Đánh giá: <span class='badge {badgeClass}'>{score.Rating}</span></div>");
            sb.Append($"<p style='margin-top: 15px; font-style: italic; color: #555;'>\"{score.Feedback}\"</p>");
            sb.Append("</div>");

            sb.Append("<div class='card'>");
            sb.Append("<div class='section-title'>Tổng hợp Dinh dưỡng (Kế hoạch vs Thực tế)</div>");
            sb.Append("<table>");
            sb.Append("<tr><th>Chỉ số</th><th>Kế hoạch (Planned)</th><th>Thực tế (Actual)</th><th>Sai lệch (Deviation)</th></tr>");
            sb.Append($"<tr><td class='text-left'><b>Năng lượng (kcal)</b></td><td>{summary.TotalPlanned.CaloriesKcal}</td><td>{summary.TotalActual.CaloriesKcal}</td><td class='highlight'>{Math.Round(summary.TotalActual.CaloriesKcal - summary.TotalPlanned.CaloriesKcal, 1)}</td></tr>");
            sb.Append($"<tr><td class='text-left'><b>Protein (g)</b></td><td>{summary.TotalPlanned.ProteinG}</td><td>{summary.TotalActual.ProteinG}</td><td>{Math.Round(summary.TotalActual.ProteinG - summary.TotalPlanned.ProteinG, 1)}</td></tr>");
            sb.Append($"<tr><td class='text-left'><b>Carbs (g)</b></td><td>{summary.TotalPlanned.CarbsG}</td><td>{summary.TotalActual.CarbsG}</td><td>{Math.Round(summary.TotalActual.CarbsG - summary.TotalPlanned.CarbsG, 1)}</td></tr>");
            sb.Append($"<tr><td class='text-left'><b>Chất béo (g)</b></td><td>{summary.TotalPlanned.FatG}</td><td>{summary.TotalActual.FatG}</td><td>{Math.Round(summary.TotalActual.FatG - summary.TotalPlanned.FatG, 1)}</td></tr>");
            sb.Append($"<tr><td class='text-left'><b>Chi phí ước tính (VND)</b></td><td>{summary.TotalPlanned.CostVnd:N0}</td><td>{summary.TotalActual.CostVnd:N0}</td><td>{Math.Round(summary.TotalActual.CostVnd - summary.TotalPlanned.CostVnd, 0):N0}</td></tr>");
            sb.Append("</table>");
            sb.Append("</div>");

            sb.Append("<div class='flex-container'>");
            
            sb.Append("<div class='card flex-child'>");
            sb.Append("<div class='section-title'>Điểm thành phần</div>");
            sb.Append("<ul class='list-unstyled'>");
            sb.Append($"<li>Hoàn thành bữa ăn: <b>{score.MealCompletionRate}/100</b></li>");
            sb.Append($"<li>Độ bám sát Calo: <b>{score.CalorieDeviationScore}/100</b></li>");
            sb.Append($"<li>Độ bám sát Macro: <b>{score.MacroDeviationScore}/100</b></li>");
            sb.Append($"<li>Hạn chế ăn ngoài plan: <b>{score.UnplannedPenaltyScore}/100</b></li>");
            sb.Append("</ul>");
            sb.Append("</div>");

            sb.Append("<div class='card flex-child'>");
            sb.Append("<div class='section-title'>Thống kê Hành vi (Drift)</div>");
            sb.Append("<ul class='list-unstyled'>");
            sb.Append($"<li>Bữa ăn bị bỏ qua: <b style='color:#e74c3c'>{drift.SkippedMealsCount}</b></li>");
            sb.Append($"<li>Bữa ăn ngoài kế hoạch: <b style='color:#f1c40f'>{drift.UnplannedIntakeCount}</b></li>");
            sb.Append($"<li>Thay thế món ăn: <b>{drift.SubstitutedItemsCount}</b></li>");
            sb.Append($"<li>Khẩu phần không khớp: <b>{drift.PortionMismatchesCount}</b></li>");
            sb.Append("</ul>");
            sb.Append("</div>");

            sb.Append("</div>");

            if (drift.SkippedMeals.Any() || drift.UnplannedIntakes.Any())
            {
                sb.Append("<div class='card'>");
                sb.Append("<div class='section-title'>Chi tiết các bữa ăn lệch chính</div>");
                
                if (drift.SkippedMeals.Any())
                {
                    sb.Append("<h4>Bữa ăn trong kế hoạch bị bỏ qua:</h4>");
                    sb.Append("<ul>");
                    foreach (var m in drift.SkippedMeals.Take(5))
                    {
                        sb.Append($"<li>Ngày {m.Date:dd/MM}: {m.MealType} - {m.ItemName} ({m.TargetCalories} kcal)</li>");
                    }
                    if (drift.SkippedMealsCount > 5) sb.Append($"<li>... và {drift.SkippedMealsCount - 5} bữa ăn khác.</li>");
                    sb.Append("</ul>");
                }

                if (drift.UnplannedIntakes.Any())
                {
                    sb.Append("<h4>Các bữa ăn tự do nạp calo ngoài kế hoạch nhiều nhất:</h4>");
                    sb.Append("<ul>");
                    foreach (var m in drift.UnplannedIntakes.OrderByDescending(x => x.CaloriesKcal).Take(5))
                    {
                        sb.Append($"<li>Ngày {m.LoggedAt:dd/MM} ({m.MealType}): {m.ItemName} (+{Math.Round(m.CaloriesKcal, 0)} kcal)</li>");
                    }
                    if (drift.UnplannedIntakeCount > 5) sb.Append($"<li>... và {drift.UnplannedIntakeCount - 5} bữa tự do khác.</li>");
                    sb.Append("</ul>");
                }
                sb.Append("</div>");
            }

            sb.Append("<div class='card' style='border-top: 2px solid #2ecc71; text-align: center; font-size: 12px; color: #7f8c8d; margin-top: 30px;'>");
            sb.Append("<p>Báo cáo được tự động tạo bởi hệ thống dinh dưỡng MenuGreen.</p>");
            sb.Append("</div>");

            sb.Append("</body>");
            sb.Append("</html>");

            return sb.ToString();
        }
    }
}
