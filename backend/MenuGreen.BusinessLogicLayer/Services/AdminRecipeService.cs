using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class AdminRecipeService : IAdminRecipeService
    {
        private readonly IUnitOfWork _unitOfWork;

        public AdminRecipeService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<RecipeResponse> CreateAsync(RecipeUpsertRequest request)
        {
            var recipe = new Recipe
            {
                Id = Guid.NewGuid(),
                FoodId = request.FoodId,
                Title = request.Title,
                Description = request.Description,
                PrepTimeMin = request.PrepTimeMin,
                CookTimeMin = request.CookTimeMin,
                TotalTimeMin = request.TotalTimeMin ?? ((request.PrepTimeMin ?? 0) + (request.CookTimeMin ?? 0)),
                Servings = request.Servings,
                Difficulty = request.Difficulty,
                MealType = request.MealType,
                EstimatedPriceVnd = request.EstimatedPriceVnd,
                Instructions = request.Instructions,
                ImageUrl = request.ImageUrl,
                VideoUrl = request.VideoUrl,
                IsActive = request.IsActive ?? true,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Recipes.AddAsync(recipe);
            await _unitOfWork.CompleteAsync();
            return Map(recipe);
        }

        public async Task<RecipeResponse> UpdateAsync(Guid id, RecipeUpsertRequest request)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id) ?? throw new Exception("Recipe not found.");
            recipe.FoodId = request.FoodId;
            recipe.Title = request.Title;
            recipe.Description = request.Description;
            recipe.PrepTimeMin = request.PrepTimeMin;
            recipe.CookTimeMin = request.CookTimeMin;
            recipe.TotalTimeMin = request.TotalTimeMin ?? ((request.PrepTimeMin ?? 0) + (request.CookTimeMin ?? 0));
            recipe.Servings = request.Servings;
            recipe.Difficulty = request.Difficulty;
            recipe.MealType = request.MealType;
            recipe.EstimatedPriceVnd = request.EstimatedPriceVnd;
            recipe.Instructions = request.Instructions;
            recipe.ImageUrl = request.ImageUrl;
            recipe.VideoUrl = request.VideoUrl;
            recipe.IsActive = request.IsActive ?? recipe.IsActive;
            _unitOfWork.Recipes.Update(recipe);
            await _unitOfWork.CompleteAsync();
            return Map(recipe);
        }

        public async Task DeleteAsync(Guid id)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id) ?? throw new Exception("Recipe not found.");
            _unitOfWork.Recipes.Remove(recipe);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<RecipeResponse> GetByIdAsync(Guid id)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id) ?? throw new Exception("Recipe not found.");
            return Map(recipe);
        }

        private static RecipeResponse Map(Recipe r) => new() { Id = r.Id, FoodId = r.FoodId, Title = r.Title, Description = r.Description, PrepTimeMin = r.PrepTimeMin, CookTimeMin = r.CookTimeMin, TotalTimeMin = r.TotalTimeMin, Servings = r.Servings, Difficulty = r.Difficulty, MealType = r.MealType, EstimatedPriceVnd = r.EstimatedPriceVnd, Instructions = r.Instructions, ImageUrl = r.ImageUrl, VideoUrl = r.VideoUrl, IsActive = r.IsActive };
    }
}
