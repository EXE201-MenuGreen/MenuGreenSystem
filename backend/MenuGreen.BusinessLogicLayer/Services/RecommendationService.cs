using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class RecommendationService : IRecommendationService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IAllergenMatchingService _allergenMatching;
        private readonly ApplicationDbContext _db;
        private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

        public RecommendationService(
            IUnitOfWork unitOfWork,
            IAllergenMatchingService allergenMatching,
            ApplicationDbContext db)
        {
            _unitOfWork = unitOfWork;
            _allergenMatching = allergenMatching;
            _db = db;
        }





        public async Task<IReadOnlyList<RecommendationHistoryResponse>> GetHistoryAsync(Guid userId)
        {
            var histories = await _unitOfWork.RecommendationHistories.FindAsync(x => x.UserId == userId);
            return histories
                .OrderByDescending(x => x.CreatedAt)
                .Select(x => new RecommendationHistoryResponse
                {
                    Id = x.Id,
                    Type = x.Type,
                    Summary = x.Output,
                    Confidence = x.Confidence,
                    CreatedAt = x.CreatedAt
                })
                .ToList();
        }

        public async Task<RecommendationDetailResponse> GetByIdAsync(Guid userId, Guid recommendationId)
        {
            var item = (await _unitOfWork.RecommendationHistories.FindAsync(x => x.UserId == userId && x.Id == recommendationId)).FirstOrDefault()
                ?? throw new Exception("Recommendation not found.");

            return new RecommendationDetailResponse
            {
                Id = item.Id,
                Type = item.Type,
                Input = item.Input,
                Output = item.Output,
                Confidence = item.Confidence,
                CreatedAt = item.CreatedAt
            };
        }

        public async Task DeleteHistoryAsync(Guid userId, Guid recommendationId)
        {
            var item = (await _unitOfWork.RecommendationHistories.FindAsync(x => x.UserId == userId && x.Id == recommendationId)).FirstOrDefault()
                ?? throw new Exception("Recommendation not found.");

            var feedbacks = await _unitOfWork.RecommendationFeedbacks.FindAsync(x => x.RecommendationId == recommendationId);
            var feedbackList = feedbacks.ToList();
            if (feedbackList.Count > 0)
            {
                _unitOfWork.RecommendationFeedbacks.RemoveRange(feedbackList);
            }

            _unitOfWork.RecommendationHistories.Remove(item);
            await _unitOfWork.CompleteAsync();
        }



        public async Task SubmitFeedbackAsync(Guid userId, RecommendationFeedbackRequest request)
        {
            var history = (await _unitOfWork.RecommendationHistories.FindAsync(x => x.UserId == userId && x.Id == request.RecommendationId)).FirstOrDefault()
                ?? throw new Exception("Recommendation not found.");

            var feedback = (await _unitOfWork.RecommendationFeedbacks.FindAsync(x => x.RecommendationId == request.RecommendationId)).FirstOrDefault();
            bool isNew = false;
            if (feedback == null)
            {
                isNew = true;
                feedback = new RecommendationFeedback
                {
                    Id = Guid.NewGuid(),
                    RecommendationId = request.RecommendationId,
                    CreatedAt = DateTime.UtcNow
                };
            }

            feedback.Rating = request.Rating;
            feedback.Feedback = request.Feedback;
            if (feedback.CreatedAt == null) feedback.CreatedAt = DateTime.UtcNow;

            if (isNew)
            {
                await _unitOfWork.RecommendationFeedbacks.AddAsync(feedback);
            }
            else
            {
                _unitOfWork.RecommendationFeedbacks.Update(feedback);
            }
            await _unitOfWork.CompleteAsync();
        }

        public async Task<RecommendationExplainResponse> ExplainAsync(Guid userId, Guid recommendationId)
        {
            var history = (await _unitOfWork.RecommendationHistories.FindAsync(x => x.UserId == userId && x.Id == recommendationId)).FirstOrDefault()
                ?? throw new Exception("Recommendation not found.");

            var feedback = (await _unitOfWork.RecommendationFeedbacks.FindAsync(x => x.RecommendationId == recommendationId)).FirstOrDefault();
            var reasons = new List<string>();
            var matchedRules = new List<string>();
            var usedContext = new List<string>();

            if (!string.IsNullOrWhiteSpace(history.Input)) usedContext.Add("Input request");
            if (!string.IsNullOrWhiteSpace(history.Type)) usedContext.Add(history.Type);
            if ((history.Confidence ?? 0) > 0) usedContext.Add("Confidence score");

            reasons.Add("Recommendation is generated based on historical data and user context.");
            if (!string.IsNullOrWhiteSpace(history.Type))
            {
                matchedRules.Add(history.Type);
                reasons.Add($"Applied recommendation rule type: {history.Type}.");
            }
            if (history.Confidence.HasValue)
            {
                reasons.Add($"Estimated confidence level: {history.Confidence:0.00}.");
            }
            if (feedback != null)
            {
                reasons.Add($"Latest feedback: {(feedback.Rating.HasValue ? feedback.Rating.Value.ToString("0.0") : "N/A")}/5.");
                if (!string.IsNullOrWhiteSpace(feedback.Feedback))
                {
                    reasons.Add($"User note: {feedback.Feedback}");
                }
            }

            return new RecommendationExplainResponse
            {
                RecommendationId = recommendationId,
                Reasons = reasons,
                MatchedRules = matchedRules,
                UsedContext = usedContext
            };
        }

        public async Task<RecommendationScoreResponse> GetScoresAsync(Guid userId, RecommendationScoreRequest request)
        {
            var targetCalories = request.TargetCalories ?? 0;
            var budget = request.BudgetVnd ?? int.MaxValue;
            var limit = request.LimitMinutes ?? int.MaxValue;

            var foods = await _unitOfWork.Foods.FindAsync(x => x.IsActive != false && x.CaloriesKcal.HasValue);
            IEnumerable<Recipe> recipes = await _db.Recipes.Include(r => r.Food).Where(x => x.IsActive != false && x.TotalTimeMin.HasValue).ToListAsync();
            if (request.ExcludeUserAllergies)
            {
                foods = await FilterFoodsByAllergyAsync(foods, userId);
                recipes = await FilterRecipesByAllergyAsync(recipes, userId);
            }

            var caloriesCandidates = foods.Select(f => (double)f.CaloriesKcal!.Value)
                .Concat(recipes.Select(r => (double)(r.Food?.CaloriesKcal ?? 0)))
                .Take(20)
                .ToList();

            var priceCandidates = foods.Select(f => (double)(f.EstimatedPriceVnd ?? 0))
                .Concat(recipes.Select(r => (double)(r.EstimatedPriceVnd ?? 0)))
                .Take(20)
                .ToList();

            var timeCandidates = recipes.Select(r => (double)(r.TotalTimeMin ?? 0)).Take(20).ToList();

            double caloriesScore = caloriesCandidates.Count == 0 || targetCalories <= 0
                ? 0
                : caloriesCandidates.Select(c => 100d - Math.Min(100d, Math.Abs(c - targetCalories) / Math.Max(1, targetCalories) * 100d)).Average();

            double budgetScore = priceCandidates.Count == 0 || budget <= 0
                ? 0
                : priceCandidates.Select(p => 100d - Math.Min(100d, Math.Max(0, p - budget) / Math.Max(1, budget) * 100d)).Average();

            double macroScore = timeCandidates.Count == 0
                ? 70d
                : Math.Max(40d, 100d - (timeCandidates.Average() / Math.Max(1, limit)) * 100d);

            var allergyScore = request.ExcludeUserAllergies ? 100d : 80d;
            var overall = (caloriesScore + macroScore + allergyScore + budgetScore) / 4d;

            return await Task.FromResult(new RecommendationScoreResponse
            {
                CaloriesScore = Math.Round(caloriesScore, 2),
                MacroScore = Math.Round(macroScore, 2),
                AllergyScore = Math.Round(allergyScore, 2),
                BudgetScore = Math.Round(budgetScore, 2),
                OverallScore = Math.Round(overall, 2)
            });
        }

        public async Task<RecommendationRetrainResponse> RetrainAsync(Guid userId, RecommendationRetrainRequest request)
        {
            var evaluatedAt = DateTimeOffset.UtcNow;
            var cutoff = evaluatedAt.AddDays(-request.LookbackDays);
            var histories = await _db.RecommendationHistories
                .AsNoTracking()
                .Where(x => x.UserId == userId && (x.CreatedAt == null || x.CreatedAt >= cutoff))
                .ToListAsync();
            var historyIds = histories.Select(x => x.Id).ToList();
            var feedbacks = historyIds.Count == 0
                ? new List<RecommendationFeedback>()
                : await _db.RecommendationFeedbacks
                    .AsNoTracking()
                    .Where(x => historyIds.Contains(x.RecommendationId))
                    .ToListAsync();

            var historyById = histories.ToDictionary(x => x.Id);
            var grouped = feedbacks
                .Where(x => x.Rating.HasValue && historyById.ContainsKey(x.RecommendationId))
                .GroupBy(x => historyById[x.RecommendationId].Type?.Trim().ToLowerInvariant() ?? "general")
                .ToDictionary(
                    group => group.Key,
                    group =>
                    {
                        var ratings = group.Select(x => x.Rating!.Value).ToList();
                        var average = ratings.Average();
                        return new RecommendationRuleTuningResponse
                        {
                            Samples = ratings.Count,
                            AverageRating = Math.Round(average, 3),
                            Weight = Math.Round(Math.Clamp(1d + ((average - 3d) / 4d), 0.5d, 1.5d), 3),
                        };
                    },
                    StringComparer.OrdinalIgnoreCase);

            var ratedFeedbacks = feedbacks.Where(x => x.Rating.HasValue).ToList();
            var itemSignals = new Dictionary<string, (string DisplayName, int Score)>(StringComparer.OrdinalIgnoreCase);
            foreach (var feedback in ratedFeedbacks.Where(x => x.Rating is >= 4 or <= 2))
            {
                var history = historyById[feedback.RecommendationId];
                var delta = feedback.Rating >= 4 ? 1 : -1;
                foreach (var name in ExtractRecommendationItemNames(history.Output))
                {
                    var key = name.Trim().ToLowerInvariant();
                    if (key.Length == 0) continue;
                    if (!itemSignals.TryGetValue(key, out var current))
                    {
                        current = (DisplayName: name.Trim(), Score: 0);
                    }
                    itemSignals[key] = (current.DisplayName, current.Score + delta);
                }
            }
            var preferredItems = itemSignals.Values
                .Where(x => x.Score > 0)
                .OrderByDescending(x => x.Score)
                .ThenBy(x => x.DisplayName)
                .Take(20)
                .Select(x => x.DisplayName)
                .ToList();
            var avoidedItems = itemSignals.Values
                .Where(x => x.Score < 0)
                .OrderBy(x => x.Score)
                .ThenBy(x => x.DisplayName)
                .Take(20)
                .Select(x => x.DisplayName)
                .ToList();
            var enoughData = ratedFeedbacks.Count >= request.MinimumFeedbackCount;
            var applied = false;
            var status = request.DryRun ? "dry_run" : enoughData ? "applied" : "insufficient_data";

            if (!request.DryRun && enoughData)
            {
                var profile = await _db.UserAiProfiles.FirstOrDefaultAsync(x => x.UserId == userId);
                if (profile == null)
                {
                    profile = new UserAiProfile { UserId = userId };
                    _db.UserAiProfiles.Add(profile);
                }

                JsonObject preferences;
                try
                {
                    preferences = JsonNode.Parse(profile.Preferences ?? "{}") as JsonObject ?? new JsonObject();
                }
                catch (JsonException)
                {
                    preferences = new JsonObject
                    {
                        ["legacyPreferences"] = profile.Preferences,
                    };
                }

                preferences["recommendationTuning"] = JsonSerializer.SerializeToNode(new
                {
                    version = 1,
                    updatedAt = evaluatedAt,
                    sampleCount = ratedFeedbacks.Count,
                    lookbackDays = request.LookbackDays,
                    ruleWeights = grouped,
                    preferredItems,
                    avoidedItems,
                }, JsonOptions);
                profile.Preferences = preferences.ToJsonString(JsonOptions);
                profile.UpdatedAt = evaluatedAt.UtcDateTime;

                _db.ActivityLogs.Add(new ActivityLog
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Action = "RecommendationRulesRecalibrated",
                    EntityType = "UserAiProfile",
                    EntityId = userId,
                    Metadata = JsonSerializer.Serialize(new
                    {
                        sampleCount = ratedFeedbacks.Count,
                        request.LookbackDays,
                        ruleWeights = grouped,
                        preferredItems,
                        avoidedItems,
                    }, JsonOptions),
                    CreatedAt = evaluatedAt,
                });
                await _db.SaveChangesAsync();
                applied = true;
            }

            return new RecommendationRetrainResponse
            {
                DryRun = request.DryRun,
                Applied = applied,
                Status = status,
                HistoriesCount = histories.Count,
                FeedbackCount = ratedFeedbacks.Count,
                PositiveCount = ratedFeedbacks.Count(x => x.Rating >= 4),
                NegativeCount = ratedFeedbacks.Count(x => x.Rating <= 2),
                EvaluatedAt = evaluatedAt,
                RuleWeights = grouped,
                PreferredItems = preferredItems,
                AvoidedItems = avoidedItems,
                Message = request.DryRun
                    ? "Rule recalibration preview completed; no profile data was changed."
                    : applied
                        ? "Personal recommendation rule weights were recalibrated and saved."
                        : $"At least {request.MinimumFeedbackCount} rated feedback items are required before applying recalibration.",
            };
        }

        private static IReadOnlyList<string> ExtractRecommendationItemNames(string? output)
        {
            if (string.IsNullOrWhiteSpace(output)) return Array.Empty<string>();
            try
            {
                using var document = JsonDocument.Parse(output);
                var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                CollectRecommendationNames(document.RootElement, names);
                return names.ToList();
            }
            catch (JsonException)
            {
                return Array.Empty<string>();
            }
        }

        private static void CollectRecommendationNames(JsonElement element, ISet<string> names)
        {
            if (element.ValueKind == JsonValueKind.Array)
            {
                foreach (var child in element.EnumerateArray()) CollectRecommendationNames(child, names);
                return;
            }
            if (element.ValueKind != JsonValueKind.Object) return;

            foreach (var property in element.EnumerateObject())
            {
                if (property.Value.ValueKind == JsonValueKind.String
                    && property.Name is "name" or "title" or "food_name" or "recipe_name")
                {
                    var value = property.Value.GetString()?.Trim();
                    if (!string.IsNullOrWhiteSpace(value)) names.Add(value);
                }
                else if (property.Value.ValueKind is JsonValueKind.Object or JsonValueKind.Array)
                {
                    CollectRecommendationNames(property.Value, names);
                }
            }
        }

        private async Task<IEnumerable<Food>> FilterFoodsByAllergyAsync(IEnumerable<Food> foods, Guid userId)
        {
            var foodList = foods.ToList();
            var userKeys = await _allergenMatching.GetUserAllergenKeysAsync(userId);
            if (userKeys.Count == 0) return foodList;

            var foodKeysMap = await _allergenMatching.GetFoodAllergenKeysAsync(foodList.Select(f => f.Id));
            return foodList.Where(f =>
            {
                foodKeysMap.TryGetValue(f.Id, out var keys);
                keys ??= new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                return !userKeys.Any(uk => keys.Contains(uk));
            });
        }

        private async Task<IEnumerable<Recipe>> FilterRecipesByAllergyAsync(IEnumerable<Recipe> recipes, Guid userId)
        {
            var recipeList = recipes.ToList();
            var userKeys = await _allergenMatching.GetUserAllergenKeysAsync(userId);
            if (userKeys.Count == 0) return recipeList;

            var ids = recipeList.Select(r => r.Id).ToList();
            var ingredientRows = await _db.RecipeIngredients.AsNoTracking()
                .Include(ri => ri.Ingredient)
                .Where(ri => ids.Contains(ri.RecipeId))
                .ToListAsync();

            var namesByRecipe = ids.ToDictionary(id => id, _ => new List<string>());
            foreach (var row in ingredientRows)
            {
                if (!string.IsNullOrWhiteSpace(row.Ingredient?.NameVi) && namesByRecipe.TryGetValue(row.RecipeId, out var list))
                    list.Add(row.Ingredient.NameVi);
            }

            var safe = new List<Recipe>();
            foreach (var recipe in recipeList)
            {
                namesByRecipe.TryGetValue(recipe.Id, out var names);
                var risk = await _allergenMatching.EvaluateRecipeRiskAsync(recipe.FoodId, names ?? new List<string>(), userId);
                if (risk.IsSafeForUser) safe.Add(recipe);
            }

            return safe;
        }

        public async Task UpdateFeedbackAsync(Guid userId, Guid recommendationId, UpdateFeedbackRequest request)
        {
            var history = (await _unitOfWork.RecommendationHistories.FindAsync(x => x.UserId == userId && x.Id == recommendationId)).FirstOrDefault()
                ?? throw new Exception("Recommendation not found.");

            var feedback = (await _unitOfWork.RecommendationFeedbacks.FindAsync(x => x.RecommendationId == recommendationId)).FirstOrDefault();
            if (feedback == null)
            {
                feedback = new RecommendationFeedback
                {
                    Id = Guid.NewGuid(),
                    RecommendationId = recommendationId,
                    CreatedAt = DateTime.UtcNow
                };
                await _unitOfWork.RecommendationFeedbacks.AddAsync(feedback);
            }

            if (request.Rating.HasValue) feedback.Rating = request.Rating.Value;

            var commentPart = request.Comment ?? string.Empty;
            var wouldRecPart = request.WouldRecommend.HasValue ? $"WouldRecommend: {request.WouldRecommend.Value}." : string.Empty;
            feedback.Feedback = string.Join(" ", wouldRecPart, commentPart).Trim();

            if (feedback.CreatedAt == null) feedback.CreatedAt = DateTime.UtcNow;

            _unitOfWork.RecommendationFeedbacks.Update(feedback);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<FeedbackSummaryResponse> GetFeedbackSummaryAsync(Guid userId)
        {
            var histories = await _unitOfWork.RecommendationHistories.FindAsync(x => x.UserId == userId);
            var historyIds = histories.Select(x => x.Id).ToList();

            var feedbacks = await _unitOfWork.RecommendationFeedbacks.FindAsync(x => historyIds.Contains(x.RecommendationId));
            var feedbackList = feedbacks.ToList();

            int totalFeedbacks = feedbackList.Count;
            int positiveCount = feedbackList.Count(x => x.Rating >= 4);
            int negativeCount = feedbackList.Count(x => x.Rating <= 3);
            double positiveRate = totalFeedbacks > 0 ? (double)positiveCount / totalFeedbacks : 0;

            var byMealType = new Dictionary<string, MealTypeFeedbackStatsDto>(StringComparer.OrdinalIgnoreCase);

            var mealTypes = new[] { "breakfast", "lunch", "dinner", "snack" };
            foreach (var type in mealTypes)
            {
                byMealType[type] = new MealTypeFeedbackStatsDto { Positive = 0, Negative = 0, Rate = 0 };
            }

            foreach (var fb in feedbackList)
            {
                var hist = histories.FirstOrDefault(x => x.Id == fb.RecommendationId);
                if (hist != null && !string.IsNullOrWhiteSpace(hist.Input))
                {
                    string? detectedMealType = null;
                    try
                    {
                        using var doc = JsonDocument.Parse(hist.Input);
                        if (doc.RootElement.TryGetProperty("MealType", out var prop))
                        {
                            detectedMealType = prop.GetString()?.ToLowerInvariant();
                        }
                    }
                    catch
                    {
                        // ignore parsing error
                    }

                    if (string.IsNullOrEmpty(detectedMealType))
                    {
                        if (hist.Type != null && hist.Type.Contains("Lunch", StringComparison.OrdinalIgnoreCase))
                        {
                            detectedMealType = "lunch";
                        }
                    }

                    if (!string.IsNullOrEmpty(detectedMealType))
                    {
                        string matchedKey = "snack";
                        if (detectedMealType.Contains("breakfast", StringComparison.OrdinalIgnoreCase)) matchedKey = "breakfast";
                        else if (detectedMealType.Contains("lunch", StringComparison.OrdinalIgnoreCase)) matchedKey = "lunch";
                        else if (detectedMealType.Contains("dinner", StringComparison.OrdinalIgnoreCase)) matchedKey = "dinner";

                        if (fb.Rating >= 4)
                        {
                            byMealType[matchedKey].Positive++;
                        }
                        else
                        {
                            byMealType[matchedKey].Negative++;
                        }
                    }
                }
            }

            foreach (var type in mealTypes)
            {
                var stats = byMealType[type];
                var total = stats.Positive + stats.Negative;
                stats.Rate = total > 0 ? (double)stats.Positive / total : 0;
            }

            return new FeedbackSummaryResponse
            {
                TotalFeedbacks = totalFeedbacks,
                PositiveCount = positiveCount,
                NegativeCount = negativeCount,
                PositiveRate = positiveRate,
                ByMealType = byMealType
            };
        }
    }
}
