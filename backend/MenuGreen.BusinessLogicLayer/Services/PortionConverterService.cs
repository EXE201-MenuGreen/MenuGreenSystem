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
    public class PortionConverterService : IPortionConverterService
    {
        private readonly IUnitOfWork _unitOfWork;

        private static readonly Dictionary<string, (decimal Grams, string Desc)> DefaultUnits = new(StringComparer.OrdinalIgnoreCase)
        {
            { "chén", (150m, "Chén cơm, chén chấm gia vị thông thường (khoảng 150g)") },
            { "bát", (200m, "Bát ăn canh hoặc bát cơm nhỡ (khoảng 200g)") },
            { "tô", (500m, "Tô lớn đựng phở, bún, hủ tiếu (khoảng 500g-650g)") },
            { "đĩa", (250m, "Đĩa thức ăn, đĩa rau luộc trung bình (khoảng 200g-250g)") },
            { "muỗng", (5m, "Muỗng cà phê dầu ăn, gia vị nhỏ (khoảng 5g)") },
            { "muỗng canh", (15m, "Muỗng canh lớn ăn cơm, muỗng ăn lẩu (khoảng 15g)") },
            { "ly", (250m, "Ly uống nước lọc, nước ngọt tiêu chuẩn (khoảng 250ml)") },
            { "cốc", (240m, "Cốc uống trà đá, sữa đậu nành nhỡ (khoảng 240ml)") },
            { "trái", (100m, "Trái cây nhỡ như táo, cam, chuối quả (khoảng 80g-150g)") },
            { "quả", (100m, "Trái quả nhỡ tiêu chuẩn (khoảng 100g)") }
        };

        public PortionConverterService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        private async Task EnsureSeedDataAsync()
        {
            var existing = await _unitOfWork.FoodPortionMappings.GetAllAsync();
            if (existing.Any())
            {
                return;
            }

            var allFoods = (await _unitOfWork.Foods.GetAllAsync()).ToList();
            if (!allFoods.Any())
            {
                return;
            }

            var mappingsToSeed = new List<FoodPortionMapping>();

            // Rice
            var rice = allFoods.FirstOrDefault(f => f.NameVi.Contains("Cơm", StringComparison.OrdinalIgnoreCase));
            if (rice != null)
            {
                mappingsToSeed.Add(new FoodPortionMapping { Id = Guid.NewGuid(), FoodId = rice.Id, Unit = "chén", GramsPerUnit = 150m, CreatedAt = DateTime.UtcNow });
                mappingsToSeed.Add(new FoodPortionMapping { Id = Guid.NewGuid(), FoodId = rice.Id, Unit = "đĩa", GramsPerUnit = 250m, CreatedAt = DateTime.UtcNow });
            }

            // Pho
            var pho = allFoods.FirstOrDefault(f => f.NameVi.Contains("Phở", StringComparison.OrdinalIgnoreCase) || f.NameVi.Contains("Bún", StringComparison.OrdinalIgnoreCase));
            if (pho != null)
            {
                mappingsToSeed.Add(new FoodPortionMapping { Id = Guid.NewGuid(), FoodId = pho.Id, Unit = "bát", GramsPerUnit = 600m, CreatedAt = DateTime.UtcNow });
                mappingsToSeed.Add(new FoodPortionMapping { Id = Guid.NewGuid(), FoodId = pho.Id, Unit = "tô", GramsPerUnit = 650m, CreatedAt = DateTime.UtcNow });
            }

            // Oil
            var oil = allFoods.FirstOrDefault(f => f.NameVi.Contains("Dầu", StringComparison.OrdinalIgnoreCase) || f.NameVi.Contains("Mỡ", StringComparison.OrdinalIgnoreCase));
            if (oil != null)
            {
                mappingsToSeed.Add(new FoodPortionMapping { Id = Guid.NewGuid(), FoodId = oil.Id, Unit = "muỗng", GramsPerUnit = 5m, CreatedAt = DateTime.UtcNow });
                mappingsToSeed.Add(new FoodPortionMapping { Id = Guid.NewGuid(), FoodId = oil.Id, Unit = "muỗng canh", GramsPerUnit = 15m, CreatedAt = DateTime.UtcNow });
            }

            // Vegetable
            var veg = allFoods.FirstOrDefault(f => f.NameVi.Contains("Rau", StringComparison.OrdinalIgnoreCase) || f.NameVi.Contains("Cải", StringComparison.OrdinalIgnoreCase));
            if (veg != null)
            {
                mappingsToSeed.Add(new FoodPortionMapping { Id = Guid.NewGuid(), FoodId = veg.Id, Unit = "đĩa", GramsPerUnit = 200m, CreatedAt = DateTime.UtcNow });
                mappingsToSeed.Add(new FoodPortionMapping { Id = Guid.NewGuid(), FoodId = veg.Id, Unit = "chén", GramsPerUnit = 100m, CreatedAt = DateTime.UtcNow });
            }

            // Fruit (Banana / Apple)
            var fruit = allFoods.FirstOrDefault(f => f.NameVi.Contains("Chuối", StringComparison.OrdinalIgnoreCase) || f.NameVi.Contains("Táo", StringComparison.OrdinalIgnoreCase) || f.NameVi.Contains("Quả", StringComparison.OrdinalIgnoreCase));
            if (fruit != null)
            {
                mappingsToSeed.Add(new FoodPortionMapping { Id = Guid.NewGuid(), FoodId = fruit.Id, Unit = "trái", GramsPerUnit = 120m, CreatedAt = DateTime.UtcNow });
                mappingsToSeed.Add(new FoodPortionMapping { Id = Guid.NewGuid(), FoodId = fruit.Id, Unit = "quả", GramsPerUnit = 120m, CreatedAt = DateTime.UtcNow });
            }

            if (mappingsToSeed.Any())
            {
                foreach (var mapping in mappingsToSeed)
                {
                    await _unitOfWork.FoodPortionMappings.AddAsync(mapping);
                }
                await _unitOfWork.CompleteAsync();
            }
        }

        public Task<IEnumerable<PortionUnitResponse>> GetDefaultUnitsAsync()
        {
            var list = DefaultUnits.Select(x => new PortionUnitResponse
            {
                UnitName = x.Key,
                GramsPerUnit = x.Value.Grams,
                Description = x.Value.Desc
            });
            return Task.FromResult(list);
        }

        public async Task<IEnumerable<PortionUnitResponse>> GetUnitsByFoodAsync(Guid foodId)
        {
            await EnsureSeedDataAsync();

            var mappings = await _unitOfWork.FoodPortionMappings.FindAsync(m => m.FoodId == foodId);
            var mappingList = mappings.ToList();

            if (mappingList.Any())
            {
                return mappingList.Select(m => new PortionUnitResponse
                {
                    UnitName = m.Unit,
                    GramsPerUnit = m.GramsPerUnit,
                    Description = $"Đơn vị quy đổi chuẩn cho món ăn: 1 {m.Unit} = {m.GramsPerUnit}g"
                });
            }

            // Nếu không cấu hình riêng, trả về list default chung
            return await GetDefaultUnitsAsync();
        }

        public async Task<PortionConvertResponse> ConvertPortionAsync(PortionConvertRequest request, Guid? userId = null)
        {
            await EnsureSeedDataAsync();

            var food = await _unitOfWork.Foods.GetByIdAsync(request.FoodId) ?? throw new Exception("Không tìm thấy thực phẩm/món ăn yêu cầu.");

            decimal factor = 1.0m;
            bool found = false;

            // 1. Tìm trong đơn vị cá nhân của User trước
            if (userId.HasValue)
            {
                var customUnits = await _unitOfWork.CustomUserPortions.FindAsync(c => c.UserId == userId.Value && c.UnitName.ToLower() == request.Unit.ToLower().Trim());
                var customUnit = customUnits.FirstOrDefault();
                if (customUnit != null)
                {
                    factor = customUnit.GramsEquivalent;
                    found = true;
                }
            }

            // 2. Tìm trong cấu hình Portion Mapping của Food đó
            if (!found)
            {
                var mappings = await _unitOfWork.FoodPortionMappings.FindAsync(m => m.FoodId == request.FoodId && m.Unit.ToLower() == request.Unit.ToLower().Trim());
                var mapping = mappings.FirstOrDefault();
                if (mapping != null)
                {
                    factor = mapping.GramsPerUnit;
                    found = true;
                }
            }

            // 3. Tìm trong Default Units
            if (!found)
            {
                if (DefaultUnits.TryGetValue(request.Unit.Trim(), out var def))
                {
                    factor = def.Grams;
                    found = true;
                }
            }

            // Nếu không tìm thấy gì, mặc định coi đơn vị là gram trực tiếp (hệ số 1)
            if (!found)
            {
                factor = 1.0m;
            }

            var convertedGrams = request.Quantity * factor;
            var ratio = convertedGrams / 100m;

            return new PortionConvertResponse
            {
                FoodId = request.FoodId,
                OriginalUnit = request.Unit,
                OriginalQuantity = request.Quantity,
                ConvertedGrams = Math.Round(convertedGrams, 1),
                CaloriesKcal = Math.Round((food.CaloriesKcal ?? 0) * ratio, 1),
                ProteinG = Math.Round((food.ProteinG ?? 0) * ratio, 1),
                CarbsG = Math.Round((food.CarbsG ?? 0) * ratio, 1),
                FatG = Math.Round((food.FatG ?? 0) * ratio, 1)
            };
        }

        public async Task<IEnumerable<CustomUserPortionResponse>> GetCustomUnitsAsync(Guid userId)
        {
            var list = await _unitOfWork.CustomUserPortions.FindAsync(c => c.UserId == userId);
            return list.OrderBy(c => c.UnitName).Select(c => new CustomUserPortionResponse
            {
                Id = c.Id,
                UserId = c.UserId,
                UnitName = c.UnitName,
                GramsEquivalent = c.GramsEquivalent
            });
        }

        public async Task<CustomUserPortionResponse> CreateCustomUnitAsync(Guid userId, CustomUserPortionUpsertRequest request)
        {
            var nameNormalized = request.UnitName.Trim();
            
            // Check trùng
            var existing = await _unitOfWork.CustomUserPortions.FindAsync(c => c.UserId == userId && c.UnitName.ToLower() == nameNormalized.ToLower());
            if (existing.Any())
            {
                throw new Exception($"Đơn vị tùy chỉnh '{nameNormalized}' đã tồn tại.");
            }

            var entity = new CustomUserPortion
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                UnitName = nameNormalized,
                GramsEquivalent = request.GramsEquivalent,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.CustomUserPortions.AddAsync(entity);
            await _unitOfWork.CompleteAsync();

            return new CustomUserPortionResponse
            {
                Id = entity.Id,
                UserId = entity.UserId,
                UnitName = entity.UnitName,
                GramsEquivalent = entity.GramsEquivalent
            };
        }

        public async Task<CustomUserPortionResponse> UpdateCustomUnitAsync(Guid userId, Guid id, CustomUserPortionUpsertRequest request)
        {
            var entity = await _unitOfWork.CustomUserPortions.GetByIdAsync(id) ?? throw new Exception("Không tìm thấy đơn vị tùy chỉnh yêu cầu.");
            if (entity.UserId != userId)
            {
                throw new Exception("Bạn không có quyền chỉnh sửa đơn vị tùy chỉnh này.");
            }

            var nameNormalized = request.UnitName.Trim();
            var duplicate = await _unitOfWork.CustomUserPortions.FindAsync(c => c.UserId == userId && c.Id != id && c.UnitName.ToLower() == nameNormalized.ToLower());
            if (duplicate.Any())
            {
                throw new Exception($"Đơn vị tùy chỉnh '{nameNormalized}' đã tồn tại.");
            }

            entity.UnitName = nameNormalized;
            entity.GramsEquivalent = request.GramsEquivalent;
            entity.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.CustomUserPortions.Update(entity);
            await _unitOfWork.CompleteAsync();

            return new CustomUserPortionResponse
            {
                Id = entity.Id,
                UserId = entity.UserId,
                UnitName = entity.UnitName,
                GramsEquivalent = entity.GramsEquivalent
            };
        }

        public async Task<bool> DeleteCustomUnitAsync(Guid userId, Guid id)
        {
            var entity = await _unitOfWork.CustomUserPortions.GetByIdAsync(id) ?? throw new Exception("Không tìm thấy đơn vị tùy chỉnh yêu cầu.");
            if (entity.UserId != userId)
            {
                throw new Exception("Bạn không có quyền xóa đơn vị tùy chỉnh này.");
            }

            _unitOfWork.CustomUserPortions.Remove(entity);
            await _unitOfWork.CompleteAsync();
            return true;
        }
    }
}
