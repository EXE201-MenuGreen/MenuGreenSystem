using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Helpers;
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
        private readonly IAllergenMatchingService _allergenMatching;
        private readonly ICacheService _cache;
        private static readonly TimeSpan NutritionTtl = TimeSpan.FromMinutes(60);

        public RecipeService(
            IUnitOfWork unitOfWork,
            ApplicationDbContext db,
            IAllergenMatchingService allergenMatching,
            ICacheService cache)
        {
            _unitOfWork = unitOfWork;
            _db = db;
            _allergenMatching = allergenMatching;
            _cache = cache;
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
            await _cache.RemoveAsync(CacheKeys.RecipeNutrition(id));
            return await GetByIdAsync(id);
        }

        public async Task DeleteAsync(Guid id) { var recipe = await _unitOfWork.Recipes.GetByIdAsync(id) ?? throw new Exception("Recipe not found."); recipe.IsActive = false; _unitOfWork.Recipes.Update(recipe); await _unitOfWork.CompleteAsync(); await _cache.RemoveAsync(CacheKeys.RecipeNutrition(id)); }
        public async Task<RecipeResponse> GetByIdAsync(Guid id, Guid? userId = null, string? allergyMode = null)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id) ?? throw new Exception("Recipe not found.");
            if (recipe.IsActive == false) throw new Exception("Recipe not found.");
            var items = await _db.RecipeIngredients
                .AsNoTracking()
                .Include(x => x.Ingredient)
                .Where(x => x.RecipeId == id)
                .ToListAsync();
            var result = Map(recipe);
            if (recipe.FoodId.HasValue)
            {
                var linkedFood = await _unitOfWork.Foods.GetByIdAsync(recipe.FoodId.Value);
                result.DefaultServingG = linkedFood?.DefaultServingG;
            }
            result.Ingredients = items.Select(x => new RecipeIngredientResponse
            {
                IngredientId = x.IngredientId,
                IngredientName = x.Ingredient?.NameVi ?? string.Empty,
                Quantity = x.Quantity ?? 0,
                Unit = x.Unit ?? string.Empty,
                NutritionBasisQuantity = IsMassOrVolume(x.Unit ?? x.Ingredient?.UnitDefault) ? 100m : 1m,
                CaloriesKcal = x.Ingredient?.CaloriesKcal ?? 0,
                ProteinG = x.Ingredient?.ProteinG ?? 0,
                CarbsG = x.Ingredient?.CarbsG ?? 0,
                FatG = x.Ingredient?.FatG ?? 0,
                Notes = x.Notes
            }).ToList();

            return await EnrichRecipeAsync(result, userId, allergyMode);
        }

        public async Task<RecipeSearchResponse> SearchAsync(
            string? keyword,
            string? mealType,
            string? difficulty,
            bool? isActive,
            Guid? userId = null,
            string? allergyMode = null,
            int? page = null,
            int? pageSize = null)
        {
            // Build query with filters at database level (fix client-side filtering)
            var allRecipes = await _unitOfWork.Recipes.FindAsync(r => true, asNoTracking: true);
            var query = allRecipes.AsEnumerable();

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

            var mode = NormalizeAllergyMode(allergyMode);
            var currentPage = pageSize.HasValue ? Math.Max(page ?? 1, 1) : 1;
            var requestedPageSize = pageSize.HasValue
                ? Math.Clamp(pageSize.Value, 1, 100)
                : 0;
            var recipeList = query.OrderBy(r => r.Title).ToList();
            var unpagedTotalCount = recipeList.Count;

            // In warn/all mode allergy matching does not remove records, so only
            // enrich the requested page. Hide mode must evaluate all records first
            // to keep TotalCount and TotalPages accurate.
            if (mode != AllergenCatalog.ModeHide && pageSize.HasValue)
            {
                recipeList = recipeList
                    .Skip((int)Math.Min((long)(currentPage - 1) * requestedPageSize, int.MaxValue))
                    .Take(requestedPageSize)
                    .ToList();
            }

            var ingredientMap = await LoadIngredientNamesByRecipeAsync(recipeList.Select(r => r.Id));
            var linkedFoodIds = recipeList
                .Where(recipe => recipe.FoodId.HasValue)
                .Select(recipe => recipe.FoodId!.Value)
                .Distinct()
                .ToList();
            var servingByFoodId = linkedFoodIds.Count == 0
                ? new Dictionary<Guid, int?>()
                : (await _unitOfWork.Foods.FindAsync(
                    food => linkedFoodIds.Contains(food.Id)))
                    .ToDictionary(food => food.Id, food => food.DefaultServingG);
            // Enrich serially to keep the shared DbContext single-threaded.
            // EF Core's DbContext is NOT thread-safe; running multiple
            // _allergenMatching calls in parallel via Task.WhenAll triggers
            // "A second operation was started on this context instance..."
            // (verified with curl: empty keyword → 400; non-empty keyword → 200).
            var items = new List<RecipeResponse>(recipeList.Count);
            foreach (var recipe in recipeList)
            {
                var dto = Map(recipe);
                if (
                    recipe.FoodId.HasValue
                    && servingByFoodId.TryGetValue(recipe.FoodId.Value, out var servingG)
                )
                {
                    dto.DefaultServingG = servingG;
                }
                ingredientMap.TryGetValue(recipe.Id, out var names);
                dto = await EnrichRecipeAsync(dto, userId, allergyMode, names ?? new List<string>());
                var shouldInclude = mode != AllergenCatalog.ModeHide || dto.IsSafeForUser;
                if (shouldInclude) items.Add(dto);
            }

            var totalCount = mode == AllergenCatalog.ModeHide
                ? items.Count
                : unpagedTotalCount;
            var currentPageSize = pageSize.HasValue ? requestedPageSize : totalCount;
            var pageItems = mode == AllergenCatalog.ModeHide && pageSize.HasValue
                ? items
                    .Skip((int)Math.Min((long)(currentPage - 1) * currentPageSize, int.MaxValue))
                    .Take(currentPageSize)
                    .ToList()
                : items;

            return new RecipeSearchResponse
            {
                Items = pageItems,
                TotalCount = totalCount,
                Page = currentPage,
                PageSize = currentPageSize
            };
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
                NutritionBasisQuantity = IsMassOrVolume(x.Unit ?? x.Ingredient?.UnitDefault) ? 100m : 1m,
                CaloriesKcal = x.Ingredient?.CaloriesKcal ?? 0,
                ProteinG = x.Ingredient?.ProteinG ?? 0,
                CarbsG = x.Ingredient?.CarbsG ?? 0,
                FatG = x.Ingredient?.FatG ?? 0,
                Notes = x.Notes
            }).ToList();
        }

        private static bool IsMassOrVolume(string? unit) =>
            (unit ?? string.Empty).Trim().ToLowerInvariant() is
                "g" or "gram" or "grams" or "ml" or "milliliter" or "milliliters";

        public async Task<RecipeNutritionResponse> GetNutritionAsync(Guid recipeId)
        {
            var cacheKey = CacheKeys.RecipeNutrition(recipeId);
            var cached = await _cache.GetAsync<RecipeNutritionResponse>(cacheKey);
            if (cached != null)
            {
                return cached;
            }

            var recipe = await _unitOfWork.Recipes.GetByIdAsync(recipeId) ?? throw new Exception("Recipe not found.");

            if (recipe.FoodId.HasValue)
            {
                var food = await _unitOfWork.Foods.GetByIdAsync(recipe.FoodId.Value);
                if (food != null)
                {
                    var response = new RecipeNutritionResponse
                    {
                        CaloriesKcal = food.CaloriesKcal ?? 0,
                        ProteinG = food.ProteinG ?? 0,
                        CarbsG = food.CarbsG ?? 0,
                        FatG = food.FatG ?? 0,
                        FiberG = food.FiberG ?? 0
                    };
                    await _cache.SetAsync(cacheKey, response, NutritionTtl);
                    return response;
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
                var ratio = NutritionMath.IngredientNutritionRatio(qty, item.Unit ?? ingredient.UnitDefault);
                calories += (ingredient.CaloriesKcal ?? 0) * ratio;
                protein += (ingredient.ProteinG ?? 0) * ratio;
                carbs += (ingredient.CarbsG ?? 0) * ratio;
                fat += (ingredient.FatG ?? 0) * ratio;
            }

            var servings = Math.Max(1, recipe.Servings ?? 1);

            var result = new RecipeNutritionResponse
            {
                CaloriesKcal = calories / servings,
                ProteinG = protein / servings,
                CarbsG = carbs / servings,
                FatG = fat / servings,
                FiberG = fiber
            };

            await _cache.SetAsync(cacheKey, result, NutritionTtl);
            return result;
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

        private async Task<RecipeResponse> EnrichRecipeAsync(
            RecipeResponse dto,
            Guid? userId,
            string? allergyMode,
            List<string>? ingredientNames = null)
        {
            ingredientNames ??= dto.Ingredients.Select(i => i.IngredientName).ToList();
            var risk = await _allergenMatching.EvaluateRecipeRiskAsync(dto.FoodId, ingredientNames, userId);
            dto.MatchedAllergens = risk.MatchedAllergens;
            dto.AllergyRiskLevel = risk.AllergyRiskLevel;
            dto.IsSafeForUser = risk.IsSafeForUser;
            return dto;
        }

        private async Task<Dictionary<Guid, List<string>>> LoadIngredientNamesByRecipeAsync(IEnumerable<Guid> recipeIds)
        {
            var ids = recipeIds.Distinct().ToList();
            var result = ids.ToDictionary(id => id, _ => new List<string>());
            if (ids.Count == 0) return result;

            var rows = await _db.RecipeIngredients.AsNoTracking()
                .Include(ri => ri.Ingredient)
                .Where(ri => ids.Contains(ri.RecipeId))
                .ToListAsync();

            foreach (var row in rows)
            {
                if (result.TryGetValue(row.RecipeId, out var list) && !string.IsNullOrWhiteSpace(row.Ingredient?.NameVi))
                    list.Add(row.Ingredient.NameVi);
            }

            return result;
        }

        private static string NormalizeAllergyMode(string? mode)
        {
            if (string.IsNullOrWhiteSpace(mode)) return AllergenCatalog.ModeWarn;
            var m = mode.Trim().ToLowerInvariant();
            return m is AllergenCatalog.ModeHide or AllergenCatalog.ModeAll or AllergenCatalog.ModeWarn
                ? m
                : AllergenCatalog.ModeWarn;
        }

        private static RecipeResponse Map(Recipe r) => new() { Id = r.Id, FoodId = r.FoodId, Title = r.Title, Description = r.Description, PrepTimeMin = r.PrepTimeMin, CookTimeMin = r.CookTimeMin, TotalTimeMin = r.TotalTimeMin, Servings = r.Servings, Difficulty = r.Difficulty, MealType = r.MealType, EstimatedPriceVnd = r.EstimatedPriceVnd, Instructions = r.Instructions, ImageUrl = r.ImageUrl, VideoUrl = r.VideoUrl, SourceName = r.SourceName, SourceUrl = r.SourceUrl, IsActive = r.IsActive };
    }
}
