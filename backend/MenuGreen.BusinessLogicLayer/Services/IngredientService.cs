using System;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class IngredientService : IIngredientService
    {
        private readonly IUnitOfWork _unitOfWork;

        public IngredientService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<IngredientResponse> CreateAsync(IngredientUpsertRequest request)
        {
            var e = new Ingredient { Id = Guid.NewGuid(), NameVi = request.NameVi, NameEn = request.NameEn, Category = request.Category, CaloriesKcal = request.CaloriesKcal, ProteinG = request.ProteinG, CarbsG = request.CarbsG, FatG = request.FatG, EstimatedPriceVnd = request.EstimatedPriceVnd, UnitDefault = request.UnitDefault, ImageUrl = request.ImageUrl, IsActive = request.IsActive ?? true, CreatedAt = DateTime.UtcNow };
            await _unitOfWork.Ingredients.AddAsync(e);
            await _unitOfWork.CompleteAsync();
            return Map(e);
        }

        public async Task<IngredientResponse> UpdateAsync(Guid id, IngredientUpsertRequest request)
        {
            var e = await _unitOfWork.Ingredients.GetByIdAsync(id) ?? throw new Exception("Ingredient not found.");
            e.NameVi = request.NameVi; e.NameEn = request.NameEn; e.Category = request.Category; e.CaloriesKcal = request.CaloriesKcal; e.ProteinG = request.ProteinG; e.CarbsG = request.CarbsG; e.FatG = request.FatG; e.EstimatedPriceVnd = request.EstimatedPriceVnd; e.UnitDefault = request.UnitDefault; e.ImageUrl = request.ImageUrl; e.IsActive = request.IsActive ?? e.IsActive;
            _unitOfWork.Ingredients.Update(e); await _unitOfWork.CompleteAsync(); return Map(e);
        }

        public async Task DeleteAsync(Guid id) { var e = await _unitOfWork.Ingredients.GetByIdAsync(id) ?? throw new Exception("Ingredient not found."); _unitOfWork.Ingredients.Remove(e); await _unitOfWork.CompleteAsync(); }
        public async Task<IngredientResponse> GetByIdAsync(Guid id) => Map(await _unitOfWork.Ingredients.GetByIdAsync(id) ?? throw new Exception("Ingredient not found."));

        public async Task<IngredientSearchResponse> SearchAsync(string? keyword, string? category, bool? isActive)
        {
            var ingredients = await _unitOfWork.Ingredients.GetAllAsync();
            var query = ingredients.AsEnumerable();

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                query = query.Where(i =>
                    i.NameVi.Contains(keyword, StringComparison.OrdinalIgnoreCase) ||
                    (i.NameEn ?? string.Empty).Contains(keyword, StringComparison.OrdinalIgnoreCase));
            }

            if (!string.IsNullOrWhiteSpace(category))
            {
                query = query.Where(i =>
                    string.Equals(i.Category, category, StringComparison.OrdinalIgnoreCase));
            }

            if (isActive.HasValue)
            {
                query = query.Where(i => i.IsActive == isActive.Value);
            }

            var items = query.Select(Map).ToList();
            return new IngredientSearchResponse { Items = items, TotalCount = items.Count };
        }

        private static IngredientResponse Map(Ingredient e) => new() { Id = e.Id, NameVi = e.NameVi, NameEn = e.NameEn, Category = e.Category, CaloriesKcal = e.CaloriesKcal, ProteinG = e.ProteinG, CarbsG = e.CarbsG, FatG = e.FatG, EstimatedPriceVnd = e.EstimatedPriceVnd, UnitDefault = e.UnitDefault, ImageUrl = e.ImageUrl, IsActive = e.IsActive };
    }
}
