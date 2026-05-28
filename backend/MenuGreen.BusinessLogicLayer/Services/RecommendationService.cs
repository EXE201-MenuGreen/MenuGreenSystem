using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class RecommendationService : IRecommendationService
    {
        private readonly IUnitOfWork _unitOfWork;

        public RecommendationService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<IEnumerable<RecommendationItemResponse>> RecommendByCaloriesAsync(RecommendationRequest request)
        {
            var foods = await _unitOfWork.Foods.FindAsync(x => x.IsActive != false && x.CaloriesKcal.HasValue);
            var recipes = await _unitOfWork.Recipes.FindAsync(x => x.IsActive != false && x.TotalTimeMin.HasValue);
            var target = request.TargetCalories ?? 0;

            var items = foods.Select(f => MapFood(f, target, "Food"))
                .Concat(recipes.Where(r => r.FoodId.HasValue).Select(r => MapRecipe(r, target, "Recipe")))
                .OrderBy(x => x.Score)
                .Take(request.Top);

            return items;
        }

        public async Task<IEnumerable<RecommendationItemResponse>> RecommendByEcoAsync(RecommendationRequest request)
        {
            var foods = await _unitOfWork.Foods.FindAsync(x => x.IsActive != false && x.EstimatedPriceVnd.HasValue);
            var recipes = await _unitOfWork.Recipes.FindAsync(x => x.IsActive != false && x.EstimatedPriceVnd.HasValue && x.TotalTimeMin.HasValue);

            var items = foods.Select(f => MapEcoFood(f, request.BudgetVnd ?? int.MaxValue, request.LimitMinutes ?? int.MaxValue))
                .Concat(recipes.Select(r => MapEcoRecipe(r, request.BudgetVnd ?? int.MaxValue, request.LimitMinutes ?? int.MaxValue)))
                .Where(x => x.EstimatedPriceVnd <= (request.BudgetVnd ?? int.MaxValue) && x.CookingTimeMin <= (request.LimitMinutes ?? int.MaxValue))
                .OrderByDescending(x => x.Score)
                .Take(request.Top);

            return items;
        }

        public async Task<IEnumerable<RecommendationItemResponse>> RecommendLunchAsync(RecommendationRequest request)
        {
            var lunchBudget = request.BudgetVnd ?? int.MaxValue;
            var targetCalories = request.TargetCalories ?? 0;

            var foods = await _unitOfWork.Foods.FindAsync(x => x.IsActive != false && x.CaloriesKcal.HasValue && x.EstimatedPriceVnd.HasValue);
            var recipes = await _unitOfWork.Recipes.FindAsync(x => x.IsActive != false && x.TotalTimeMin.HasValue && x.EstimatedPriceVnd.HasValue);

            var items = foods.Select(f => MapLunchFood(f, targetCalories, lunchBudget))
                .Concat(recipes.Select(r => MapLunchRecipe(r, targetCalories, lunchBudget)))
                .Where(x => x.EstimatedPriceVnd <= lunchBudget && x.CookingTimeMin < 20)
                .OrderBy(x => x.Score)
                .Take(request.Top);

            return items;
        }

        public async Task<MealPlanResponse> BuildDailyMenuAsync(RecommendationRequest request)
        {
            var targetCalories = request.TargetCalories ?? 0;
            var breakfastTarget = targetCalories * 0.25m;
            var lunchTarget = targetCalories * 0.35m;
            var dinnerTarget = targetCalories * 0.30m;
            var snackTarget = targetCalories * 0.10m;

            var breakfast = (await RecommendByCaloriesAsync(new RecommendationRequest { TargetCalories = (int)breakfastTarget, Top = 1 })).ToList();
            var lunch = (await RecommendByCaloriesAsync(new RecommendationRequest { TargetCalories = (int)lunchTarget, Top = 1 })).ToList();
            var dinner = (await RecommendByCaloriesAsync(new RecommendationRequest { TargetCalories = (int)dinnerTarget, Top = 1 })).ToList();
            var snack = (await RecommendByCaloriesAsync(new RecommendationRequest { TargetCalories = (int)snackTarget, Top = 1 })).ToList();

            var all = breakfast.Concat(lunch).Concat(dinner).Concat(snack).ToList();

            return new MealPlanResponse
            {
                TargetCalories = targetCalories,
                TotalCalories = all.Sum(x => x.CaloriesKcal),
                TotalProteinG = all.Sum(x => x.ProteinG),
                TotalCarbsG = all.Sum(x => x.CarbsG),
                TotalFatG = all.Sum(x => x.FatG),
                Breakfast = breakfast,
                Lunch = lunch,
                Dinner = dinner,
                Snack = snack
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
    }
}
