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
    public class DailyStarterService : IDailyStarterService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ApplicationDbContext _db;
        private readonly IAllergenMatchingService _allergenMatchingService;
        private readonly IAllergyService _allergyService;

        public DailyStarterService(
            IUnitOfWork unitOfWork,
            ApplicationDbContext db,
            IAllergenMatchingService allergenMatchingService,
            IAllergyService allergyService)
        {
            _unitOfWork = unitOfWork;
            _db = db;
            _allergenMatchingService = allergenMatchingService;
            _allergyService = allergyService;
        }

        public async Task<DailyStarterTodayResponse> GetTodayStarterAsync(Guid userId)
        {
            var quotes = new[]
            {
                ("Sức khỏe không phải là thứ chúng ta có thể mua. Tuy nhiên, nó có thể là một tài khoản tiết kiệm cực kỳ giá trị.", "Anne Wilson Schaef"),
                ("Hãy chăm sóc cơ thể bạn. Đó là nơi duy nhất bạn phải sống.", "Jim Rohn"),
                ("Ăn uống là một nhu cầu, nhưng ăn uống thông minh là một nghệ thuật.", "La Rochefoucauld"),
                ("Một cơ thể khỏe mạnh là phòng khách của tâm hồn, một cơ thể đau ốm là nhà tù của nó.", "Francis Bacon"),
                ("Hãy đầu tư vào sức khỏe của bạn ngay hôm nay để nhận lại niềm vui sống ngày mai.", "MenuGreen")
            };
            var rand = new Random();
            var (quote, author) = quotes[rand.Next(quotes.Length)];

            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(h => h.UserId == userId);
            var health = healthProfiles.FirstOrDefault();

            var todayDateTime = DateTime.UtcNow.Date;
            var hasLogged = await _db.MealLogs.AnyAsync(m => m.UserId == userId && m.LoggedAt.HasValue && m.LoggedAt.Value.Date == todayDateTime);

            var isOnboardingComplete = health != null && health.HeightCm.HasValue && health.WeightKg.HasValue;
            var targetCalories = health?.TargetCalories ?? 2000;

            return new DailyStarterTodayResponse
            {
                WelcomeMessage = "Chào mừng bạn đến với ngày mới cùng MenuGreen!",
                Quote = quote,
                Author = author,
                CaloriesTarget = targetCalories,
                IsOnboardingComplete = isOnboardingComplete,
                HasLoggedToday = hasLogged,
                CurrentWeightKg = health?.WeightKg
            };
        }

        public async Task<IEnumerable<FoodResponse>> GetFeaturedMealsAsync()
        {
            var foods = await _db.Foods.AsNoTracking().Where(f => f.IsActive != false).Take(5).ToListAsync();
            var foodIds = foods.Select(f => f.Id).ToList();
            var foodAllergenMap = await _allergenMatchingService.GetFoodAllergenKeysAsync(foodIds);

            return foods.Select(f =>
            {
                foodAllergenMap.TryGetValue(f.Id, out var keys);
                keys ??= new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                return MapFoodToResponse(f, keys, new HashSet<string>());
            }).ToList();
        }

        public async Task SelectMealPlanAsync(Guid userId, DailyStarterSelectMealRequest request)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            
            // Tìm plan active hôm nay của user
            var existingPlans = await _unitOfWork.MealPlanHeaders.FindAsync(x => x.UserId == userId && x.IsActive && x.StartDate <= today && x.EndDate >= today);
            var planHeader = existingPlans.FirstOrDefault();

            if (planHeader == null)
            {
                planHeader = new MealPlanHeader
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Title = $"Kế hoạch ăn uống hôm nay ({today:dd/MM})",
                    PlanType = "Daily",
                    StartDate = today,
                    EndDate = today,
                    TargetCalories = 2000,
                    GeneratedBy = "DAILY_STARTER",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.MealPlanHeaders.AddAsync(planHeader);
                await _unitOfWork.CompleteAsync();
            }

            foreach (var item in request.Meals)
            {
                var food = await _unitOfWork.Foods.GetByIdAsync(item.FoodId);
                var targetCal = food != null ? (int?)(food.CaloriesKcal) : 300;

                await _unitOfWork.MealPlanItems.AddAsync(new MealPlanItem
                {
                    Id = Guid.NewGuid(),
                    MealPlanId = planHeader.Id,
                    MealType = item.MealType,
                    FoodId = item.FoodId,
                    PlannedDate = today,
                    TargetCalories = targetCal,
                    IsCompleted = false,
                    CreatedAt = DateTime.UtcNow
                });
            }

            await _unitOfWork.CompleteAsync();
        }

        public async Task<DailyStarterStartLogResponse> StartLogFlowAsync(Guid userId)
        {
            var now = DateTime.UtcNow.AddHours(7); // Giờ VN
            string suggestedMealType = "Breakfast";
            if (now.Hour >= 5 && now.Hour < 10) suggestedMealType = "Breakfast";
            else if (now.Hour >= 10 && now.Hour < 15) suggestedMealType = "Lunch";
            else if (now.Hour >= 15 && now.Hour < 21) suggestedMealType = "Dinner";
            else suggestedMealType = "Snack";

            var foods = await _db.Foods.AsNoTracking().Where(f => f.IsActive != false).Take(5).ToListAsync();
            var foodIds = foods.Select(f => f.Id).ToList();
            var foodAllergenMap = await _allergenMatchingService.GetFoodAllergenKeysAsync(foodIds);
            var userKeys = await _allergenMatchingService.GetUserAllergenKeysAsync(userId);

            var suggestedFoods = foods.Select(f =>
            {
                foodAllergenMap.TryGetValue(f.Id, out var keys);
                keys ??= new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                return MapFoodToResponse(f, keys, userKeys);
            }).ToList();

            return new DailyStarterStartLogResponse
            {
                SuggestedMealType = suggestedMealType,
                SuggestedFoods = suggestedFoods
            };
        }

        public async Task<DailyStarterPersonalizationResponse> GetPersonalizationAsync(Guid userId)
        {
            var health = (await _unitOfWork.HealthProfiles.FindAsync(h => h.UserId == userId)).FirstOrDefault();
            var aiProfile = (await _unitOfWork.UserAiProfiles.FindAsync(p => p.UserId == userId)).FirstOrDefault();
            
            var activeAllergies = await _unitOfWork.Allergies.FindAsync(a => a.UserId == userId && a.IsActive);
            var userKeys = activeAllergies
                .Select(a => AllergenCatalog.NormalizeToKey(a.Name) ?? a.Name)
                .Where(k => !string.IsNullOrEmpty(k))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            var allergensList = activeAllergies.Select(a => new AllergenProfileItem
            {
                AllergenKey = AllergenCatalog.NormalizeToKey(a.Name) ?? a.Name,
                Name = a.Name,
                Notes = a.Notes
            }).ToList();

            return new DailyStarterPersonalizationResponse
            {
                UserId = userId,
                HeightCm = health?.HeightCm,
                WeightKg = health?.WeightKg,
                TargetCalories = health?.TargetCalories,
                DietaryPreference = aiProfile?.Preferences,
                AllergenKeys = userKeys,
                Allergens = allergensList
            };
        }

        public async Task<DailyStarterPersonalizationResponse> UpdatePersonalizationAsync(Guid userId, DailyStarterPersonalizationUpdateRequest request)
        {
            // 1. Cập nhật HealthProfile
            var health = (await _unitOfWork.HealthProfiles.FindAsync(h => h.UserId == userId)).FirstOrDefault();
            if (health == null)
            {
                health = new HealthProfile
                {
                    UserId = userId,
                    HeightCm = request.HeightCm,
                    WeightKg = request.WeightKg,
                    TargetCalories = (int?)(request.TargetCalories ?? 2000),
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                HealthProfileMetricsCalculator.ApplyMacroTargets(health);
                await _unitOfWork.HealthProfiles.AddAsync(health);
            }
            else
            {
                if (request.HeightCm.HasValue) health.HeightCm = request.HeightCm;
                if (request.WeightKg.HasValue) health.WeightKg = request.WeightKg;
                if (request.TargetCalories.HasValue) health.TargetCalories = (int?)request.TargetCalories;
                health.UpdatedAt = DateTime.UtcNow;
                HealthProfileMetricsCalculator.ApplyMacroTargets(health);
                _unitOfWork.HealthProfiles.Update(health);
            }

            // 2. Cập nhật AI Profile
            var aiProfile = (await _unitOfWork.UserAiProfiles.FindAsync(p => p.UserId == userId)).FirstOrDefault();
            if (aiProfile == null)
            {
                aiProfile = new UserAiProfile
                {
                    UserId = userId,
                    Preferences = request.DietaryPreference,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.UserAiProfiles.AddAsync(aiProfile);
            }
            else
            {
                if (request.DietaryPreference != null) aiProfile.Preferences = request.DietaryPreference;
                aiProfile.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.UserAiProfiles.Update(aiProfile);
            }

            // 3. Cập nhật hồ sơ chất dị ứng (nếu có) thông qua IAllergyService
            if (request.Allergens != null)
            {
                await _allergyService.UpdateProfileAsync(userId, request.Allergens);
            }

            await _unitOfWork.CompleteAsync();
            await _db.SaveChangesAsync();

            var activeAllergies = await _unitOfWork.Allergies.FindAsync(a => a.UserId == userId && a.IsActive);
            var updatedUserKeys = activeAllergies
                .Select(a => AllergenCatalog.NormalizeToKey(a.Name) ?? a.Name)
                .Where(k => !string.IsNullOrEmpty(k))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            var allergensList = activeAllergies.Select(a => new AllergenProfileItem
            {
                AllergenKey = AllergenCatalog.NormalizeToKey(a.Name) ?? a.Name,
                Name = a.Name,
                Notes = a.Notes
            }).ToList();

            return new DailyStarterPersonalizationResponse
            {
                UserId = userId,
                HeightCm = health.HeightCm,
                WeightKg = health.WeightKg,
                TargetCalories = health.TargetCalories,
                DietaryPreference = aiProfile.Preferences,
                AllergenKeys = updatedUserKeys,
                Allergens = allergensList
            };
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
    }
}
