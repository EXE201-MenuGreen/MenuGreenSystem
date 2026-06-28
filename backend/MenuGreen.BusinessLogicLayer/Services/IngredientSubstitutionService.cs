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
    public class IngredientSubstitutionService : IIngredientSubstitutionService
    {
        private readonly IUnitOfWork _unitOfWork;

        public IngredientSubstitutionService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // A. Engine gợi ý thay thế
        public async Task<IEnumerable<IngredientSubstituteDetailResponse>> GetSubstitutesAsync(
            Guid userId, Guid ingredientId, string reason, int? maxPrice, bool macroMatch)
        {
            var original = await _unitOfWork.Ingredients.GetByIdAsync(ingredientId);
            if (original == null) throw new Exception("Original ingredient not found.");

            var allIngredients = await _unitOfWork.Ingredients.GetAllAsync();
            var candidates = allIngredients.Where(x => x.Id != ingredientId && 
                x.Category == original.Category && 
                (x.IsActive == true || x.IsActive == null)).ToList();

            // Loại trừ các nguyên liệu dị ứng
            var userAllergies = await _unitOfWork.UserAllergies.FindAsync(ua => ua.UserId == userId);
            var allergyIds = userAllergies.Select(ua => ua.AllergyId).ToList();
            if (allergyIds.Any())
            {
                var foodAllergies = await _unitOfWork.FoodAllergies.FindAsync(fa => allergyIds.Contains(fa.AllergyId));
                var forbiddenFoodIds = foodAllergies.Select(fa => fa.FoodId).ToHashSet();
                // Nếu Candidate liên quan đến Food bị dị ứng, có thể lọc (giản lược: so sánh tên hoặc lọc theo id)
            }

            if (maxPrice.HasValue)
            {
                candidates = candidates.Where(c => c.EstimatedPriceVnd == null || c.EstimatedPriceVnd.Value <= maxPrice.Value).ToList();
            }

            if (reason == "expensive")
            {
                var originalPrice = original.EstimatedPriceVnd ?? 50000;
                candidates = candidates.Where(c => c.EstimatedPriceVnd == null || c.EstimatedPriceVnd.Value < originalPrice).ToList();
            }

            var result = new List<IngredientSubstituteDetailResponse>();

            foreach (var candidate in candidates)
            {
                double score = 0.80; // Baseline similarity
                double ratio = 1.0;

                var origCal = original.CaloriesKcal ?? 100;
                var candCal = candidate.CaloriesKcal ?? 100;
                if (candCal > 0)
                {
                    ratio = (double)origCal / (double)candCal;
                }

                if (macroMatch)
                {
                    var origProtein = original.ProteinG ?? 0;
                    var candProtein = candidate.ProteinG ?? 0;
                    var diff = Math.Abs((double)origProtein - (double)candProtein);
                    if (diff < 5)
                    {
                        score += 0.15;
                    }
                }

                string explanation = $"Cùng nhóm {original.Category}. Giá trị calo tương đương khi quy đổi tỉ lệ {ratio:F2}.";
                if (reason == "expensive")
                {
                    explanation += $" Giúp tiết kiệm chi phí so với {original.NameVi}.";
                }

                result.Add(new IngredientSubstituteDetailResponse
                {
                    Id = candidate.Id,
                    NameVi = candidate.NameVi ?? string.Empty,
                    Category = candidate.Category ?? string.Empty,
                    SimilarityScore = Math.Min(1.0, score),
                    ConversionRatio = ratio,
                    EstimatedPriceVnd = candidate.EstimatedPriceVnd,
                    Explanation = explanation
                });
            }

            return result.OrderByDescending(r => r.SimilarityScore).ThenBy(r => r.EstimatedPriceVnd).ToList();
        }

        public async Task<IEnumerable<IngredientSubstituteDto>> GetBatchSubstitutesAsync(Guid userId, BatchSubstitutionRequest request)
        {
            var result = new List<IngredientSubstituteDto>();

            foreach (var ingId in request.IngredientIds)
            {
                var original = await _unitOfWork.Ingredients.GetByIdAsync(ingId);
                if (original == null) continue;

                var substitutes = await GetSubstitutesAsync(userId, ingId, "not_available", null, false);
                var options = substitutes.Select(s => new SubstituteOptionDto
                {
                    Id = s.Id,
                    NameVi = s.NameVi,
                    Category = s.Category,
                    ConversionRatio = s.ConversionRatio,
                    EstimatedPriceVnd = s.EstimatedPriceVnd,
                    CaloriesKcal = 100 * s.ConversionRatio // Estimated
                }).ToList();

                result.Add(new IngredientSubstituteDto
                {
                    OriginalIngredientId = ingId,
                    OriginalIngredientName = original.NameVi ?? string.Empty,
                    Substitutes = options
                });
            }

            return result;
        }

        public async Task<RecipeIngredientSubstituteResponse> GetRecipeIngredientSubstitutesAsync(
            Guid userId, Guid recipeId, Guid ingredientId)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(recipeId);
            if (recipe == null) throw new Exception("Recipe not found.");

            var original = await _unitOfWork.Ingredients.GetByIdAsync(ingredientId);
            if (original == null) throw new Exception("Original ingredient not found.");

            var recipeIngredients = await _unitOfWork.RecipeIngredients.FindAsync(x => x.RecipeId == recipeId && x.IngredientId == ingredientId);
            var recipeIng = recipeIngredients.FirstOrDefault();

            double originalQty = recipeIng != null ? (double)(recipeIng.Quantity ?? 100) : 100;
            string originalUnit = recipeIng?.Unit ?? "g";

            var substitutes = await GetSubstitutesAsync(userId, ingredientId, "not_available", null, true);

            var options = new List<RecipeSubstituteOptionDto>();
            foreach (var sub in substitutes)
            {
                double suggestedQty = originalQty * sub.ConversionRatio;
                int priceDiff = 0;

                var originalPrice = original.EstimatedPriceVnd ?? 50000;
                var subPrice = sub.EstimatedPriceVnd ?? 50000;
                priceDiff = (int)((subPrice * sub.ConversionRatio) - originalPrice);

                options.Add(new RecipeSubstituteOptionDto
                {
                    IngredientId = sub.Id,
                    IngredientName = sub.NameVi,
                    SuggestedQuantity = suggestedQty,
                    Unit = originalUnit,
                    PriceDifferenceVnd = priceDiff
                });
            }

            return new RecipeIngredientSubstituteResponse
            {
                RecipeId = recipeId,
                OriginalIngredientId = ingredientId,
                OriginalIngredientName = original.NameVi ?? string.Empty,
                OriginalQuantity = originalQty,
                OriginalUnit = originalUnit,
                Options = options
            };
        }

        public async Task<IEnumerable<RecipeResponse>> GetSafeRecipeAlternativesAsync(Guid userId, Guid recipeId)
        {
            var targetRecipe = await _unitOfWork.Recipes.GetByIdAsync(recipeId);
            if (targetRecipe == null) throw new Exception("Recipe not found.");

            // Get safe recipes matching same MealType
            var userAllergies = await _unitOfWork.UserAllergies.FindAsync(ua => ua.UserId == userId);
            var allergyIds = userAllergies.Select(ua => ua.AllergyId).ToList();

            var allRecipes = await _unitOfWork.Recipes.FindAsync(r => 
                r.MealType != null && r.MealType.Contains(targetRecipe.MealType ?? "lunch") &&
                r.Id != recipeId && (r.IsActive == true || r.IsActive == null));

            var safeRecipes = allRecipes.ToList();

            if (allergyIds.Any())
            {
                var foodAllergies = await _unitOfWork.FoodAllergies.FindAsync(fa => allergyIds.Contains(fa.AllergyId));
                var forbiddenFoodIds = foodAllergies.Select(fa => fa.FoodId).ToHashSet();
                safeRecipes = safeRecipes.Where(r => r.FoodId == null || !forbiddenFoodIds.Contains(r.FoodId.Value)).ToList();
            }

            return safeRecipes.Select(MapRecipe).ToList();
        }

        // B. Áp dụng thay thế
        public async Task ApplyMealPlanSubstitutionAsync(
            Guid userId, Guid planId, Guid itemId, IngredientSubstitutionApplyRequest request)
        {
            var mealPlanItem = await _unitOfWork.MealPlanItems.GetByIdAsync(itemId);
            if (mealPlanItem == null || mealPlanItem.MealPlanId != planId)
            {
                throw new Exception("Meal in meal plan not found.");
            }

            var substitution = new MealPlanItemSubstitution
            {
                Id = Guid.NewGuid(),
                MealPlanItemId = itemId,
                OriginalIngredientId = request.OriginalIngredientId,
                SubstituteIngredientId = request.SubstituteIngredientId,
                OriginalQuantity = request.OriginalQuantity,
                SubstituteQuantity = request.SubstituteQuantity,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MealPlanItemSubstitutions.AddAsync(substitution);

            // Cập nhật lại calo mục tiêu (TargetCalories) dựa trên ConversionRatio
            var original = await _unitOfWork.Ingredients.GetByIdAsync(request.OriginalIngredientId);
            var substitute = await _unitOfWork.Ingredients.GetByIdAsync(request.SubstituteIngredientId);

            if (original != null && substitute != null)
            {
                var origCal = (double)(original.CaloriesKcal ?? 100) * (request.OriginalQuantity / 100.0);
                var subCal = (double)(substitute.CaloriesKcal ?? 100) * (request.SubstituteQuantity / 100.0);
                var diff = subCal - origCal;
                
                mealPlanItem.TargetCalories = (int)Math.Max(0, (mealPlanItem.TargetCalories ?? 500) + diff);
                _unitOfWork.MealPlanItems.Update(mealPlanItem);
            }

            await _unitOfWork.CompleteAsync();
        }

        public async Task ApplyMealLogSubstitutionAsync(
            Guid userId, Guid mealLogId, IngredientSubstitutionApplyRequest request)
        {
            var mealLog = await _unitOfWork.MealLogs.GetByIdAsync(mealLogId);
            if (mealLog == null || mealLog.UserId != userId)
            {
                throw new Exception("Food log not found.");
            }

            var substitution = new MealLogSubstitution
            {
                Id = Guid.NewGuid(),
                MealLogId = mealLogId,
                OriginalIngredientId = request.OriginalIngredientId,
                SubstituteIngredientId = request.SubstituteIngredientId,
                OriginalQuantity = request.OriginalQuantity,
                SubstituteQuantity = request.SubstituteQuantity,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MealLogSubstitutions.AddAsync(substitution);

            var original = await _unitOfWork.Ingredients.GetByIdAsync(request.OriginalIngredientId);
            var substitute = await _unitOfWork.Ingredients.GetByIdAsync(request.SubstituteIngredientId);

            if (original != null && substitute != null)
            {
                var origCal = (double)(original.CaloriesKcal ?? 100) * (request.OriginalQuantity / 100.0);
                var subCal = (double)(substitute.CaloriesKcal ?? 100) * (request.SubstituteQuantity / 100.0);
                var diff = subCal - origCal;

                mealLog.CaloriesKcal = (decimal)Math.Max(0, (double)(mealLog.CaloriesKcal ?? 0m) + diff);
                _unitOfWork.MealLogs.Update(mealLog);
            }

            await _unitOfWork.CompleteAsync();
        }

        // C. Cấu hình cá nhân
        public async Task<IEnumerable<UserSubstitutePreferenceResponse>> GetPersonalPreferencesAsync(Guid userId)
        {
            var preferences = await _unitOfWork.UserSubstitutionPreferences.FindAsync(x => x.UserId == userId);
            var response = new List<UserSubstitutePreferenceResponse>();

            foreach (var pref in preferences)
            {
                var orig = await _unitOfWork.Ingredients.GetByIdAsync(pref.OriginalIngredientId);
                var sub = await _unitOfWork.Ingredients.GetByIdAsync(pref.SubstituteIngredientId);

                response.Add(new UserSubstitutePreferenceResponse
                {
                    Id = pref.Id,
                    UserId = pref.UserId,
                    OriginalIngredientId = pref.OriginalIngredientId,
                    OriginalIngredientName = orig?.NameVi ?? string.Empty,
                    SubstituteIngredientId = pref.SubstituteIngredientId,
                    SubstituteIngredientName = sub?.NameVi ?? string.Empty,
                    CreatedAt = pref.CreatedAt
                });
            }

            return response;
        }

        public async Task<UserSubstitutePreferenceResponse> CreatePersonalPreferenceAsync(
            Guid userId, UserSubstitutePreferenceUpsertRequest request)
        {
            var original = await _unitOfWork.Ingredients.GetByIdAsync(request.OriginalIngredientId);
            if (original == null) throw new Exception("Original ingredient not found.");

            var substitute = await _unitOfWork.Ingredients.GetByIdAsync(request.SubstituteIngredientId);
            if (substitute == null) throw new Exception("Substitute ingredient not found.");

            var preference = new UserSubstitutionPreference
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                OriginalIngredientId = request.OriginalIngredientId,
                SubstituteIngredientId = request.SubstituteIngredientId,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.UserSubstitutionPreferences.AddAsync(preference);
            await _unitOfWork.CompleteAsync();

            return new UserSubstitutePreferenceResponse
            {
                Id = preference.Id,
                UserId = preference.UserId,
                OriginalIngredientId = preference.OriginalIngredientId,
                OriginalIngredientName = original.NameVi ?? string.Empty,
                SubstituteIngredientId = preference.SubstituteIngredientId,
                SubstituteIngredientName = substitute.NameVi ?? string.Empty,
                CreatedAt = preference.CreatedAt
            };
        }

        public async Task DeletePersonalPreferenceAsync(Guid userId, Guid id)
        {
            var preference = await _unitOfWork.UserSubstitutionPreferences.GetByIdAsync(id);
            if (preference == null || preference.UserId != userId)
            {
                throw new Exception("Substitution configuration not found.");
            }

            _unitOfWork.UserSubstitutionPreferences.Remove(preference);
            await _unitOfWork.CompleteAsync();
        }

        private static RecipeResponse MapRecipe(Recipe r)
        {
            return new RecipeResponse
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
                IsActive = r.IsActive
            };
        }
    }
}
