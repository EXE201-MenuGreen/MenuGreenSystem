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
    public class FoodService : IFoodService
    {
        private readonly IUnitOfWork _unitOfWork;

        public FoodService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
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

        public async Task<FoodResponse> GetByIdAsync(Guid id) => Map(await _unitOfWork.Foods.GetByIdAsync(id) ?? throw new Exception("Food not found."));

        public async Task<FoodSearchResponse> SearchAsync(string? keyword, decimal? minCalories, decimal? maxCalories, string? proteinLevel, int? maxPriceVnd, int? maxPrepTimeMin, string? category)
        {
            var foods = (await _unitOfWork.Foods.GetAllAsync()).Where(f => f.IsActive != false);
            if (!string.IsNullOrWhiteSpace(keyword)) foods = foods.Where(f => f.NameVi.Contains(keyword, StringComparison.OrdinalIgnoreCase) || (f.NameEn ?? string.Empty).Contains(keyword, StringComparison.OrdinalIgnoreCase));
            if (minCalories.HasValue) foods = foods.Where(f => (f.CaloriesKcal ?? 0) >= minCalories.Value);
            if (maxCalories.HasValue) foods = foods.Where(f => (f.CaloriesKcal ?? 0) <= maxCalories.Value);
            if (!string.IsNullOrWhiteSpace(category)) foods = foods.Where(f => string.Equals(f.Category, category, StringComparison.OrdinalIgnoreCase));
            if (maxPriceVnd.HasValue) foods = foods.Where(f => (f.EstimatedPriceVnd ?? int.MaxValue) <= maxPriceVnd.Value);
            if (!string.IsNullOrWhiteSpace(proteinLevel)) foods = proteinLevel.Equals("high", StringComparison.OrdinalIgnoreCase) ? foods.Where(f => (f.ProteinG ?? 0) >= 20) : foods.Where(f => (f.ProteinG ?? 0) < 20);
            if (maxPrepTimeMin.HasValue) foods = foods.Where(f => true);
            return new FoodSearchResponse { TotalCount = foods.Count(), Items = foods.Select(Map).ToList() };
        }

        private static FoodResponse Map(Food f) => new() { Id = f.Id, NameVi = f.NameVi, NameEn = f.NameEn, Category = f.Category, Description = f.Description, CaloriesKcal = f.CaloriesKcal, ProteinG = f.ProteinG, CarbsG = f.CarbsG, FatG = f.FatG, FiberG = f.FiberG, EstimatedPriceVnd = f.EstimatedPriceVnd, DefaultServingG = f.DefaultServingG, ImageUrl = f.ImageUrl, IsActive = f.IsActive };
    }
}
