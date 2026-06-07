using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
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

        public async Task<IEnumerable<RecommendationItemResponse>> RecommendByCaloriesAsync(Guid? userId, RecommendationRequest request)
        {
            var foods = await _unitOfWork.Foods.FindAsync(x => x.IsActive != false && x.CaloriesKcal.HasValue);
            var recipes = await _unitOfWork.Recipes.FindAsync(x => x.IsActive != false && x.TotalTimeMin.HasValue);
            var target = request.TargetCalories ?? 0;

            if (request.ExcludeUserAllergies && userId.HasValue)
            {
                foods = await FilterFoodsByAllergyAsync(foods, userId.Value);
                recipes = await FilterRecipesByAllergyAsync(recipes, userId.Value);
            }

            var items = foods.Select(f => MapFood(f, target, "Food"))
                .Concat(recipes.Where(r => r.FoodId.HasValue).Select(r => MapRecipe(r, target, "Recipe")))
                .OrderBy(x => x.Score)
                .Take(request.Top);

            return items;
        }

        public async Task<IEnumerable<RecommendationItemResponse>> RecommendByEcoAsync(Guid? userId, RecommendationRequest request)
        {
            var foods = await _unitOfWork.Foods.FindAsync(x => x.IsActive != false && x.EstimatedPriceVnd.HasValue);
            var recipes = await _unitOfWork.Recipes.FindAsync(x => x.IsActive != false && x.EstimatedPriceVnd.HasValue && x.TotalTimeMin.HasValue);

            if (request.ExcludeUserAllergies && userId.HasValue)
            {
                foods = await FilterFoodsByAllergyAsync(foods, userId.Value);
                recipes = await FilterRecipesByAllergyAsync(recipes, userId.Value);
            }

            var items = foods.Select(f => MapEcoFood(f, request.BudgetVnd ?? int.MaxValue, request.LimitMinutes ?? int.MaxValue))
                .Concat(recipes.Select(r => MapEcoRecipe(r, request.BudgetVnd ?? int.MaxValue, request.LimitMinutes ?? int.MaxValue)))
                .Where(x => x.EstimatedPriceVnd <= (request.BudgetVnd ?? int.MaxValue) && x.CookingTimeMin <= (request.LimitMinutes ?? int.MaxValue))
                .OrderByDescending(x => x.Score)
                .Take(request.Top);

            return items;
        }

        public async Task<IEnumerable<RecommendationItemResponse>> RecommendLunchAsync(Guid? userId, RecommendationRequest request)
        {
            var lunchBudget = request.BudgetVnd ?? int.MaxValue;
            var targetCalories = request.TargetCalories ?? 0;

            var foods = await _unitOfWork.Foods.FindAsync(x => x.IsActive != false && x.CaloriesKcal.HasValue && x.EstimatedPriceVnd.HasValue);
            var recipes = await _unitOfWork.Recipes.FindAsync(x => x.IsActive != false && x.TotalTimeMin.HasValue && x.EstimatedPriceVnd.HasValue);

            if (request.ExcludeUserAllergies && userId.HasValue)
            {
                foods = await FilterFoodsByAllergyAsync(foods, userId.Value);
                recipes = await FilterRecipesByAllergyAsync(recipes, userId.Value);
            }

            var items = foods.Select(f => MapLunchFood(f, targetCalories, lunchBudget))
                .Concat(recipes.Select(r => MapLunchRecipe(r, targetCalories, lunchBudget)))
                .Where(x => x.EstimatedPriceVnd <= lunchBudget && x.CookingTimeMin < 20)
                .OrderBy(x => x.Score)
                .Take(request.Top);

            return items;
        }

        public async Task<MealPlanResponse> BuildDailyMenuAsync(Guid? userId, RecommendationRequest request)
        {
            var targetCalories = request.TargetCalories ?? 0;
            var breakfastTarget = targetCalories * 0.25m;
            var lunchTarget = targetCalories * 0.35m;
            var dinnerTarget = targetCalories * 0.30m;
            var snackTarget = targetCalories * 0.10m;

            var slots = new[]
            {
                ("breakfast", breakfastTarget, (await RecommendByCaloriesAsync(userId, new RecommendationRequest { TargetCalories = (int)breakfastTarget, Top = 1, ExcludeUserAllergies = request.ExcludeUserAllergies })).ToList()),
                ("lunch", lunchTarget, (await RecommendByCaloriesAsync(userId, new RecommendationRequest { TargetCalories = (int)lunchTarget, Top = 1, ExcludeUserAllergies = request.ExcludeUserAllergies })).ToList()),
                ("dinner", dinnerTarget, (await RecommendByCaloriesAsync(userId, new RecommendationRequest { TargetCalories = (int)dinnerTarget, Top = 1, ExcludeUserAllergies = request.ExcludeUserAllergies })).ToList()),
                ("snack", snackTarget, (await RecommendByCaloriesAsync(userId, new RecommendationRequest { TargetCalories = (int)snackTarget, Top = 1, ExcludeUserAllergies = request.ExcludeUserAllergies })).ToList())
            };

            var items = slots
                .Select(slot => MapDailyMenuItem(slot.Item1, slot.Item3.FirstOrDefault()))
                .Where(x => x != null)
                .Cast<MealPlanItemResponse>()
                .ToList();

            return new MealPlanResponse
            {
                TargetCalories = targetCalories,
                TotalCalories = items.Sum(x => x.TargetCalories ?? 0),
                TotalProteinG = 0,
                TotalCarbsG = 0,
                TotalFatG = 0,
                Items = items
            };
        }

        private static MealPlanItemResponse? MapDailyMenuItem(string mealType, RecommendationItemResponse? recommendation)
        {
            if (recommendation == null) return null;

            var isFood = string.Equals(recommendation.Type, "Food", StringComparison.OrdinalIgnoreCase);
            return new MealPlanItemResponse
            {
                Id = recommendation.Id,
                MealPlanId = Guid.Empty,
                MealType = mealType,
                FoodId = isFood ? recommendation.Id : null,
                RecipeId = isFood ? null : recommendation.Id,
                PlannedDate = null,
                TargetCalories = (int)Math.Round(recommendation.CaloriesKcal),
                IsCompleted = false,
                FoodName = isFood ? recommendation.Name : null,
                RecipeName = isFood ? null : recommendation.Name,
                SourceEntityType = recommendation.Type
            };
        }

        public Task<SmartScheduleResponse> BuildSmartScheduleAsync(SmartScheduleRequest request)
        {
            var reminderTime = request.ExpectedMealTime.AddMinutes(-(request.CookingTimeMinutes + request.BufferMinutes));
            return Task.FromResult(new SmartScheduleResponse
            {
                ExpectedMealTime = request.ExpectedMealTime,
                ReminderTime = reminderTime,
                CookingTimeMinutes = request.CookingTimeMinutes,
                BufferMinutes = request.BufferMinutes
            });
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

        public async Task<IReadOnlyList<RecommendationItemResponse>> PreviewAsync(Guid userId, RecommendationPreviewRequest request)
        {
            var recommendationRequest = new RecommendationRequest
            {
                TargetCalories = request.TargetCalories,
                BudgetVnd = request.BudgetVnd,
                LimitMinutes = request.LimitMinutes,
                Top = 5
            };

            var result = (request.Type?.ToLowerInvariant()) switch
            {
                "eco" => await RecommendByEcoAsync(userId, recommendationRequest),
                "lunch" => await RecommendLunchAsync(userId, recommendationRequest),
                _ => await RecommendByCaloriesAsync(userId, recommendationRequest)
            };

            return result.ToList();
        }

        public async Task SubmitFeedbackAsync(Guid userId, RecommendationFeedbackRequest request)
        {
            var history = (await _unitOfWork.RecommendationHistories.FindAsync(x => x.UserId == userId && x.Id == request.RecommendationId)).FirstOrDefault()
                ?? throw new Exception("Recommendation not found.");

            var feedback = (await _unitOfWork.RecommendationFeedbacks.FindAsync(x => x.RecommendationId == request.RecommendationId)).FirstOrDefault();
            if (feedback == null)
            {
                feedback = new RecommendationFeedback
                {
                    Id = Guid.NewGuid(),
                    RecommendationId = request.RecommendationId,
                    CreatedAt = DateTime.UtcNow
                };
                await _unitOfWork.RecommendationFeedbacks.AddAsync(feedback);
            }

            feedback.Rating = request.Rating;
            feedback.Feedback = request.Feedback;
            if (feedback.CreatedAt == null) feedback.CreatedAt = DateTime.UtcNow;
            _unitOfWork.RecommendationFeedbacks.Update(feedback);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<RecommendationExplainResponse> ExplainAsync(Guid userId, Guid recommendationId)
        {
            var history = (await _unitOfWork.RecommendationHistories.FindAsync(x => x.UserId == userId && x.Id == recommendationId)).FirstOrDefault()
                ?? throw new Exception("Recommendation not found.");

            var reasons = new List<string>();
            var matchedRules = new List<string>();
            var usedContext = new List<string>();

            if (!string.IsNullOrWhiteSpace(history.Input)) usedContext.Add("Input request");
            if (!string.IsNullOrWhiteSpace(history.Type)) usedContext.Add(history.Type);
            if ((history.Confidence ?? 0) > 0) usedContext.Add("Confidence score");

            reasons.Add("Recommendation được tạo dựa trên dữ liệu lịch sử và context của user.");
            if (!string.IsNullOrWhiteSpace(history.Type))
            {
                matchedRules.Add(history.Type);
                reasons.Add($"Áp dụng rule theo kiểu recommendation: {history.Type}.");
            }
            if (history.Confidence.HasValue)
            {
                reasons.Add($"Mức tin cậy ước tính: {history.Confidence:0.00}.");
            }

            return new RecommendationExplainResponse
            {
                RecommendationId = recommendationId,
                Reasons = reasons,
                MatchedRules = matchedRules,
                UsedContext = usedContext
            };
        }

        private static RecommendationItemResponse MapFood(Food food, decimal targetCalories, string type)
        {
            var calories = food.CaloriesKcal ?? 0;
            return new RecommendationItemResponse
            {
                Id = food.Id,
                Name = food.NameVi,
                Type = type,
                CaloriesKcal = calories,
                ProteinG = food.ProteinG ?? 0,
                CarbsG = food.CarbsG ?? 0,
                FatG = food.FatG ?? 0,
                EstimatedPriceVnd = food.EstimatedPriceVnd ?? 0,
                CookingTimeMin = 0,
                Score = Math.Abs(calories - targetCalories)
            };
        }

        private static RecommendationItemResponse MapRecipe(Recipe recipe, decimal targetCalories, string type)
        {
            var calories = recipe.Food?.CaloriesKcal ?? 0;
            return new RecommendationItemResponse
            {
                Id = recipe.Id,
                Name = recipe.Title,
                Type = type,
                CaloriesKcal = calories,
                ProteinG = recipe.Food?.ProteinG ?? 0,
                CarbsG = recipe.Food?.CarbsG ?? 0,
                FatG = recipe.Food?.FatG ?? 0,
                EstimatedPriceVnd = recipe.EstimatedPriceVnd ?? 0,
                CookingTimeMin = recipe.TotalTimeMin ?? 0,
                Score = Math.Abs(calories - targetCalories)
            };
        }

        private static RecommendationItemResponse MapEcoFood(Food food, int budget, int limitMinutes)
        {
            var price = food.EstimatedPriceVnd ?? 0;
            return new RecommendationItemResponse
            {
                Id = food.Id,
                Name = food.NameVi,
                Type = "Food",
                CaloriesKcal = food.CaloriesKcal ?? 0,
                ProteinG = food.ProteinG ?? 0,
                CarbsG = food.CarbsG ?? 0,
                FatG = food.FatG ?? 0,
                EstimatedPriceVnd = price,
                CookingTimeMin = 0,
                Score = (budget - price) + limitMinutes
            };
        }

        private static RecommendationItemResponse MapEcoRecipe(Recipe recipe, int budget, int limitMinutes)
        {
            var price = recipe.EstimatedPriceVnd ?? 0;
            var time = recipe.TotalTimeMin ?? 0;
            return new RecommendationItemResponse
            {
                Id = recipe.Id,
                Name = recipe.Title,
                Type = "Recipe",
                CaloriesKcal = recipe.Food?.CaloriesKcal ?? 0,
                ProteinG = recipe.Food?.ProteinG ?? 0,
                CarbsG = recipe.Food?.CarbsG ?? 0,
                FatG = recipe.Food?.FatG ?? 0,
                EstimatedPriceVnd = price,
                CookingTimeMin = time,
                Score = (budget - price) + (limitMinutes - time)
            };
        }

        private static RecommendationItemResponse MapLunchFood(Food food, decimal targetCalories, int lunchBudget)
        {
            var calories = food.CaloriesKcal ?? 0;
            return new RecommendationItemResponse
            {
                Id = food.Id,
                Name = food.NameVi,
                Type = "Food",
                CaloriesKcal = calories,
                ProteinG = food.ProteinG ?? 0,
                CarbsG = food.CarbsG ?? 0,
                FatG = food.FatG ?? 0,
                EstimatedPriceVnd = food.EstimatedPriceVnd ?? 0,
                CookingTimeMin = 0,
                Score = Math.Abs(calories - targetCalories) + Math.Max(0, (food.EstimatedPriceVnd ?? 0) - lunchBudget)
            };
        }

        private static RecommendationItemResponse MapLunchRecipe(Recipe recipe, decimal targetCalories, int lunchBudget)
        {
            var calories = recipe.Food?.CaloriesKcal ?? 0;
            return new RecommendationItemResponse
            {
                Id = recipe.Id,
                Name = recipe.Title,
                Type = "Recipe",
                CaloriesKcal = calories,
                ProteinG = recipe.Food?.ProteinG ?? 0,
                CarbsG = recipe.Food?.CarbsG ?? 0,
                FatG = recipe.Food?.FatG ?? 0,
                EstimatedPriceVnd = recipe.EstimatedPriceVnd ?? 0,
                CookingTimeMin = recipe.TotalTimeMin ?? 0,
                Score = Math.Abs(calories - targetCalories) + Math.Max(0, (recipe.EstimatedPriceVnd ?? 0) - lunchBudget) + Math.Max(0, (recipe.TotalTimeMin ?? 0) - 20)
            };
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
    }
}
