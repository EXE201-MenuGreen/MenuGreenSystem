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

            await ReplaceItemsAsync(entity.Id, request.Items);
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

            await ReplaceItemsAsync(entity.Id, request.Items);
            return await GetByIdAsync(userId, id);
        }

        public async Task DeleteAsync(Guid userId, Guid id)
        {
            var entity = await GetOwnedAsync(userId, id);
            var items = await _unitOfWork.MealTemplateItems.FindAsync(x => x.MealTemplateId == entity.Id);
            _unitOfWork.MealTemplateItems.RemoveRange(items);
            _unitOfWork.MealTemplates.Remove(entity);
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
                var nutrition = await CalculateNutritionAsync(item.FoodId, item.RecipeId, item.QuantityG);
                totalCalories += nutrition.CaloriesKcal;
                totalProtein += nutrition.ProteinG;
                totalCarbs += nutrition.CarbsG;
                totalFat += nutrition.FatG;

                var created = await _nutritionTrackingService.CreateMealLogAsync(userId, new MealLogUpsertRequest
                {
                    FoodId = item.FoodId,
                    RecipeId = item.RecipeId,
                    MealType = mealType,
                    QuantityG = item.QuantityG,
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
                    QuantityG = item.QuantityG,
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
                if (!item.FoodId.HasValue && !item.RecipeId.HasValue)
                {
                    throw new Exception("Each template item must have either FoodId or RecipeId.");
                }
            }
        }

        private async Task ReplaceItemsAsync(Guid mealTemplateId, IEnumerable<MealTemplateItemUpsertRequest> items)
        {
            foreach (var item in items.OrderBy(x => x.SortOrder))
            {
                await _unitOfWork.MealTemplateItems.AddAsync(new MealTemplateItem
                {
                    Id = Guid.NewGuid(),
                    MealTemplateId = mealTemplateId,
                    FoodId = item.FoodId,
                    RecipeId = item.RecipeId,
                    QuantityG = item.QuantityG,
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
                var nutrition = await CalculateNutritionAsync(item.FoodId, item.RecipeId, item.QuantityG);
                result.Add(new MealTemplateItemResponse
                {
                    Id = item.Id,
                    MealTemplateId = item.MealTemplateId,
                    FoodId = item.FoodId,
                    RecipeId = item.RecipeId,
                    QuantityG = item.QuantityG,
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

        private async Task<(decimal CaloriesKcal, decimal ProteinG, decimal CarbsG, decimal FatG)> CalculateNutritionAsync(Guid? foodId, Guid? recipeId, decimal quantityG)
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

            return (0, 0, 0, 0);
        }

        private static (decimal CaloriesKcal, decimal ProteinG, decimal CarbsG, decimal FatG) ScaleNutrition(decimal? calories, decimal? protein, decimal? carbs, decimal? fat, int? defaultServingG, decimal quantityG)
        {
            var baseServing = defaultServingG.GetValueOrDefault(100);
            var ratio = baseServing <= 0 ? 1m : quantityG / baseServing;
            return (
                Math.Round((calories ?? 0) * ratio, 2),
                Math.Round((protein ?? 0) * ratio, 2),
                Math.Round((carbs ?? 0) * ratio, 2),
                Math.Round((fat ?? 0) * ratio, 2)
            );
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
