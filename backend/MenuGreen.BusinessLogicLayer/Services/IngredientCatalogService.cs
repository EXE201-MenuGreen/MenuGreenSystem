using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class IngredientCatalogService : IIngredientCatalogService
    {
        private readonly IUnitOfWork _unitOfWork;
        public IngredientCatalogService(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

        public async Task<IngredientResponse> CreateAsync(IngredientUpsertRequest request)
        {
            var entity = new Ingredient { Id = Guid.NewGuid(), NameVi = request.NameVi, NameEn = request.NameEn, Category = request.Category, CaloriesKcal = request.CaloriesKcal, ProteinG = request.ProteinG, CarbsG = request.CarbsG, FatG = request.FatG, EstimatedPriceVnd = request.EstimatedPriceVnd, UnitDefault = request.UnitDefault, ImageUrl = request.ImageUrl, IsActive = request.IsActive ?? true, CreatedAt = DateTime.UtcNow };
            await _unitOfWork.Ingredients.AddAsync(entity); await _unitOfWork.CompleteAsync(); return Map(entity);
        }

        public async Task<IngredientResponse> UpdateAsync(Guid id, IngredientUpsertRequest request)
        {
            var entity = await _unitOfWork.Ingredients.GetByIdAsync(id) ?? throw new Exception("Ingredient not found.");
            entity.NameVi = request.NameVi; entity.NameEn = request.NameEn; entity.Category = request.Category; entity.CaloriesKcal = request.CaloriesKcal; entity.ProteinG = request.ProteinG; entity.CarbsG = request.CarbsG; entity.FatG = request.FatG; entity.EstimatedPriceVnd = request.EstimatedPriceVnd; entity.UnitDefault = request.UnitDefault; entity.ImageUrl = request.ImageUrl; entity.IsActive = request.IsActive ?? entity.IsActive;
            _unitOfWork.Ingredients.Update(entity); await _unitOfWork.CompleteAsync(); return Map(entity);
        }

        public async Task DeleteAsync(Guid id) { var entity = await _unitOfWork.Ingredients.GetByIdAsync(id) ?? throw new Exception("Ingredient not found."); entity.IsActive = false; _unitOfWork.Ingredients.Update(entity); await _unitOfWork.CompleteAsync(); }
        public async Task<IngredientResponse> GetByIdAsync(Guid id)
        {
            var entity = await _unitOfWork.Ingredients.GetByIdAsync(id) ?? throw new Exception("Ingredient not found.");
            if (entity.IsActive == false) throw new Exception("Ingredient not found.");
            return Map(entity);
        }

        private static IngredientResponse Map(Ingredient e) => new() { Id = e.Id, NameVi = e.NameVi, NameEn = e.NameEn, Category = e.Category, CaloriesKcal = e.CaloriesKcal, ProteinG = e.ProteinG, CarbsG = e.CarbsG, FatG = e.FatG, EstimatedPriceVnd = e.EstimatedPriceVnd, UnitDefault = e.UnitDefault, ImageUrl = e.ImageUrl, IsActive = e.IsActive };
    }
}
