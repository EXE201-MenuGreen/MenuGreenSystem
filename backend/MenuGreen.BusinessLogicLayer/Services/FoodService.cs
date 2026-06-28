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
        private readonly IAllergenMatchingService _allergenMatching;

        public FoodService(
            IUnitOfWork unitOfWork,
            ApplicationDbContext db,
            IAllergenMatchingService allergenMatching)
        {
            _unitOfWork = unitOfWork;
            _db = db;
            _allergenMatching = allergenMatching;
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
            food.IsActive = false;
            _unitOfWork.Foods.Update(food);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<FoodResponse> GetByIdAsync(Guid id, Guid? userId = null, string? allergyMode = null)
        {
            var food = await _unitOfWork.Foods.GetByIdAsync(id) ?? throw new Exception("Food not found.");
            if (food.IsActive == false) throw new Exception("Food not found.");
            var mode = NormalizeAllergyMode(allergyMode);
            var userKeys = userId.HasValue
                ? await _allergenMatching.GetUserAllergenKeysAsync(userId.Value)
                : new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var foodKeysMap = await _allergenMatching.GetFoodAllergenKeysAsync(new[] { id });
            foodKeysMap.TryGetValue(id, out var foodKeys);
            foodKeys ??= new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            return EnrichWithAllergy(Map(food), foodKeys, userKeys);
        }

        public async Task<FoodSearchResponse> SearchAsync(
            string? keyword,
            decimal? minCalories,
            decimal? maxCalories,
            string? proteinLevel,
            int? maxPriceVnd,
            int? maxPrepTimeMin,
            string? category,
            Guid? userId = null,
            string? allergyMode = null,
            string? region = null,
            bool? localOnly = null,
            string? mealContext = null,
            string? sort = null)
        {
            var mode = NormalizeAllergyMode(allergyMode);
            var foods = (await _unitOfWork.Foods.GetAllAsync()).Where(f => f.IsActive != false);

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                foods = foods.Where(f =>
                    f.NameVi.Contains(keyword, StringComparison.OrdinalIgnoreCase) ||
                    (f.NameEn ?? string.Empty).Contains(keyword, StringComparison.OrdinalIgnoreCase));
            }

            if (minCalories.HasValue) foods = foods.Where(f => (f.CaloriesKcal ?? 0) >= minCalories.Value);
            if (maxCalories.HasValue) foods = foods.Where(f => (f.CaloriesKcal ?? 0) <= maxCalories.Value);
            if (!string.IsNullOrWhiteSpace(category))
                foods = foods.Where(f => string.Equals(f.Category, category, StringComparison.OrdinalIgnoreCase));
            if (maxPriceVnd.HasValue) foods = foods.Where(f => (f.EstimatedPriceVnd ?? int.MaxValue) <= maxPriceVnd.Value);
            if (!string.IsNullOrWhiteSpace(proteinLevel))
            {
                foods = proteinLevel.Equals("high", StringComparison.OrdinalIgnoreCase)
                    ? foods.Where(f => (f.ProteinG ?? 0) >= 20)
                    : foods.Where(f => (f.ProteinG ?? 0) < 20);
            }

            if (localOnly == true)
            {
                foods = foods.Where(IsVietnameseFriendlyFood);
            }

            foods = ApplyRegionPreference(foods, region);

            var foodList = foods.ToList();
            var userKeys = userId.HasValue
                ? await _allergenMatching.GetUserAllergenKeysAsync(userId.Value)
                : new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var foodKeysMap = await _allergenMatching.GetFoodAllergenKeysAsync(foodList.Select(f => f.Id));

            var items = new List<FoodResponse>();
            foreach (var food in foodList)
            {
                foodKeysMap.TryGetValue(food.Id, out var foodKeys);
                foodKeys ??= new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                var dto = EnrichWithAllergy(Map(food), foodKeys, userKeys);

                if (mode == AllergenCatalog.ModeHide && !dto.IsSafeForUser)
                    continue;

                items.Add(dto);
            }

            if (ShouldSortLocalFriendly(sort, region, localOnly, mealContext))
            {
                items = items
                    .OrderByDescending(x => GetLocalFriendlyScore(x.NameVi, x.Category, x.Description, region, mealContext))
                    .ThenBy(x => x.EstimatedPriceVnd ?? int.MaxValue)
                    .ThenBy(x => x.NameVi)
                    .ToList();
            }

            return new FoodSearchResponse { TotalCount = items.Count, Items = items };
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

        private static FoodResponse Map(Food f) => new()
        {
            Id = f.Id,
            NameVi = f.NameVi,
            NameEn = f.NameEn,
            Category = f.Category,
            Description = f.Description,
            CaloriesKcal = f.CaloriesKcal,
            ProteinG = f.ProteinG,
            CarbsG = f.CarbsG,
            FatG = f.FatG,
            FiberG = f.FiberG,
            EstimatedPriceVnd = f.EstimatedPriceVnd,
            DefaultServingG = f.DefaultServingG,
            ImageUrl = f.ImageUrl,
            IsActive = f.IsActive
        };

        private static FoodResponse EnrichWithAllergy(
            FoodResponse dto,
            HashSet<string> foodKeys,
            HashSet<string> userKeys)
        {
            dto.AllergenKeys = foodKeys.OrderBy(k => k).ToList();
            dto.AllergenLabelsVi = AllergenCatalog.ToDisplayNamesVi(dto.AllergenKeys).ToList();

            var matchedKeys = foodKeys.Where(userKeys.Contains).ToList();
            dto.MatchedAllergens = AllergenCatalog.ToDisplayNamesVi(matchedKeys).ToList();
            dto.AllergyRiskLevel = matchedKeys.Count > 0
                ? AllergenCatalog.RiskHigh
                : AllergenCatalog.RiskNone;
            dto.IsSafeForUser = AllergenCatalog.IsSafeForUser(dto.AllergyRiskLevel);
            return dto;
        }

        private static string NormalizeAllergyMode(string? mode)
        {
            if (string.IsNullOrWhiteSpace(mode)) return AllergenCatalog.ModeWarn;
            var m = mode.Trim().ToLowerInvariant();
            return m is AllergenCatalog.ModeHide or AllergenCatalog.ModeAll or AllergenCatalog.ModeWarn
                ? m
                : AllergenCatalog.ModeWarn;
        }

        private static IEnumerable<Food> ApplyRegionPreference(IEnumerable<Food> foods, string? region)
        {
            if (string.IsNullOrWhiteSpace(region))
            {
                return foods;
            }

            var list = foods.ToList();
            var matched = list.Where(f => IsRegionMatch(f.NameVi, f.Category, f.Description, region)).ToList();
            return matched.Count > 0 ? matched : list;
        }

        private static bool ShouldSortLocalFriendly(string? sort, string? region, bool? localOnly, string? mealContext)
        {
            return localOnly == true ||
                   !string.IsNullOrWhiteSpace(region) ||
                   !string.IsNullOrWhiteSpace(mealContext) ||
                   string.Equals(sort, "local-friendly", StringComparison.OrdinalIgnoreCase);
        }

        private static bool IsVietnameseFriendlyFood(Food food)
        {
            return GetLocalFriendlyScore(food.NameVi, food.Category, food.Description, null, null) > 0;
        }

        private static bool IsRegionMatch(string? name, string? category, string? description, string? region)
        {
            var terms = GetRegionTerms(region);
            return terms.Length > 0 && ContainsAny(JoinText(name, category, description), terms);
        }

        private static int GetLocalFriendlyScore(string? name, string? category, string? description, string? region, string? mealContext)
        {
            var text = JoinText(name, category, description);
            var score = 0;

            if (ContainsAny(text, "com", "cơm", "pho", "phở", "bun", "bún", "mien", "miến", "xoi", "xôi", "banh", "bánh", "goi", "gỏi", "hu tieu", "hủ tiếu"))
            {
                score += 20;
            }

            if (!string.IsNullOrWhiteSpace(region) && ContainsAny(text, GetRegionTerms(region)))
            {
                score += 30;
            }

            if (!string.IsNullOrWhiteSpace(mealContext))
            {
                var normalized = mealContext.Trim().ToLowerInvariant();
                if ((normalized.Contains("home") || normalized.Contains("nau") || normalized.Contains("nấu")) &&
                    ContainsAny(text, "canh", "kho", "luoc", "luộc", "xao", "xào", "rau", "thit", "thịt", "ca ", "cá "))
                {
                    score += 10;
                }
                else if ((normalized.Contains("out") || normalized.Contains("ngoai") || normalized.Contains("ngoài")) &&
                         ContainsAny(text, "pho", "phở", "bun", "bún", "com tam", "cơm tấm", "banh mi", "bánh mì", "hu tieu", "hủ tiếu"))
                {
                    score += 10;
                }
            }

            return score;
        }

        private static string[] GetRegionTerms(string? region)
        {
            var normalized = region?.Trim().ToLowerInvariant();
            return normalized switch
            {
                "north" or "bac" or "bắc" => new[] { "phở", "pho", "bún chả", "bun cha", "bún thang", "bun thang", "chả cá", "cha ca", "cốm", "com dep", "miến", "mien", "xôi", "xoi" },
                "central" or "trung" or "miền trung" => new[] { "bún bò", "bun bo", "mì quảng", "mi quang", "cao lầu", "cao lau", "cơm hến", "com hen", "bánh bèo", "banh beo", "bánh xèo", "banh xeo" },
                "south" or "nam" or "miền nam" => new[] { "cơm tấm", "com tam", "hủ tiếu", "hu tieu", "bánh mì", "banh mi", "gỏi cuốn", "goi cuon", "bún mắm", "bun mam", "cá kho", "ca kho" },
                _ => Array.Empty<string>()
            };
        }

        private static string JoinText(params string?[] values)
        {
            return string.Join(' ', values.Where(x => !string.IsNullOrWhiteSpace(x))).ToLowerInvariant();
        }

        private static bool ContainsAny(string text, params string[] terms)
        {
            return terms.Any(term => text.Contains(term, StringComparison.OrdinalIgnoreCase));
        }
    }
}
