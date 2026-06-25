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
            var allergies = await _unitOfWork.Allergies.FindAsync(allergy => allergy.UserId == userId && allergy.IsActive);
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
            allergy.IsActive = false;
            _unitOfWork.Allergies.Update(allergy);
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

            if (allergy == null || !allergy.IsActive)
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
            var existingList = existingAllergies.ToList();
            
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

            var userAllergiesInDb = await _db.UserAllergies.Where(x => x.UserId == userId).ToListAsync();

            // Cập nhật các dị ứng hiện tại của user
            foreach (var allergy in existingList)
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

                    if (!userAllergiesInDb.Any(x => x.AllergyId == allergy.Id))
                    {
                        await _db.UserAllergies.AddAsync(new UserAllergy
                        {
                            UserId = userId,
                            AllergyId = allergy.Id,
                            CreatedAt = DateTime.UtcNow
                        });
                    }
                }
                else
                {
                    allergy.IsActive = false;
                    allergy.UpdatedAt = DateTime.UtcNow;
                    _unitOfWork.Allergies.Update(allergy);
                }

                // Lưu thay đổi tuần tự cho từng Allergy để tránh lỗi Circular Dependency
                await _unitOfWork.CompleteAsync();
            }

            // Thêm mới các dị ứng chưa có
            foreach (var item in normalizedItems)
            {
                var exists = existingList.Any(a => string.Equals(AllergenCatalog.NormalizeToKey(a.Name), item.Key, StringComparison.OrdinalIgnoreCase));
                if (!exists)
                {
                    var allergyId = Guid.NewGuid();
                    var allergy = new Allergy
                    {
                        Id = allergyId,
                        UserId = userId,
                        Name = item.Name ?? AllergenCatalog.GetDisplayNameVi(item.Key),
                        Notes = item.Notes ?? "Cập nhật hồ sơ hàng loạt",
                        IsActive = true,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };
                    await _unitOfWork.Allergies.AddAsync(allergy);

                    await _db.UserAllergies.AddAsync(new UserAllergy
                    {
                        UserId = userId,
                        AllergyId = allergyId,
                        CreatedAt = DateTime.UtcNow
                    });

                    // Lưu thay đổi tuần tự cho từng Allergy thêm mới
                    await _unitOfWork.CompleteAsync();
                }
            }

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
