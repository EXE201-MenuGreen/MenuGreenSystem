using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class AllergyService : IAllergyService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ApplicationDbContext _db;
        private readonly IAllergenMatchingService _allergenMatchingService;

        public AllergyService(
            IUnitOfWork unitOfWork,
            ApplicationDbContext db,
            IAllergenMatchingService allergenMatchingService)
        {
            _unitOfWork = unitOfWork;
            _db = db;
            _allergenMatchingService = allergenMatchingService;
        }

        public async Task<IEnumerable<AllergyResponse>> GetAllAsync(Guid userId)
        {
            var allergies = await _unitOfWork.Allergies.FindAsync(allergy => allergy.UserId == userId);
            return allergies.Select(MapToResponse).ToList();
        }

        public async Task<AllergyResponse> CreateAsync(Guid userId, AllergyUpsertRequest request)
        {
            var allergy = new Allergy
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Name = request.Name,
                Notes = request.Notes,
                IsActive = request.IsActive ?? true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Allergies.AddAsync(allergy);
            await _unitOfWork.CompleteAsync();
            await SyncUserAllergyAsync(userId, allergy.Id);

            return MapToResponse(allergy);
        }

        public async Task<AllergyResponse> UpdateAsync(Guid userId, Guid allergyId, AllergyUpsertRequest request)
        {
            var allergy = await GetOwnedAllergyAsync(userId, allergyId);

            allergy.Name = request.Name;
            allergy.Notes = request.Notes;
            allergy.IsActive = request.IsActive ?? allergy.IsActive;
            allergy.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Allergies.Update(allergy);
            await _unitOfWork.CompleteAsync();

            return MapToResponse(allergy);
        }

        public async Task DeleteAsync(Guid userId, Guid allergyId)
        {
            var allergy = await GetOwnedAllergyAsync(userId, allergyId);
            var userAllergy = await _db.UserAllergies
                .FirstOrDefaultAsync(x => x.UserId == userId && x.AllergyId == allergyId);
            if (userAllergy != null) _db.UserAllergies.Remove(userAllergy);
            _unitOfWork.Allergies.Remove(allergy);
            await _unitOfWork.CompleteAsync();
        }

        private async Task SyncUserAllergyAsync(Guid userId, Guid allergyId)
        {
            var exists = await _db.UserAllergies
                .AnyAsync(x => x.UserId == userId && x.AllergyId == allergyId);
            if (exists) return;

            await _db.UserAllergies.AddAsync(new UserAllergy
            {
                UserId = userId,
                AllergyId = allergyId,
                CreatedAt = DateTime.UtcNow
            });
            await _db.SaveChangesAsync();
        }

        private async Task<Allergy> GetOwnedAllergyAsync(Guid userId, Guid allergyId)
        {
            var allergy = await _unitOfWork.Allergies.GetByIdAsync(allergyId);

            if (allergy == null)
            {
                throw new Exception("Allergy not found.");
            }

            if (allergy.UserId != userId)
            {
                throw new Exception("Forbidden.");
            }

            return allergy;
        }

        public async Task<IEnumerable<AllergyResponse>> UpdateProfileAsync(Guid userId, List<AllergenProfileItem> allergens)
        {
            var existingAllergies = await _unitOfWork.Allergies.FindAsync(a => a.UserId == userId);
            
            // Lọc và chuẩn hóa danh sách gửi lên
            var normalizedItems = new List<(string Key, string? Name, string? Notes)>();
            foreach (var item in allergens)
            {
                var key = AllergenCatalog.NormalizeToKey(item.AllergenKey) ?? item.AllergenKey?.Trim();
                if (!string.IsNullOrEmpty(key))
                {
                    // Tránh trùng lặp key
                    if (!normalizedItems.Any(x => string.Equals(x.Key, key, StringComparison.OrdinalIgnoreCase)))
                    {
                        normalizedItems.Add((key, item.Name, item.Notes));
                    }
                }
            }

            // Cập nhật các dị ứng hiện tại của user
            foreach (var allergy in existingAllergies)
            {
                var key = AllergenCatalog.NormalizeToKey(allergy.Name);
                var matchedItem = key != null 
                    ? normalizedItems.FirstOrDefault(x => string.Equals(x.Key, key, StringComparison.OrdinalIgnoreCase))
                    : default;

                if (matchedItem.Key != null)
                {
                    allergy.IsActive = true;
                    // Cập nhật cả ghi chú nếu client gửi lên
                    if (matchedItem.Notes != null)
                    {
                        allergy.Notes = matchedItem.Notes;
                    }
                    // Cập nhật cả tên nếu client gửi lên
                    if (!string.IsNullOrWhiteSpace(matchedItem.Name))
                    {
                        allergy.Name = matchedItem.Name;
                    }
                    allergy.UpdatedAt = DateTime.UtcNow;
                    _unitOfWork.Allergies.Update(allergy);
                    await SyncUserAllergyAsync(userId, allergy.Id);
                }
                else
                {
                    allergy.IsActive = false;
                    allergy.UpdatedAt = DateTime.UtcNow;
                    _unitOfWork.Allergies.Update(allergy);
                }
            }

            // Thêm mới các dị ứng chưa có
            foreach (var item in normalizedItems)
            {
                var exists = existingAllergies.Any(a => string.Equals(AllergenCatalog.NormalizeToKey(a.Name), item.Key, StringComparison.OrdinalIgnoreCase));
                if (!exists)
                {
                    var allergy = new Allergy
                    {
                        Id = Guid.NewGuid(),
                        UserId = userId,
                        Name = item.Name ?? AllergenCatalog.GetDisplayNameVi(item.Key),
                        Notes = item.Notes ?? "Cập nhật hồ sơ hàng loạt",
                        IsActive = true,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };
                    await _unitOfWork.Allergies.AddAsync(allergy);
                    await _unitOfWork.CompleteAsync(); // Hoàn thành trước để sinh ID
                    await SyncUserAllergyAsync(userId, allergy.Id);
                }
            }

            await _unitOfWork.CompleteAsync();

            var updatedAllergies = await _unitOfWork.Allergies.FindAsync(a => a.UserId == userId);
            return updatedAllergies.Select(MapToResponse).ToList();
        }

        public Task<IEnumerable<AllergyCatalogResponse>> GetCatalogAsync()
        {
            var catalog = AllergenCatalog.AllKeys.Select(key => new AllergyCatalogResponse
            {
                Key = key,
                DisplayNameVi = AllergenCatalog.GetDisplayNameVi(key)
            });
            return Task.FromResult<IEnumerable<AllergyCatalogResponse>>(catalog);
        }

        public async Task<IEnumerable<FoodResponse>> GetRecommendationsAsync(Guid userId)
        {
            var userKeys = await _allergenMatchingService.GetUserAllergenKeysAsync(userId);
            var foods = await _db.Foods.AsNoTracking().Where(f => f.IsActive != false).ToListAsync();

            if (userKeys.Count == 0)
            {
                return foods.Take(20).Select(f => MapFoodToResponse(f, new HashSet<string>(), userKeys)).ToList();
            }

            var foodIds = foods.Select(f => f.Id).ToList();
            var foodAllergenMap = await _allergenMatchingService.GetFoodAllergenKeysAsync(foodIds);

            var safeFoods = new List<FoodResponse>();
            foreach (var food in foods)
            {
                foodAllergenMap.TryGetValue(food.Id, out var foodKeys);
                foodKeys ??= new HashSet<string>(StringComparer.OrdinalIgnoreCase);

                if (!foodKeys.Overlaps(userKeys))
                {
                    safeFoods.Add(MapFoodToResponse(food, foodKeys, userKeys));
                }
            }

            return safeFoods.Take(20).ToList();
        }

        private static FoodResponse MapFoodToResponse(Food f, HashSet<string> foodKeys, HashSet<string> userKeys)
        {
            var dto = new FoodResponse
            {
                Id = f.Id,
                NameVi = f.NameVi,
                NameEn = f.NameEn,
                Category = f.Category,
                Description = f.Description,
                CaloriesKcal = f.CaloriesKcal,
                ProteinG = f.ProteinG,
                CarbsG = f.CarbsG,
                FatG = f.FatG,
                FiberG = f.FiberG,
                EstimatedPriceVnd = f.EstimatedPriceVnd,
                DefaultServingG = f.DefaultServingG,
                ImageUrl = f.ImageUrl,
                IsActive = f.IsActive,
                AllergenKeys = foodKeys.OrderBy(k => k).ToList(),
                AllergenLabelsVi = AllergenCatalog.ToDisplayNamesVi(foodKeys).ToList()
            };

            var matchedKeys = foodKeys.Where(userKeys.Contains).ToList();
            dto.MatchedAllergens = AllergenCatalog.ToDisplayNamesVi(matchedKeys).ToList();
            dto.AllergyRiskLevel = matchedKeys.Count > 0 ? AllergenCatalog.RiskHigh : AllergenCatalog.RiskNone;
            dto.IsSafeForUser = AllergenCatalog.IsSafeForUser(dto.AllergyRiskLevel);
            return dto;
        }

        private static AllergyResponse MapToResponse(Allergy allergy)
        {
            return new AllergyResponse
            {
                Id = allergy.Id,
                Name = allergy.Name,
                Notes = allergy.Notes,
                IsActive = allergy.IsActive
            };
        }
    }
}
