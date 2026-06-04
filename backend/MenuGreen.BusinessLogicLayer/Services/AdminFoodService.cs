using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class AdminFoodService : IAdminFoodService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IAllergenMatchingService _allergenMatching;

        public AdminFoodService(IUnitOfWork unitOfWork, IAllergenMatchingService allergenMatching)
        {
            _unitOfWork = unitOfWork;
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
            _unitOfWork.Foods.Remove(food);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<FoodResponse> GetByIdAsync(Guid id)
        {
            var food = await _unitOfWork.Foods.GetByIdAsync(id) ?? throw new Exception("Food not found.");
            return Map(food);
        }

        public async Task<FoodAllergenTagsResponse> GetAllergenTagsAsync(Guid id)
        {
            _ = await _unitOfWork.Foods.GetByIdAsync(id) ?? throw new Exception("Food not found.");
            var keys = await _allergenMatching.GetFoodAllergenKeysListAsync(id);
            return new FoodAllergenTagsResponse
            {
                FoodId = id,
                AllergenKeys = keys.ToList(),
                AllergenLabelsVi = AllergenCatalog.ToDisplayNamesVi(keys).ToList(),
                AvailableAllergenKeys = AllergenCatalog.AllKeys.ToList()
            };
        }

        public async Task<FoodAllergenTagsResponse> SetAllergenTagsAsync(Guid id, FoodAllergenTagsUpsertRequest request)
        {
            _ = await _unitOfWork.Foods.GetByIdAsync(id) ?? throw new Exception("Food not found.");
            await _allergenMatching.SetFoodAllergenKeysAsync(id, request.AllergenKeys);
            return await GetAllergenTagsAsync(id);
        }

        private static FoodResponse Map(Food f) => new() { Id = f.Id, NameVi = f.NameVi, NameEn = f.NameEn, Category = f.Category, Description = f.Description, CaloriesKcal = f.CaloriesKcal, ProteinG = f.ProteinG, CarbsG = f.CarbsG, FatG = f.FatG, FiberG = f.FiberG, EstimatedPriceVnd = f.EstimatedPriceVnd, DefaultServingG = f.DefaultServingG, ImageUrl = f.ImageUrl, IsActive = f.IsActive };
    }
}
