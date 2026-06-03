using System;
using System.Collections.Generic;
using System.Linq;
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
    public class RecipeService : IRecipeService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ApplicationDbContext _db;

        public RecipeService(IUnitOfWork unitOfWork, ApplicationDbContext db)
        {
            _unitOfWork = unitOfWork;
            _db = db;
        }

        public async Task<RecipeResponse> CreateAsync(RecipeUpsertRequest request)
        {
            var recipe = new Recipe { Id = Guid.NewGuid(), FoodId = request.FoodId, Title = request.Title, Description = request.Description, PrepTimeMin = request.PrepTimeMin, CookTimeMin = request.CookTimeMin, TotalTimeMin = request.TotalTimeMin ?? ((request.PrepTimeMin ?? 0)+(request.CookTimeMin ?? 0)), Servings = request.Servings, Difficulty = request.Difficulty, MealType = request.MealType, EstimatedPriceVnd = request.EstimatedPriceVnd, Instructions = request.Instructions, ImageUrl = request.ImageUrl, VideoUrl = request.VideoUrl, IsActive = request.IsActive ?? true, CreatedAt = DateTime.UtcNow };
            await _unitOfWork.Recipes.AddAsync(recipe); await _unitOfWork.CompleteAsync();
            await UpsertIngredients(recipe.Id, request.Ingredients);
            return await GetByIdAsync(recipe.Id);
        }

        public async Task<RecipeResponse> UpdateAsync(Guid id, RecipeUpsertRequest request)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id) ?? throw new Exception("Recipe not found.");
            recipe.FoodId = request.FoodId; recipe.Title = request.Title; recipe.Description = request.Description; recipe.PrepTimeMin = request.PrepTimeMin; recipe.CookTimeMin = request.CookTimeMin; recipe.TotalTimeMin = request.TotalTimeMin ?? ((request.PrepTimeMin ?? 0)+(request.CookTimeMin ?? 0)); recipe.Servings = request.Servings; recipe.Difficulty = request.Difficulty; recipe.MealType = request.MealType; recipe.EstimatedPriceVnd = request.EstimatedPriceVnd; recipe.Instructions = request.Instructions; recipe.ImageUrl = request.ImageUrl; recipe.VideoUrl = request.VideoUrl; recipe.IsActive = request.IsActive ?? recipe.IsActive;
            _unitOfWork.Recipes.Update(recipe); await _unitOfWork.CompleteAsync();
            var existing = await _unitOfWork.RecipeIngredients.FindAsync(x => x.RecipeId == id); _unitOfWork.RecipeIngredients.RemoveRange(existing); await _unitOfWork.CompleteAsync();
            await UpsertIngredients(id, request.Ingredients);
            return await GetByIdAsync(id);
        }

        public async Task DeleteAsync(Guid id) { var recipe = await _unitOfWork.Recipes.GetByIdAsync(id) ?? throw new Exception("Recipe not found."); _unitOfWork.Recipes.Remove(recipe); await _unitOfWork.CompleteAsync(); }
        public async Task<RecipeResponse> GetByIdAsync(Guid id)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id) ?? throw new Exception("Recipe not found.");
            var items = await _unitOfWork.RecipeIngredients.FindAsync(x => x.RecipeId == id);
            var result = Map(recipe);
            result.Ingredients = items.Select(x => new RecipeIngredientResponse { IngredientId = x.IngredientId, IngredientName = x.Ingredient?.NameVi ?? string.Empty, Quantity = x.Quantity ?? 0, Unit = x.Unit ?? string.Empty, Notes = x.Notes }).ToList();
            return result;
        }

        public async Task<RecipeSearchResponse> SearchAsync(string? keyword, string? mealType, string? difficulty, bool? isActive)
        {
            var recipes = await _unitOfWork.Recipes.GetAllAsync();
            var query = recipes.AsEnumerable();

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                query = query.Where(r =>
                    r.Title.Contains(keyword, StringComparison.OrdinalIgnoreCase) ||
                    (r.Description ?? string.Empty).Contains(keyword, StringComparison.OrdinalIgnoreCase));
            }

            if (!string.IsNullOrWhiteSpace(mealType))
            {
                query = query.Where(r =>
                    string.Equals(r.MealType, mealType, StringComparison.OrdinalIgnoreCase));
            }

            if (!string.IsNullOrWhiteSpace(difficulty))
            {
                query = query.Where(r =>
                    string.Equals(r.Difficulty, difficulty, StringComparison.OrdinalIgnoreCase));
            }

            if (isActive.HasValue)
            {
                query = query.Where(r => r.IsActive == isActive.Value);
            }

            var items = query.Select(Map).ToList();
            return new RecipeSearchResponse { Items = items, TotalCount = items.Count };
        }

        public async Task<IReadOnlyList<RecipeIngredientResponse>> GetIngredientsAsync(Guid recipeId)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(recipeId) ?? throw new Exception("Recipe not found.");
            var items = await _db.RecipeIngredients
                .AsNoTracking()
                .Include(x => x.Ingredient)
                .Where(x => x.RecipeId == recipeId)
                .ToListAsync();

            return items.Select(x => new RecipeIngredientResponse
            {
                IngredientId = x.IngredientId,
                IngredientName = x.Ingredient?.NameVi ?? string.Empty,
                Quantity = x.Quantity ?? 0,
                Unit = x.Unit ?? string.Empty,
                Notes = x.Notes
            }).ToList();
        }

        public async Task<RecipeNutritionResponse> GetNutritionAsync(Guid recipeId)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(recipeId) ?? throw new Exception("Recipe not found.");

            if (recipe.FoodId.HasValue)
            {
                var food = await _unitOfWork.Foods.GetByIdAsync(recipe.FoodId.Value);
                if (food != null)
                {
                    return new RecipeNutritionResponse
                    {
                        CaloriesKcal = food.CaloriesKcal ?? 0,
                        ProteinG = food.ProteinG ?? 0,
                        CarbsG = food.CarbsG ?? 0,
                        FatG = food.FatG ?? 0,
                        FiberG = food.FiberG ?? 0
                    };
                }
            }

            var ingredients = await _db.RecipeIngredients
                .AsNoTracking()
                .Include(x => x.Ingredient)
                .Where(x => x.RecipeId == recipeId)
                .ToListAsync();

            decimal calories = 0, protein = 0, carbs = 0, fat = 0, fiber = 0;
            foreach (var item in ingredients)
            {
                var qty = item.Quantity ?? 0;
                var ingredient = item.Ingredient;
                if (ingredient == null) continue;
                calories += (ingredient.CaloriesKcal ?? 0) * qty;
                protein += (ingredient.ProteinG ?? 0) * qty;
                carbs += (ingredient.CarbsG ?? 0) * qty;
                fat += (ingredient.FatG ?? 0) * qty;
            }

            return new RecipeNutritionResponse
            {
                CaloriesKcal = calories,
                ProteinG = protein,
                CarbsG = carbs,
                FatG = fat,
                FiberG = fiber
            };
        }

        public async Task<IReadOnlyList<RecipeResponse>> GetRelatedAsync(Guid recipeId)
        {
            var current = await _unitOfWork.Recipes.GetByIdAsync(recipeId) ?? throw new Exception("Recipe not found.");
            var recipes = await _unitOfWork.Recipes.GetAllAsync();
            var query = recipes.Where(r => r.Id != recipeId && r.IsActive != false);

            if (!string.IsNullOrWhiteSpace(current.MealType))
            {
                query = query.Where(r => string.Equals(r.MealType, current.MealType, StringComparison.OrdinalIgnoreCase) || string.Equals(r.Difficulty, current.Difficulty, StringComparison.OrdinalIgnoreCase));
            }

            return query
                .Take(10)
                .Select(Map)
                .ToList();
        }

        private async Task UpsertIngredients(Guid recipeId, System.Collections.Generic.List<RecipeIngredientUpsertRequest> ingredients)
        {
            foreach (var item in ingredients)
            {
                await _unitOfWork.RecipeIngredients.AddAsync(new RecipeIngredient { Id = Guid.NewGuid(), RecipeId = recipeId, IngredientId = item.IngredientId, Quantity = item.Quantity, Unit = item.Unit, Notes = item.Notes });
            }
            await _unitOfWork.CompleteAsync();
        }

        private static RecipeResponse Map(Recipe r) => new() { Id = r.Id, FoodId = r.FoodId, Title = r.Title, Description = r.Description, PrepTimeMin = r.PrepTimeMin, CookTimeMin = r.CookTimeMin, TotalTimeMin = r.TotalTimeMin, Servings = r.Servings, Difficulty = r.Difficulty, MealType = r.MealType, EstimatedPriceVnd = r.EstimatedPriceVnd, Instructions = r.Instructions, ImageUrl = r.ImageUrl, VideoUrl = r.VideoUrl, IsActive = r.IsActive };
    }
}
