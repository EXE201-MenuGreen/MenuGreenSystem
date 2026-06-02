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
    public class FoodService : IFoodService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ApplicationDbContext _db;

        public FoodService(IUnitOfWork unitOfWork, ApplicationDbContext db)
        {
            _unitOfWork = unitOfWork;
            _db = db;
        }

        public async Task<FoodResponse> CreateAsync(FoodUpsertRequest request)
        {
            var food = new Food
            {
                Id = Guid.NewGuid(),
                NameVi = request.NameVi,
                NameEn = request.NameEn,
                Category = request.Category,
                Description = request.Description,
                CaloriesKcal = request.CaloriesKcal,
                ProteinG = request.ProteinG,
                CarbsG = request.CarbsG,
                FatG = request.FatG,
                FiberG = request.FiberG,
                EstimatedPriceVnd = request.EstimatedPriceVnd,
                DefaultServingG = request.DefaultServingG,
                ImageUrl = request.ImageUrl,
                IsActive = request.IsActive ?? true,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Foods.AddAsync(food);
            await _unitOfWork.CompleteAsync();
            return Map(food);
        }

        public async Task<FoodResponse> UpdateAsync(Guid id, FoodUpsertRequest request)
        {
            var food = await _unitOfWork.Foods.GetByIdAsync(id) ?? throw new Exception("Food not found.");
            food.NameVi = request.NameVi;
            food.NameEn = request.NameEn;
            food.Category = request.Category;
            food.Description = request.Description;
            food.CaloriesKcal = request.CaloriesKcal;
            food.ProteinG = request.ProteinG;
            food.CarbsG = request.CarbsG;
            food.FatG = request.FatG;
            food.FiberG = request.FiberG;
            food.EstimatedPriceVnd = request.EstimatedPriceVnd;
            food.DefaultServingG = request.DefaultServingG;
            food.ImageUrl = request.ImageUrl;
            food.IsActive = request.IsActive ?? food.IsActive;
            _unitOfWork.Foods.Update(food);
            await _unitOfWork.CompleteAsync();
            return Map(food);
        }

        public async Task DeleteAsync(Guid id)
        {
            var food = await _unitOfWork.Foods.GetByIdAsync(id) ?? throw new Exception("Food not found.");
            _unitOfWork.Foods.Remove(food);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<FoodResponse> GetByIdAsync(Guid id) => Map(await _unitOfWork.Foods.GetByIdAsync(id) ?? throw new Exception("Food not found."));

        public async Task<FoodSearchResponse> SearchAsync(string? keyword, decimal? minCalories, decimal? maxCalories, string? proteinLevel, int? maxPriceVnd, int? maxPrepTimeMin, string? category)
        {
            var foods = (await _unitOfWork.Foods.GetAllAsync()).Where(f => f.IsActive != false);
            if (!string.IsNullOrWhiteSpace(keyword)) foods = foods.Where(f => f.NameVi.Contains(keyword, StringComparison.OrdinalIgnoreCase) || (f.NameEn ?? string.Empty).Contains(keyword, StringComparison.OrdinalIgnoreCase));
            if (minCalories.HasValue) foods = foods.Where(f => (f.CaloriesKcal ?? 0) >= minCalories.Value);
            if (maxCalories.HasValue) foods = foods.Where(f => (f.CaloriesKcal ?? 0) <= maxCalories.Value);
            if (!string.IsNullOrWhiteSpace(category)) foods = foods.Where(f => string.Equals(f.Category, category, StringComparison.OrdinalIgnoreCase));
            if (maxPriceVnd.HasValue) foods = foods.Where(f => (f.EstimatedPriceVnd ?? int.MaxValue) <= maxPriceVnd.Value);
            if (!string.IsNullOrWhiteSpace(proteinLevel)) foods = proteinLevel.Equals("high", StringComparison.OrdinalIgnoreCase) ? foods.Where(f => (f.ProteinG ?? 0) >= 20) : foods.Where(f => (f.ProteinG ?? 0) < 20);
            if (maxPrepTimeMin.HasValue) foods = foods.Where(f => true);
            return new FoodSearchResponse { TotalCount = foods.Count(), Items = foods.Select(Map).ToList() };
        }

        public async Task<IReadOnlyList<RecipeResponse>> GetRecipesAsync(Guid foodId)
        {
            var recipes = await _db.Recipes
                .AsNoTracking()
                .Include(r => r.RecipeIngredients)
                .ThenInclude(ri => ri.Ingredient)
                .Where(r => r.FoodId == foodId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return recipes.Select(r => new RecipeResponse
            {
                Id = r.Id,
                FoodId = r.FoodId,
                Title = r.Title,
                Description = r.Description,
                PrepTimeMin = r.PrepTimeMin,
                CookTimeMin = r.CookTimeMin,
                TotalTimeMin = r.TotalTimeMin,
                Servings = r.Servings,
                Difficulty = r.Difficulty,
                MealType = r.MealType,
                EstimatedPriceVnd = r.EstimatedPriceVnd,
                Instructions = r.Instructions,
                ImageUrl = r.ImageUrl,
                VideoUrl = r.VideoUrl,
                IsActive = r.IsActive,
                Ingredients = r.RecipeIngredients.Select(ri => new RecipeIngredientResponse
                {
                    IngredientId = ri.IngredientId,
                    IngredientName = ri.Ingredient?.NameVi ?? string.Empty,
                    Quantity = ri.Quantity ?? 0,
                    Unit = ri.Unit ?? string.Empty,
                    Notes = ri.Notes
                }).ToList()
            }).ToList();
        }

        public async Task<IReadOnlyList<FoodResponse>> GetSimilarAsync(Guid foodId)
        {
            var currentFood = await _unitOfWork.Foods.GetByIdAsync(foodId) ?? throw new Exception("Food not found.");
            var foods = (await _unitOfWork.Foods.GetAllAsync())
                .Where(f => f.IsActive != false && f.Id != foodId);

            if (!string.IsNullOrWhiteSpace(currentFood.Category))
            {
                foods = foods.Where(f => string.Equals(f.Category, currentFood.Category, StringComparison.OrdinalIgnoreCase));
            }

            var similar = foods
                .OrderBy(f => Math.Abs((double)((f.CaloriesKcal ?? 0) - (currentFood.CaloriesKcal ?? 0))))
                .Take(10)
                .Select(Map)
                .ToList();

            return similar;
        }

        public async Task<IReadOnlyList<FavoriteFoodResponse>> GetFavoritesAsync(Guid userId)
        {
            var favorites = await _db.FavoriteFoods
                .AsNoTracking()
                .Include(x => x.Food)
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync();

            return favorites.Select(x => new FavoriteFoodResponse
            {
                FoodId = x.FoodId,
                NameVi = x.Food?.NameVi ?? string.Empty,
                NameEn = x.Food?.NameEn,
                Category = x.Food?.Category,
                CaloriesKcal = x.Food?.CaloriesKcal,
                ProteinG = x.Food?.ProteinG,
                CarbsG = x.Food?.CarbsG,
                FatG = x.Food?.FatG,
                EstimatedPriceVnd = x.Food?.EstimatedPriceVnd,
                ImageUrl = x.Food?.ImageUrl,
                CreatedAt = x.CreatedAt
            }).ToList();
        }

        public async Task FavoriteAsync(Guid userId, Guid foodId)
        {
            var food = await _unitOfWork.Foods.GetByIdAsync(foodId) ?? throw new Exception("Food not found.");
            var existing = await _db.FavoriteFoods.FirstOrDefaultAsync(x => x.UserId == userId && x.FoodId == foodId);
            if (existing != null) return;

            await _db.FavoriteFoods.AddAsync(new FavoriteFood
            {
                UserId = userId,
                FoodId = food.Id,
                CreatedAt = DateTime.UtcNow
            });

            await _db.SaveChangesAsync();
        }

        public async Task UnfavoriteAsync(Guid userId, Guid foodId)
        {
            var existing = await _db.FavoriteFoods.FirstOrDefaultAsync(x => x.UserId == userId && x.FoodId == foodId);
            if (existing == null) return;

            _db.FavoriteFoods.Remove(existing);
            await _db.SaveChangesAsync();
        }

        private static FoodResponse Map(Food f) => new() { Id = f.Id, NameVi = f.NameVi, NameEn = f.NameEn, Category = f.Category, Description = f.Description, CaloriesKcal = f.CaloriesKcal, ProteinG = f.ProteinG, CarbsG = f.CarbsG, FatG = f.FatG, FiberG = f.FiberG, EstimatedPriceVnd = f.EstimatedPriceVnd, DefaultServingG = f.DefaultServingG, ImageUrl = f.ImageUrl, IsActive = f.IsActive };
    }
}
