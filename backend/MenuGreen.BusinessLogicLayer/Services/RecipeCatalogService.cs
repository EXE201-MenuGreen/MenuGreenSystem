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
    public class RecipeCatalogService : IRecipeCatalogService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ApplicationDbContext _db;

        public RecipeCatalogService(IUnitOfWork unitOfWork, ApplicationDbContext db)
        {
            _unitOfWork = unitOfWork;
            _db = db;
        }

        public async Task<RecipeResponse> CreateAsync(RecipeUpsertRequest request)
        {
            var recipe = new Recipe { Id = Guid.NewGuid(), FoodId = request.FoodId, Title = request.Title, Description = request.Description, PrepTimeMin = request.PrepTimeMin, CookTimeMin = request.CookTimeMin, TotalTimeMin = request.TotalTimeMin ?? ((request.PrepTimeMin ?? 0) + (request.CookTimeMin ?? 0)), Servings = request.Servings, Difficulty = request.Difficulty, MealType = request.MealType, EstimatedPriceVnd = request.EstimatedPriceVnd, Instructions = request.Instructions, ImageUrl = request.ImageUrl, VideoUrl = request.VideoUrl, IsActive = request.IsActive ?? true, CreatedAt = DateTime.UtcNow };
            await _unitOfWork.Recipes.AddAsync(recipe); await _unitOfWork.CompleteAsync();
            await UpsertIngredients(recipe.Id, request.Ingredients);
            return await GetByIdAsync(recipe.Id);
        }

        public async Task<RecipeResponse> UpdateAsync(Guid id, RecipeUpsertRequest request)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id) ?? throw new Exception("Recipe not found.");
            recipe.FoodId = request.FoodId; recipe.Title = request.Title; recipe.Description = request.Description; recipe.PrepTimeMin = request.PrepTimeMin; recipe.CookTimeMin = request.CookTimeMin; recipe.TotalTimeMin = request.TotalTimeMin ?? ((request.PrepTimeMin ?? 0) + (request.CookTimeMin ?? 0)); recipe.Servings = request.Servings; recipe.Difficulty = request.Difficulty; recipe.MealType = request.MealType; recipe.EstimatedPriceVnd = request.EstimatedPriceVnd; recipe.Instructions = request.Instructions; recipe.ImageUrl = request.ImageUrl; recipe.VideoUrl = request.VideoUrl; recipe.IsActive = request.IsActive ?? recipe.IsActive;
            _unitOfWork.Recipes.Update(recipe); await _unitOfWork.CompleteAsync();
            var existing = await _unitOfWork.RecipeIngredients.FindAsync(x => x.RecipeId == id); _unitOfWork.RecipeIngredients.RemoveRange(existing); await _unitOfWork.CompleteAsync();
            await UpsertIngredients(id, request.Ingredients);
            return await GetByIdAsync(id);
        }

        public async Task DeleteAsync(Guid id) { var recipe = await _unitOfWork.Recipes.GetByIdAsync(id) ?? throw new Exception("Recipe not found."); recipe.IsActive = false; _unitOfWork.Recipes.Update(recipe); await _unitOfWork.CompleteAsync(); }

        public async Task<RecipeResponse> GetByIdAsync(Guid id)
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

        private static RecipeResponse Map(Recipe r) => new() { Id = r.Id, FoodId = r.FoodId, Title = r.Title, Description = r.Description, PrepTimeMin = r.PrepTimeMin, CookTimeMin = r.CookTimeMin, TotalTimeMin = r.TotalTimeMin, Servings = r.Servings, Difficulty = r.Difficulty, MealType = r.MealType, EstimatedPriceVnd = r.EstimatedPriceVnd, Instructions = r.Instructions, ImageUrl = r.ImageUrl, VideoUrl = r.VideoUrl, IsActive = r.IsActive };
    }
}
