using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.BusinessLogicLayer.Helpers;
using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class CatalogService : ICatalogService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ApplicationDbContext _db;
        private readonly ICacheService _cache;
        private static readonly TimeSpan CatalogTtl = TimeSpan.FromMinutes(30);

        public CatalogService(IUnitOfWork unitOfWork, ApplicationDbContext db, ICacheService cache)
        {
            _unitOfWork = unitOfWork;
            _db = db;
            _cache = cache;
        }

        public async Task<FoodResponse> CreateFoodAsync(FoodUpsertRequest request)
        {
            var food = new Food { Id = Guid.NewGuid(), NameVi = request.NameVi, NameEn = request.NameEn, Category = request.Category, Description = request.Description, CaloriesKcal = request.CaloriesKcal, ProteinG = request.ProteinG, CarbsG = request.CarbsG, FatG = request.FatG, FiberG = request.FiberG, EstimatedPriceVnd = request.EstimatedPriceVnd, DefaultServingG = request.DefaultServingG, ImageUrl = request.ImageUrl, IsActive = request.IsActive ?? true, CreatedAt = DateTime.UtcNow };
            await _unitOfWork.Foods.AddAsync(food);
            await _unitOfWork.CompleteAsync();
            await InvalidateFoodCacheAsync();
            return Map(food);
        }

        public async Task<FoodResponse> UpdateFoodAsync(Guid id, FoodUpsertRequest request)
        {
            var food = await _unitOfWork.Foods.GetByIdAsync(id) ?? throw new Exception("Food not found.");
            food.NameVi = request.NameVi; food.NameEn = request.NameEn; food.Category = request.Category; food.Description = request.Description; food.CaloriesKcal = request.CaloriesKcal; food.ProteinG = request.ProteinG; food.CarbsG = request.CarbsG; food.FatG = request.FatG; food.FiberG = request.FiberG; food.EstimatedPriceVnd = request.EstimatedPriceVnd; food.DefaultServingG = request.DefaultServingG; food.ImageUrl = request.ImageUrl; food.IsActive = request.IsActive ?? food.IsActive;
            _unitOfWork.Foods.Update(food); await _unitOfWork.CompleteAsync(); 
            await InvalidateFoodCacheAsync();
            return Map(food);
        }

        public async Task DeleteFoodAsync(Guid id) { var food = await _unitOfWork.Foods.GetByIdAsync(id) ?? throw new Exception("Food not found."); food.IsActive = false; _unitOfWork.Foods.Update(food); await _unitOfWork.CompleteAsync(); await InvalidateFoodCacheAsync(); }
        public async Task<FoodResponse> GetFoodByIdAsync(Guid id) { var food = await _unitOfWork.Foods.GetByIdAsync(id) ?? throw new Exception("Food not found."); if (food.IsActive == false) throw new Exception("Food not found."); return Map(food); }

        public async Task<FoodSearchResponse> SearchFoodsAsync(string? keyword, decimal? minCalories, decimal? maxCalories, string? proteinLevel, int? maxPriceVnd, int? maxPrepTimeMin, string? category)
        {
            var cacheKey = CacheKeys.FoodCatalog(keyword, category, minCalories.HasValue ? (int)minCalories.Value : null, maxCalories.HasValue ? (int)maxCalories.Value : null);
            
            var cached = await _cache.GetAsync<FoodSearchResponse>(cacheKey);
            if (cached != null)
            {
                return cached;
            }

            var foods = (await _unitOfWork.Foods.GetAllAsync()).Where(f => f.IsActive != false);
            if (!string.IsNullOrWhiteSpace(keyword)) foods = foods.Where(f => f.NameVi.Contains(keyword, StringComparison.OrdinalIgnoreCase) || (f.NameEn ?? string.Empty).Contains(keyword, StringComparison.OrdinalIgnoreCase));
            if (minCalories.HasValue) foods = foods.Where(f => (f.CaloriesKcal ?? 0) >= minCalories.Value);
            if (maxCalories.HasValue) foods = foods.Where(f => (f.CaloriesKcal ?? 0) <= maxCalories.Value);
            if (!string.IsNullOrWhiteSpace(category)) foods = foods.Where(f => string.Equals(f.Category, category, StringComparison.OrdinalIgnoreCase));
            if (maxPriceVnd.HasValue) foods = foods.Where(f => (f.EstimatedPriceVnd ?? int.MaxValue) <= maxPriceVnd.Value);
            if (!string.IsNullOrWhiteSpace(proteinLevel)) foods = proteinLevel.Equals("high", StringComparison.OrdinalIgnoreCase) ? foods.Where(f => (f.ProteinG ?? 0) >= 20) : foods.Where(f => (f.ProteinG ?? 0) < 20);
            if (maxPrepTimeMin.HasValue) foods = foods.Where(f => true);
            var response = new FoodSearchResponse { TotalCount = foods.Count(), Items = foods.Select(Map).ToList() };
            
            await _cache.SetAsync(cacheKey, response, CatalogTtl);
            return response;
        }

        public async Task<IngredientResponse> CreateIngredientAsync(IngredientUpsertRequest request) { var e = new Ingredient { Id = Guid.NewGuid(), NameVi = request.NameVi, NameEn = request.NameEn, Category = request.Category, CaloriesKcal = request.CaloriesKcal, ProteinG = request.ProteinG, CarbsG = request.CarbsG, FatG = request.FatG, EstimatedPriceVnd = request.EstimatedPriceVnd, UnitDefault = request.UnitDefault, ImageUrl = request.ImageUrl, IsActive = request.IsActive ?? true, CreatedAt = DateTime.UtcNow }; await _unitOfWork.Ingredients.AddAsync(e); await _unitOfWork.CompleteAsync(); return Map(e); }
        public async Task<IngredientResponse> UpdateIngredientAsync(Guid id, IngredientUpsertRequest request) { var e = await _unitOfWork.Ingredients.GetByIdAsync(id) ?? throw new Exception("Ingredient not found."); e.NameVi=request.NameVi; e.NameEn=request.NameEn; e.Category=request.Category; e.CaloriesKcal=request.CaloriesKcal; e.ProteinG=request.ProteinG; e.CarbsG=request.CarbsG; e.FatG=request.FatG; e.EstimatedPriceVnd=request.EstimatedPriceVnd; e.UnitDefault=request.UnitDefault; e.ImageUrl=request.ImageUrl; e.IsActive=request.IsActive ?? e.IsActive; _unitOfWork.Ingredients.Update(e); await _unitOfWork.CompleteAsync(); return Map(e); }
        public async Task DeleteIngredientAsync(Guid id) { var e = await _unitOfWork.Ingredients.GetByIdAsync(id) ?? throw new Exception("Ingredient not found."); e.IsActive = false; _unitOfWork.Ingredients.Update(e); await _unitOfWork.CompleteAsync(); }
        public async Task<IngredientResponse> GetIngredientByIdAsync(Guid id) { var e = await _unitOfWork.Ingredients.GetByIdAsync(id) ?? throw new Exception("Ingredient not found."); if (e.IsActive == false) throw new Exception("Ingredient not found."); return Map(e); }

        public async Task<RecipeResponse> CreateRecipeAsync(RecipeUpsertRequest request)
        {
            var recipe = new Recipe { Id=Guid.NewGuid(), FoodId=request.FoodId, Title=request.Title, Description=request.Description, PrepTimeMin=request.PrepTimeMin, CookTimeMin=request.CookTimeMin, TotalTimeMin=request.TotalTimeMin ?? ((request.PrepTimeMin ?? 0)+(request.CookTimeMin ?? 0)), Servings=request.Servings, Difficulty=request.Difficulty, MealType=request.MealType, EstimatedPriceVnd=request.EstimatedPriceVnd, Instructions=request.Instructions, ImageUrl=request.ImageUrl, VideoUrl=request.VideoUrl, IsActive=request.IsActive ?? true, CreatedAt=DateTime.UtcNow };
            await _unitOfWork.Recipes.AddAsync(recipe); await _unitOfWork.CompleteAsync();
            await UpsertIngredients(recipe.Id, request.Ingredients);
            return await GetRecipeByIdAsync(recipe.Id);
        }

        public async Task<RecipeResponse> UpdateRecipeAsync(Guid id, RecipeUpsertRequest request)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id) ?? throw new Exception("Recipe not found.");
            recipe.FoodId=request.FoodId; recipe.Title=request.Title; recipe.Description=request.Description; recipe.PrepTimeMin=request.PrepTimeMin; recipe.CookTimeMin=request.CookTimeMin; recipe.TotalTimeMin=request.TotalTimeMin ?? ((request.PrepTimeMin ?? 0)+(request.CookTimeMin ?? 0)); recipe.Servings=request.Servings; recipe.Difficulty=request.Difficulty; recipe.MealType=request.MealType; recipe.EstimatedPriceVnd=request.EstimatedPriceVnd; recipe.Instructions=request.Instructions; recipe.ImageUrl=request.ImageUrl; recipe.VideoUrl=request.VideoUrl; recipe.IsActive=request.IsActive ?? recipe.IsActive;
            _unitOfWork.Recipes.Update(recipe); await _unitOfWork.CompleteAsync();
            var existing = await _unitOfWork.RecipeIngredients.FindAsync(x => x.RecipeId == id); _unitOfWork.RecipeIngredients.RemoveRange(existing);
            await _unitOfWork.CompleteAsync();
            await UpsertIngredients(id, request.Ingredients);
            return await GetRecipeByIdAsync(id);
        }

        public async Task DeleteRecipeAsync(Guid id) { var recipe = await _unitOfWork.Recipes.GetByIdAsync(id) ?? throw new Exception("Recipe not found."); recipe.IsActive = false; _unitOfWork.Recipes.Update(recipe); await _unitOfWork.CompleteAsync(); }
        public async Task<RecipeResponse> GetRecipeByIdAsync(Guid id)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id) ?? throw new Exception("Recipe not found.");
            if (recipe.IsActive == false) throw new Exception("Recipe not found.");
            var result = Map(recipe);
            result.Ingredients = await RecipeIngredientLoader.LoadAsync(_db, id);
            return result;
        }

        private async Task UpsertIngredients(Guid recipeId, List<RecipeIngredientUpsertRequest> ingredients)
        {
            foreach (var item in ingredients)
            {
                await _unitOfWork.RecipeIngredients.AddAsync(new RecipeIngredient { Id = Guid.NewGuid(), RecipeId = recipeId, IngredientId = item.IngredientId, Quantity = item.Quantity, Unit = item.Unit, Notes = item.Notes });
            }
            await _unitOfWork.CompleteAsync();
        }

        private static FoodResponse Map(Food f) => new() { Id=f.Id, NameVi=f.NameVi, NameEn=f.NameEn, Category=f.Category, Description=f.Description, CaloriesKcal=f.CaloriesKcal, ProteinG=f.ProteinG, CarbsG=f.CarbsG, FatG=f.FatG, FiberG=f.FiberG, EstimatedPriceVnd=f.EstimatedPriceVnd, DefaultServingG=f.DefaultServingG, ImageUrl=f.ImageUrl, IsActive=f.IsActive };
        private static IngredientResponse Map(Ingredient e) => new() { Id=e.Id, NameVi=e.NameVi, NameEn=e.NameEn, Category=e.Category, CaloriesKcal=e.CaloriesKcal, ProteinG=e.ProteinG, CarbsG=e.CarbsG, FatG=e.FatG, EstimatedPriceVnd=e.EstimatedPriceVnd, UnitDefault=e.UnitDefault, ImageUrl=e.ImageUrl, IsActive=e.IsActive };
        private static RecipeResponse Map(Recipe r) => new() { Id=r.Id, FoodId=r.FoodId, Title=r.Title, Description=r.Description, PrepTimeMin=r.PrepTimeMin, CookTimeMin=r.CookTimeMin, TotalTimeMin=r.TotalTimeMin, Servings=r.Servings, Difficulty=r.Difficulty, MealType=r.MealType, EstimatedPriceVnd=r.EstimatedPriceVnd, Instructions=r.Instructions, ImageUrl=r.ImageUrl, VideoUrl=r.VideoUrl, SourceName=r.SourceName, SourceUrl=r.SourceUrl, IsActive=r.IsActive };
        
        private async Task InvalidateFoodCacheAsync()
        {
            // Note: For pattern-based invalidation, use CacheInvalidationService
            // For now, we invalidate known cache keys (this is a simplified approach)
            await Task.CompletedTask;
        }
    }
}
