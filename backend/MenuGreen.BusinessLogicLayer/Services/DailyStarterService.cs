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
        private readonly IMealPlanService _mealPlanService;
        private readonly IHealthProfileService _healthProfileService;
        private readonly IUserAiProfileService _userAiProfileService;

        public DailyStarterService(
            IUnitOfWork unitOfWork,
            ApplicationDbContext db,
            IAllergenMatchingService allergenMatchingService,
            IAllergyService allergyService,
            IMealPlanService mealPlanService,
            IHealthProfileService healthProfileService,
            IUserAiProfileService userAiProfileService)
        {
            _unitOfWork = unitOfWork;
            _db = db;
            _allergenMatchingService = allergenMatchingService;
            _allergyService = allergyService;
            _mealPlanService = mealPlanService;
            _healthProfileService = healthProfileService;
            _userAiProfileService = userAiProfileService;
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
            
            // Tìm target calories từ HealthProfile để kế hoạch có calorie mục tiêu đúng đắn
            var health = await _healthProfileService.GetAsync(userId);
            var targetCalories = health?.TargetCalories ?? 2000;

            var items = request.Meals.Select(x => new DailyMenuPlanItemRequest
            {
                MealType = x.MealType,
                FoodId = x.FoodId,
                RecipeId = null,
                ScheduledTime = new TimeOnly(8, 0),
                TargetCalories = null
            }).ToList();

            var menuRequest = new CreateMealPlanFromDailyMenuRequest
            {
                PlannedDate = today,
                TargetCalories = targetCalories,
                Items = items
            };

            await _mealPlanService.CreateFromDailyMenuAsync(userId, menuRequest);
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
            var health = await _healthProfileService.GetAsync(userId);
            var aiProfile = await _userAiProfileService.GetAsync(userId);
            
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
            // 1. Cập nhật HealthProfile sử dụng IHealthProfileService
            var currentHealth = await _healthProfileService.GetAsync(userId);
            var updateHealthRequest = new UpdateHealthProfileRequest
            {
                HeightCm = request.HeightCm ?? currentHealth.HeightCm ?? 170m,
                WeightKg = request.WeightKg ?? currentHealth.WeightKg ?? 60m,
                BodyFatPercent = currentHealth.BodyFatPercent,
                ActivityLevel = currentHealth.ActivityLevel ?? "Light",
                Goal = currentHealth.Goal ?? "Maintain",
                TargetCalories = request.TargetCalories.HasValue ? (int?)request.TargetCalories.Value : currentHealth.TargetCalories
            };
            var health = await _healthProfileService.UpdateAsync(userId, updateHealthRequest);

            // 2. Cập nhật AI Profile sử dụng IUserAiProfileService
            UserAiProfileResponse? aiProfile = null;
            if (request.DietaryPreference != null)
            {
                var updateAiRequest = new UpdateUserAiProfileRequest
                {
                    Preferences = request.DietaryPreference
                };
                aiProfile = await _userAiProfileService.UpsertAsync(userId, updateAiRequest);
            }
            else
            {
                aiProfile = await _userAiProfileService.GetAsync(userId);
            }

            // 3. Cập nhật hồ sơ chất dị ứng (nếu có) thông qua IAllergyService
            if (request.Allergens != null)
            {
                await _allergyService.UpdateProfileAsync(userId, request.Allergens);
            }

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
                DietaryPreference = aiProfile?.Preferences,
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
