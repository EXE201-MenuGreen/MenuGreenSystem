using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class AdminIngredientService : IAdminIngredientService
    {
        private readonly IUnitOfWork _unitOfWork;

        public AdminIngredientService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<IngredientResponse> CreateAsync(IngredientUpsertRequest request)
        {
            var ingredient = new Ingredient
            {
                Id = Guid.NewGuid(),
                NameVi = request.NameVi,
                NameEn = request.NameEn,
                Category = request.Category,
                CaloriesKcal = request.CaloriesKcal,
                ProteinG = request.ProteinG,
                CarbsG = request.CarbsG,
                FatG = request.FatG,
                EstimatedPriceVnd = request.EstimatedPriceVnd,
                UnitDefault = request.UnitDefault,
                ImageUrl = request.ImageUrl,
                IsActive = request.IsActive ?? true,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Ingredients.AddAsync(ingredient);
            await _unitOfWork.CompleteAsync();
            return Map(ingredient);
        }

        public async Task<IngredientResponse> UpdateAsync(Guid id, IngredientUpsertRequest request)
        {
            var ingredient = await _unitOfWork.Ingredients.GetByIdAsync(id) ?? throw new Exception("Ingredient not found.");
            ingredient.NameVi = request.NameVi;
            ingredient.NameEn = request.NameEn;
            ingredient.Category = request.Category;
            ingredient.CaloriesKcal = request.CaloriesKcal;
            ingredient.ProteinG = request.ProteinG;
            ingredient.CarbsG = request.CarbsG;
            ingredient.FatG = request.FatG;
            ingredient.EstimatedPriceVnd = request.EstimatedPriceVnd;
            ingredient.UnitDefault = request.UnitDefault;
            ingredient.ImageUrl = request.ImageUrl;
            ingredient.IsActive = request.IsActive ?? ingredient.IsActive;
            _unitOfWork.Ingredients.Update(ingredient);
            await _unitOfWork.CompleteAsync();
            return Map(ingredient);
        }

        public async Task DeleteAsync(Guid id)
        {
            var ingredient = await _unitOfWork.Ingredients.GetByIdAsync(id) ?? throw new Exception("Ingredient not found.");
            _unitOfWork.Ingredients.Remove(ingredient);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<IngredientResponse> GetByIdAsync(Guid id)
        {
            var ingredient = await _unitOfWork.Ingredients.GetByIdAsync(id) ?? throw new Exception("Ingredient not found.");
            return Map(ingredient);
        }

        private static IngredientResponse Map(Ingredient e) => new() { Id = e.Id, NameVi = e.NameVi, NameEn = e.NameEn, Category = e.Category, CaloriesKcal = e.CaloriesKcal, ProteinG = e.ProteinG, CarbsG = e.CarbsG, FatG = e.FatG, EstimatedPriceVnd = e.EstimatedPriceVnd, UnitDefault = e.UnitDefault, ImageUrl = e.ImageUrl, IsActive = e.IsActive };
    }
}
