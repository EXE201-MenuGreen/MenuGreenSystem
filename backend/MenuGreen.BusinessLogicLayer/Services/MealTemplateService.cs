using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Helpers;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class MealTemplateService : IMealTemplateService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INutritionTrackingService _nutritionTrackingService;

        public MealTemplateService(IUnitOfWork unitOfWork, INutritionTrackingService nutritionTrackingService)
        {
            _unitOfWork = unitOfWork;
            _nutritionTrackingService = nutritionTrackingService;
        }

        public async Task<IEnumerable<MealTemplateResponse>> GetAllAsync(Guid userId)
        {
            var templates = await _unitOfWork.MealTemplates.FindAsync(x => x.UserId == userId);
            var list = templates.OrderByDescending(x => x.UpdatedAt).ToList();
            return list.Select(entity => Map(entity)).ToList();
        }

        public async Task<MealTemplateResponse> GetByIdAsync(Guid userId, Guid id)
        {
            var entity = await GetOwnedAsync(userId, id);
            return Map(entity, await LoadTemplateItemsAsync(entity.Id));
        }

        public async Task<MealTemplateResponse> CreateAsync(Guid userId, MealTemplateUpsertRequest request)
        {
            ValidateRequest(request);

            var entity = new MealTemplate
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = request.Title,
                Description = request.Description,
                MealType = request.MealType,
                IsActive = request.IsActive ?? true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MealTemplates.AddAsync(entity);
            await _unitOfWork.CompleteAsync();

            await ReplaceItemsAsync(entity.Id, request.Items, request.MealType);
            return await GetByIdAsync(userId, entity.Id);
        }

        public async Task<MealTemplateResponse> UpdateAsync(Guid userId, Guid id, MealTemplateUpsertRequest request)
        {
            ValidateRequest(request);
            var entity = await GetOwnedAsync(userId, id);

            entity.Title = request.Title;
            entity.Description = request.Description;
            entity.MealType = request.MealType;
            entity.IsActive = request.IsActive ?? entity.IsActive;
            entity.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.MealTemplates.Update(entity);
            await _unitOfWork.CompleteAsync();

            var existingItems = await _unitOfWork.MealTemplateItems.FindAsync(x => x.MealTemplateId == entity.Id);
            _unitOfWork.MealTemplateItems.RemoveRange(existingItems);
            await _unitOfWork.CompleteAsync();

            await ReplaceItemsAsync(entity.Id, request.Items, request.MealType);
            return await GetByIdAsync(userId, id);
        }

        public async Task DeleteAsync(Guid userId, Guid id)
        {
            var entity = await GetOwnedAsync(userId, id);
            entity.IsActive = false;
            _unitOfWork.MealTemplates.Update(entity);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<MealTemplateLogResponse> LogAsync(Guid userId, Guid id, MealTemplateLogRequest request)
        {
            var template = await GetOwnedAsync(userId, id);
            var items = await LoadTemplateItemsAsync(template.Id);
            if (items.Count == 0) throw new Exception("Meal template has no items.");

            var loggedAt = request.LoggedAt ?? DateTime.UtcNow;
            var mealType = request.MealType ?? template.MealType ?? "SNACK";
            var createdLogs = new List<MealLogResponse>();
            decimal totalCalories = 0;
            decimal totalProtein = 0;
            decimal totalCarbs = 0;
            decimal totalFat = 0;

            foreach (var item in items.OrderBy(x => x.SortOrder))
            {
                var nutrition = (
                    item.CaloriesKcal,
                    item.ProteinG,
                    item.CarbsG,
                    item.FatG);
                totalCalories += nutrition.CaloriesKcal;
                totalProtein += nutrition.ProteinG;
                totalCarbs += nutrition.CarbsG;
                totalFat += nutrition.FatG;

                var created = await _nutritionTrackingService.CreateMealLogAsync(userId, new MealLogUpsertRequest
                {
                    FoodId = item.FoodId,
                    RecipeId = item.RecipeId,
                    CustomName = item.CustomName,
                    SourceType = item.SourceType,
                    MealType = NormalizeMealType(item.MealType, mealType),
                    QuantityG = item.QuantityG,
                    CaloriesKcal = nutrition.CaloriesKcal,
                    ProteinG = nutrition.ProteinG,
                    CarbsG = nutrition.CarbsG,
                    FatG = nutrition.FatG,
                    Notes = item.Notes,
                    LoggedAt = loggedAt
                });

                createdLogs.Add(created);
            }

            template.UsageCount += 1;
            template.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.MealTemplates.Update(template);
            await _unitOfWork.CompleteAsync();

            return new MealTemplateLogResponse
            {
                MealTemplateId = template.Id,
                Title = template.Title,
                MealType = mealType,
                LoggedAt = loggedAt,
                CreatedMealLogsCount = createdLogs.Count,
                TotalCaloriesKcal = totalCalories,
                TotalProteinG = totalProtein,
                TotalCarbsG = totalCarbs,
                TotalFatG = totalFat,
                MealLogs = createdLogs
            };
        }

        public async Task<MealTemplateResponse> DuplicateAsync(Guid userId, Guid id)
        {
            var source = await GetOwnedAsync(userId, id);
            var items = await LoadTemplateItemsAsync(source.Id);

            var clone = new MealTemplate
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = source.Title + " (Copy)",
                Description = source.Description,
                MealType = source.MealType,
                UsageCount = 0,
                IsActive = source.IsActive,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MealTemplates.AddAsync(clone);
            await _unitOfWork.CompleteAsync();

            foreach (var item in items)
            {
                await _unitOfWork.MealTemplateItems.AddAsync(new MealTemplateItem
                {
                    Id = Guid.NewGuid(),
                    MealTemplateId = clone.Id,
                    FoodId = item.FoodId,
                    RecipeId = item.RecipeId,
                    CustomName = item.CustomName,
                    SourceType = item.SourceType,
                    MealType = item.MealType,
                    QuantityG = item.QuantityG,
                    CaloriesKcal = item.CaloriesKcal,
                    ProteinG = item.ProteinG,
                    CarbsG = item.CarbsG,
                    FatG = item.FatG,
                    IngredientSnapshotJson = JsonSerializer.Serialize(item.Ingredients),
                    Notes = item.Notes,
                    SortOrder = item.SortOrder,
                    CreatedAt = DateTime.UtcNow
                });
            }

            await _unitOfWork.CompleteAsync();
            return await GetByIdAsync(userId, clone.Id);
        }

        public async Task<int> GetUsageAsync(Guid userId, Guid id)
        {
            var entity = await GetOwnedAsync(userId, id);
            return entity.UsageCount;
        }

        private static void ValidateRequest(MealTemplateUpsertRequest request)
        {
            if (request.Items == null || request.Items.Count == 0)
            {
                throw new Exception("Meal template must contain at least one item.");
            }

            foreach (var item in request.Items)
            {
                var hasCatalogReference = item.FoodId.HasValue || item.RecipeId.HasValue;
                var isAiScan = string.Equals(
                        item.SourceType,
                        "AiScan",
                        StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(
                        item.SourceType,
                        "AiIngredientScan",
                        StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(
                        item.SourceType,
                        "AiDishScan",
                        StringComparison.OrdinalIgnoreCase);
                var hasAiSnapshot = isAiScan &&
                    !string.IsNullOrWhiteSpace(item.CustomName) &&
                    item.CaloriesKcal.HasValue;

                if (!hasCatalogReference && !hasAiSnapshot)
                {
                    throw new Exception(
                        "Each template item must reference Food/Recipe or contain an AI scan snapshot.");
                }
            }
        }

        private async Task ReplaceItemsAsync(
            Guid mealTemplateId,
            IEnumerable<MealTemplateItemUpsertRequest> items,
            string? templateMealType)
        {
            foreach (var item in items.OrderBy(x => x.SortOrder))
            {
                await _unitOfWork.MealTemplateItems.AddAsync(new MealTemplateItem
                {
                    Id = Guid.NewGuid(),
                    MealTemplateId = mealTemplateId,
                    FoodId = item.FoodId,
                    RecipeId = item.RecipeId,
                    CustomName = item.CustomName?.Trim(),
                    SourceType = item.SourceType,
                    MealType = NormalizeMealType(item.MealType, templateMealType),
                    QuantityG = item.QuantityG,
                    CaloriesKcal = item.CaloriesKcal,
                    ProteinG = item.ProteinG,
                    CarbsG = item.CarbsG,
                    FatG = item.FatG,
                    IngredientSnapshotJson = JsonSerializer.Serialize(item.Ingredients),
                    Notes = item.Notes,
                    SortOrder = item.SortOrder,
                    CreatedAt = DateTime.UtcNow
                });
            }

            await _unitOfWork.CompleteAsync();
        }

        private async Task<MealTemplate> GetOwnedAsync(Guid userId, Guid id)
        {
            var entity = await _unitOfWork.MealTemplates.GetByIdAsync(id);
            if (entity == null) throw new Exception("Meal template not found.");
            if (entity.UserId != userId) throw new Exception("Forbidden.");
            return entity;
        }

        private async Task<List<MealTemplateItemResponse>> LoadTemplateItemsAsync(Guid templateId)
        {
            var items = await _unitOfWork.MealTemplateItems.FindAsync(x => x.MealTemplateId == templateId);
            var result = new List<MealTemplateItemResponse>();

            foreach (var item in items.OrderBy(x => x.SortOrder))
            {
                var nutrition = await CalculateNutritionAsync(
                    item.FoodId,
                    item.RecipeId,
                    item.QuantityG,
                    item.CaloriesKcal,
                    item.ProteinG,
                    item.CarbsG,
                    item.FatG);
                var name = await ResolveItemNameAsync(item);
                result.Add(new MealTemplateItemResponse
                {
                    Id = item.Id,
                    MealTemplateId = item.MealTemplateId,
                    FoodId = item.FoodId,
                    RecipeId = item.RecipeId,
                    CustomName = item.CustomName,
                    SourceType = item.SourceType,
                    Name = name,
                    MealType = NormalizeMealType(item.MealType),
                    QuantityG = item.QuantityG,
                    Ingredients = DeserializeIngredients(item.IngredientSnapshotJson),
                    Notes = item.Notes,
                    SortOrder = item.SortOrder,
                    CaloriesKcal = nutrition.CaloriesKcal,
                    ProteinG = nutrition.ProteinG,
                    CarbsG = nutrition.CarbsG,
                    FatG = nutrition.FatG
                });
            }

            return result;
        }

        private async Task<string?> ResolveItemNameAsync(MealTemplateItem item)
        {
            if (item.FoodId.HasValue)
            {
                var food = await _unitOfWork.Foods.GetByIdAsync(item.FoodId.Value);
                return food?.NameVi;
            }

            if (item.RecipeId.HasValue)
            {
                var recipe = await _unitOfWork.Recipes.GetByIdAsync(item.RecipeId.Value);
                return recipe?.Title;
            }

            return item.CustomName;
        }

        private static string NormalizeMealType(string? value, string? fallback = null)
        {
            foreach (var candidate in new[] { value, fallback })
            {
                if (string.Equals(candidate, "Breakfast", StringComparison.OrdinalIgnoreCase)) return "Breakfast";
                if (string.Equals(candidate, "Lunch", StringComparison.OrdinalIgnoreCase)) return "Lunch";
                if (string.Equals(candidate, "Dinner", StringComparison.OrdinalIgnoreCase)) return "Dinner";
                if (string.Equals(candidate, "Snack", StringComparison.OrdinalIgnoreCase)) return "Snack";
            }

            return "Snack";
        }

        private async Task<(decimal CaloriesKcal, decimal ProteinG, decimal CarbsG, decimal FatG)> CalculateNutritionAsync(
            Guid? foodId,
            Guid? recipeId,
            decimal quantityG,
            decimal? customCalories = null,
            decimal? customProtein = null,
            decimal? customCarbs = null,
            decimal? customFat = null)
        {
            if (foodId.HasValue)
            {
                var food = await _unitOfWork.Foods.GetByIdAsync(foodId.Value) ?? throw new Exception("Food not found.");
                return ScaleNutrition(food.CaloriesKcal, food.ProteinG, food.CarbsG, food.FatG, food.DefaultServingG, quantityG);
            }

            if (recipeId.HasValue)
            {
                var recipe = await _unitOfWork.Recipes.GetByIdAsync(recipeId.Value) ?? throw new Exception("Recipe not found.");
                var food = recipe.FoodId.HasValue ? await _unitOfWork.Foods.GetByIdAsync(recipe.FoodId.Value) : null;
                if (food != null)
                {
                    return ScaleNutrition(food.CaloriesKcal, food.ProteinG, food.CarbsG, food.FatG, food.DefaultServingG, quantityG);
                }

                var ingredients = await _unitOfWork.RecipeIngredients.FindAsync(x => x.RecipeId == recipe.Id);
                var ingredientCount = ingredients.Count();
                var estimatedCalories = ingredientCount * 50m;
                var estimatedProtein = ingredientCount * 2m;
                var estimatedCarbs = ingredientCount * 5m;
                var estimatedFat = ingredientCount * 1m;
                return ScaleNutrition(estimatedCalories, estimatedProtein, estimatedCarbs, estimatedFat, 100, quantityG);
            }

            return (
                customCalories ?? 0,
                customProtein ?? 0,
                customCarbs ?? 0,
                customFat ?? 0);
        }

        private static List<OfficeScanIngredientRequest> DeserializeIngredients(string? json)
        {
            if (string.IsNullOrWhiteSpace(json)) return new();
            try
            {
                return JsonSerializer.Deserialize<List<OfficeScanIngredientRequest>>(json) ?? new();
            }
            catch (JsonException)
            {
                return new();
            }
        }

        private static (decimal CaloriesKcal, decimal ProteinG, decimal CarbsG, decimal FatG) ScaleNutrition(decimal? calories, decimal? protein, decimal? carbs, decimal? fat, int? defaultServingG, decimal quantityG)
        {
            var ratio = NutritionMath.ServingNutritionRatio(
                quantityG,
                defaultServingG);
            return (
                Math.Round((calories ?? 0) * ratio, 2),
                Math.Round((protein ?? 0) * ratio, 2),
                Math.Round((carbs ?? 0) * ratio, 2),
                Math.Round((fat ?? 0) * ratio, 2)
            );
        }

        public async Task<MealTemplateResponse> CreateFromLogAsync(Guid userId, Guid mealLogId, string title)
        {
            var mealLog = await _unitOfWork.MealLogs.GetByIdAsync(mealLogId);
            if (mealLog == null) throw new Exception("Meal log not found.");
            if (mealLog.UserId != userId) throw new Exception("Forbidden.");

            var template = new MealTemplate
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = title,
                Description = $"Created from meal log on {mealLog.LoggedAt:yyyy-MM-dd}",
                MealType = mealLog.MealType ?? "SNACK",
                UsageCount = 0,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MealTemplates.AddAsync(template);
            await _unitOfWork.CompleteAsync();

            var templateItem = new MealTemplateItem
            {
                Id = Guid.NewGuid(),
                MealTemplateId = template.Id,
                FoodId = mealLog.FoodId,
                RecipeId = mealLog.RecipeId,
                CustomName = mealLog.CustomName,
                SourceType = mealLog.SourceType,
                MealType = NormalizeMealType(mealLog.MealType),
                QuantityG = mealLog.QuantityG ?? 100,
                CaloriesKcal = mealLog.CaloriesKcal,
                ProteinG = mealLog.ProteinG,
                CarbsG = mealLog.CarbsG,
                FatG = mealLog.FatG,
                Notes = mealLog.Notes,
                SortOrder = 1,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MealTemplateItems.AddAsync(templateItem);
            await _unitOfWork.CompleteAsync();

            return await GetByIdAsync(userId, template.Id);
        }

        private MealTemplateResponse Map(MealTemplate entity, List<MealTemplateItemResponse>? items = null)
        {
            return new MealTemplateResponse
            {
                Id = entity.Id,
                UserId = entity.UserId,
                Title = entity.Title,
                Description = entity.Description,
                MealType = entity.MealType,
                UsageCount = entity.UsageCount,
                IsActive = entity.IsActive,
                CreatedAt = entity.CreatedAt,
                UpdatedAt = entity.UpdatedAt,
                Items = items ?? new List<MealTemplateItemResponse>()
            };
        }
    }
}
