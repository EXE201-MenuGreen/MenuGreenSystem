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
        private readonly IRecommendationService _recommendationService;
        private readonly INutritionAssistantService _nutritionAssistantService;
        private readonly INutritionTrackingService _nutritionTrackingService;

        public DailyStarterService(
            IUnitOfWork unitOfWork,
            ApplicationDbContext db,
            IAllergenMatchingService allergenMatchingService,
            IAllergyService allergyService,
            IMealPlanService mealPlanService,
            IHealthProfileService healthProfileService,
            IUserAiProfileService userAiProfileService,
            IRecommendationService recommendationService,
            INutritionAssistantService nutritionAssistantService,
            INutritionTrackingService nutritionTrackingService)
        {
            _unitOfWork = unitOfWork;
            _db = db;
            _allergenMatchingService = allergenMatchingService;
            _allergyService = allergyService;
            _mealPlanService = mealPlanService;
            _healthProfileService = healthProfileService;
            _userAiProfileService = userAiProfileService;
            _recommendationService = recommendationService;
            _nutritionAssistantService = nutritionAssistantService;
            _nutritionTrackingService = nutritionTrackingService;
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

            var (startUtc, endUtc) = GetVietnamDayWindowUtc();
            var todayLogs = await _db.MealLogs
                .AsNoTracking()
                .Where(m => m.UserId == userId && m.LoggedAt.HasValue && m.LoggedAt.Value >= startUtc && m.LoggedAt.Value < endUtc)
                .ToListAsync();
            var hasLogged = todayLogs.Count > 0;

            var isOnboardingComplete = health != null && health.HeightCm.HasValue && health.WeightKg.HasValue;
            var targetCalories = health?.TargetCalories ?? 2000;
            var consumedCalories = todayLogs.Sum(x => x.CaloriesKcal ?? 0);

            return new DailyStarterTodayResponse
            {
                WelcomeMessage = "Welcome to a new day with MenuGreen!",
                Quote = quote,
                Author = author,
                CaloriesTarget = targetCalories,
                CaloriesConsumed = consumedCalories,
                CaloriesRemaining = Math.Max(0, targetCalories - consumedCalories),
                IsOnboardingComplete = isOnboardingComplete,
                HasLoggedToday = hasLogged,
                CurrentWeightKg = health?.WeightKg
            };
        }

        public async Task<IEnumerable<FoodResponse>> GetFeaturedMealsAsync(Guid userId)
        {
            var foods = await _db.Foods
                .AsNoTracking()
                .Where(f => f.IsActive != false)
                .ToListAsync();
            var foodIds = foods.Select(f => f.Id).ToList();
            var foodAllergenMap = await _allergenMatchingService.GetFoodAllergenKeysAsync(foodIds);
            var userKeys = await _allergenMatchingService.GetUserAllergenKeysAsync(userId);
            var aiProfile = await _userAiProfileService.GetAsync(userId);
            var budget = aiProfile?.BudgetPerMealVnd ?? int.MaxValue;
            var preferredRegion = aiProfile?.VietnamRegion?.Trim();
            var caloriesRemaining = await GetCaloriesRemainingAsync(userId);
            var mealCalorieTarget = Math.Max(200m, Math.Min(caloriesRemaining, caloriesRemaining * 0.35m));

            return foods
                .Select(f =>
                {
                    foodAllergenMap.TryGetValue(f.Id, out var keys);
                    keys ??= new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                    var isSafe = !userKeys.Any(keys.Contains);
                    var regionScore = !string.IsNullOrWhiteSpace(preferredRegion) &&
                                      !string.IsNullOrWhiteSpace(f.Region) &&
                                      f.Region.Contains(preferredRegion, StringComparison.OrdinalIgnoreCase)
                        ? 1
                        : 0;
                    var withinBudget = !f.EstimatedPriceVnd.HasValue || f.EstimatedPriceVnd.Value <= budget ? 1 : 0;
                    var calorieDistance = Math.Abs((f.CaloriesKcal ?? 0) - mealCalorieTarget);
                    return new { Food = f, Keys = keys, IsSafe = isSafe, RegionScore = regionScore, WithinBudget = withinBudget, CalorieDistance = calorieDistance };
                })
                .Where(x => x.IsSafe)
                .OrderByDescending(x => x.WithinBudget)
                .ThenByDescending(x => x.RegionScore)
                .ThenBy(x => x.CalorieDistance)
                .ThenBy(x => x.Food.NameVi)
                .Take(3)
                .Select(x => MapFoodToResponse(x.Food, x.Keys, userKeys))
                .ToList();
        }

        public async Task SelectMealPlanAsync(Guid userId, DailyStarterSelectMealRequest request)
        {
            if (request.Meals.Count == 0)
            {
                throw new InvalidOperationException("Vui lòng chọn ít nhất một món ăn.");
            }

            var requestedFoodIds = request.Meals.Select(x => x.FoodId).Distinct().ToList();
            var activeFoods = await _db.Foods
                .AsNoTracking()
                .Where(x => requestedFoodIds.Contains(x.Id) && x.IsActive != false)
                .ToListAsync();
            if (activeFoods.Count != requestedFoodIds.Count)
            {
                throw new InvalidOperationException("Một hoặc nhiều món ăn không còn khả dụng.");
            }

            var foodAllergens = await _allergenMatchingService.GetFoodAllergenKeysAsync(requestedFoodIds);
            var userAllergens = await _allergenMatchingService.GetUserAllergenKeysAsync(userId);
            if (requestedFoodIds.Any(id => foodAllergens.TryGetValue(id, out var keys) && userAllergens.Any(keys.Contains)))
            {
                throw new InvalidOperationException("Không thể áp dụng món có thành phần dị ứng vào kế hoạch.");
            }

            var today = DateOnly.FromDateTime(DateTime.UtcNow.AddHours(7));
            
            // Tìm target calories từ HealthProfile để kế hoạch có calorie mục tiêu đúng đắn
            var health = await _healthProfileService.GetAsync(userId);
            var targetCalories = health?.TargetCalories ?? 2000;

            var items = request.Meals.Select(x => new DailyMenuPlanItemRequest
            {
                MealType = x.MealType,
                FoodId = x.FoodId,
                RecipeId = null,
                ScheduledTime = GetScheduledTime(x.MealType),
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

            var suggestedFoods = (await GetFeaturedMealsAsync(userId)).ToList();
            var selectedFood = suggestedFoods.FirstOrDefault();
            if (selectedFood == null)
            {
                throw new InvalidOperationException("Chưa có món an toàn phù hợp để ghi nhận nhanh.");
            }

            var food = await _db.Foods.AsNoTracking().FirstAsync(x => x.Id == selectedFood.Id);
            var mealLog = await _nutritionTrackingService.CreateMealLogAsync(userId, new MealLogUpsertRequest
            {
                FoodId = food.Id,
                MealType = suggestedMealType,
                QuantityG = food.DefaultServingG ?? 100,
                LoggedAt = DateTime.UtcNow,
                Notes = "Ghi nhận nhanh từ Daily Starter"
            });

            return new DailyStarterStartLogResponse
            {
                SuggestedMealType = suggestedMealType,
                SuggestedFoods = suggestedFoods,
                LoggedMealId = mealLog.Id,
                LoggedFood = selectedFood
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

        private async Task<decimal> GetCaloriesRemainingAsync(Guid userId)
        {
            var health = await _healthProfileService.GetAsync(userId);
            var target = health?.TargetCalories ?? 2000;
            var (startUtc, endUtc) = GetVietnamDayWindowUtc();
            var consumed = await _db.MealLogs
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.LoggedAt.HasValue && x.LoggedAt.Value >= startUtc && x.LoggedAt.Value < endUtc)
                .SumAsync(x => x.CaloriesKcal ?? 0);
            return Math.Max(0, target - consumed);
        }

        private static (DateTime StartUtc, DateTime EndUtc) GetVietnamDayWindowUtc()
        {
            var vietnamNow = DateTime.UtcNow.AddHours(7);
            var vietnamMidnightAsUtc = new DateTime(
                vietnamNow.Year,
                vietnamNow.Month,
                vietnamNow.Day,
                0,
                0,
                0,
                DateTimeKind.Utc);
            var startUtc = vietnamMidnightAsUtc.AddHours(-7);
            return (startUtc, startUtc.AddDays(1));
        }

        private static TimeOnly GetScheduledTime(string mealType)
        {
            return mealType.Trim().ToLowerInvariant() switch
            {
                "breakfast" => new TimeOnly(8, 0),
                "lunch" => new TimeOnly(12, 0),
                "dinner" => new TimeOnly(19, 0),
                _ => new TimeOnly(15, 30)
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
                Region = f.Region,
                AllergenKeys = foodKeys.OrderBy(k => k).ToList(),
                AllergenLabelsVi = AllergenCatalog.ToDisplayNamesVi(foodKeys).ToList()
            };

            var matchedKeys = foodKeys.Where(userKeys.Contains).ToList();
            dto.MatchedAllergens = AllergenCatalog.ToDisplayNamesVi(matchedKeys).ToList();
            dto.AllergyRiskLevel = matchedKeys.Count > 0 ? AllergenCatalog.RiskHigh : AllergenCatalog.RiskNone;
            dto.IsSafeForUser = AllergenCatalog.IsSafeForUser(dto.AllergyRiskLevel);
            return dto;
        }

        public async Task<IEnumerable<RecommendationItemResponse>> GetRecommendationsAsync(Guid userId, RecommendationRequest request)
        {
            if (request.TargetCalories == null || request.TargetCalories <= 0)
            {
                var health = await _healthProfileService.GetAsync(userId);
                request.TargetCalories = health?.TargetCalories ?? 2000;
            }

            var limit = request.Top > 0 ? request.Top : 10;
            var random = new Random();

            var today = DateOnly.FromDateTime(DateTime.UtcNow.AddHours(7));
            var previousPlanIds = await _db.MealPlanHeaders
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.IsActive && x.StartDate < today)
                .Select(x => x.Id)
                .ToListAsync();

            var excludedFoodIds = new List<Guid>();
            var excludedRecipeIds = new List<Guid>();

            if (previousPlanIds.Count > 0)
            {
                var usedItems = await _db.MealPlanItems
                    .AsNoTracking()
                    .Where(x => previousPlanIds.Contains(x.MealPlanId))
                    .Select(x => new { x.FoodId, x.RecipeId })
                    .ToListAsync();

                excludedFoodIds = usedItems.Where(x => x.FoodId.HasValue).Select(x => x.FoodId!.Value).Distinct().ToList();
                excludedRecipeIds = usedItems.Where(x => x.RecipeId.HasValue).Select(x => x.RecipeId!.Value).Distinct().ToList();
            }

            var activeFoodIds = await _db.Foods
                .AsNoTracking()
                .Where(x => x.IsActive == true && x.CaloriesKcal.HasValue && !excludedFoodIds.Contains(x.Id))
                .Select(x => x.Id)
                .ToListAsync();

            var activeRecipeIds = await _db.Recipes
                .AsNoTracking()
                .Where(x => x.IsActive == true && !excludedRecipeIds.Contains(x.Id))
                .Select(x => x.Id)
                .ToListAsync();

            if (activeFoodIds.Count + activeRecipeIds.Count < limit)
            {
                activeFoodIds = await _db.Foods
                    .AsNoTracking()
                    .Where(x => x.IsActive == true && x.CaloriesKcal.HasValue)
                    .Select(x => x.Id)
                    .ToListAsync();

                activeRecipeIds = await _db.Recipes
                    .AsNoTracking()
                    .Where(x => x.IsActive == true)
                    .Select(x => x.Id)
                    .ToListAsync();
            }

            var randomFoodIds = activeFoodIds.OrderBy(x => random.Next()).Take(30).ToList();
            var randomRecipeIds = activeRecipeIds.OrderBy(x => random.Next()).Take(30).ToList();

            var foods = await _db.Foods
                .AsNoTracking()
                .Where(x => randomFoodIds.Contains(x.Id))
                .ToListAsync();

            var recipes = await _db.Recipes
                .AsNoTracking()
                .Where(x => randomRecipeIds.Contains(x.Id))
                .ToListAsync();

            var itemsList = new List<RecommendationItemResponse>();

            foreach (var food in foods)
            {
                itemsList.Add(new RecommendationItemResponse
                {
                    Id = food.Id,
                    Name = food.NameVi ?? food.NameEn ?? "Món ăn",
                    Type = "Food",
                    CaloriesKcal = food.CaloriesKcal ?? 0,
                    ProteinG = food.ProteinG ?? 0,
                    CarbsG = food.CarbsG ?? 0,
                    FatG = food.FatG ?? 0,
                    EstimatedPriceVnd = food.EstimatedPriceVnd ?? 0,
                    CookingTimeMin = 5,
                    Score = (decimal)(7.0 + random.NextDouble() * 2.5),
                    Instructions = food.Description
                });
            }

            foreach (var recipe in recipes)
            {
                var calories = 450;
                try
                {
                    calories = await GetRecipeCaloriesAsync(recipe.Id);
                }
                catch { }

                itemsList.Add(new RecommendationItemResponse
                {
                    Id = recipe.Id,
                    Name = recipe.Title ?? "Công thức",
                    Type = "Recipe",
                    CaloriesKcal = calories,
                    ProteinG = 20,
                    CarbsG = 40,
                    FatG = 12,
                    EstimatedPriceVnd = recipe.EstimatedPriceVnd ?? 0,
                    CookingTimeMin = recipe.TotalTimeMin ?? recipe.CookTimeMin ?? 20,
                    Score = (decimal)(8.0 + random.NextDouble() * 1.5),
                    Instructions = recipe.Instructions
                });
            }

            var shuffledItems = itemsList
                .OrderBy(x => random.Next())
                .GroupBy(x => x.Id)
                .Select(g => g.First())
                .Take(limit)
                .ToList();

            return shuffledItems;
        }

        public async Task<UserAiProfileResponse> SavePreferenceAsync(Guid userId, UpdateUserAiProfileRequest request)
        {
            return await _userAiProfileService.UpsertAsync(userId, request);
        }

        private async Task<int> GetRecipeCaloriesAsync(Guid recipeId)
        {
            var recipeIngredients = await _db.RecipeIngredients
                .AsNoTracking()
                .Where(ri => ri.RecipeId == recipeId)
                .ToListAsync();
            decimal totalCalories = 0;

            foreach (var ri in recipeIngredients)
            {
                var ingredient = await _db.Ingredients.FindAsync(ri.IngredientId);
                if (ingredient != null && ingredient.CaloriesKcal.HasValue)
                {
                    var quantity = ri.Quantity ?? 1;
                    totalCalories += ingredient.CaloriesKcal.Value * quantity;
                }
            }

            return totalCalories > 0 ? (int)Math.Round(totalCalories) : 350;
        }
    }
}
