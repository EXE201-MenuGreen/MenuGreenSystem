using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class LuckyWheelService : ILuckyWheelService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ApplicationDbContext _db;
        private readonly IAllergenMatchingService _allergenMatchingService;
        private readonly IUserAiProfileService _userAiProfileService;
        private readonly IHealthProfileService _healthProfileService;

        public LuckyWheelService(
            IUnitOfWork unitOfWork,
            ApplicationDbContext db,
            IAllergenMatchingService allergenMatchingService,
            IUserAiProfileService userAiProfileService,
            IHealthProfileService healthProfileService)
        {
            _unitOfWork = unitOfWork;
            _db = db;
            _allergenMatchingService = allergenMatchingService;
            _userAiProfileService = userAiProfileService;
            _healthProfileService = healthProfileService;
        }

        public async Task<IEnumerable<FoodResponse>> GetWheelFoodsAsync(Guid userId)
        {
            // 1. Get user preferences & profile info
            var aiProfile = await _userAiProfileService.GetAsync(userId);
            var budget = aiProfile?.BudgetPerMealVnd ?? int.MaxValue;
            var preferredRegion = aiProfile?.VietnamRegion?.Trim().ToLowerInvariant();

            // Extract liked keywords from AI preferences JSON if available
            var likedKeywords = new List<string>();
            if (aiProfile != null && !string.IsNullOrEmpty(aiProfile.Preferences))
            {
                try
                {
                    using var doc = JsonDocument.Parse(aiProfile.Preferences);
                    if (doc.RootElement.TryGetProperty("eatingPreferences", out var eatProp))
                    {
                        if (eatProp.ValueKind == JsonValueKind.Array)
                        {
                            likedKeywords.AddRange(eatProp.EnumerateArray().Select(x => x.GetString() ?? "").Where(s => !string.IsNullOrEmpty(s)));
                        }
                        else if (eatProp.ValueKind == JsonValueKind.String)
                        {
                            likedKeywords.AddRange(eatProp.GetString()!.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
                        }
                    }
                }
                catch
                {
                    // ignore parse errors
                }
            }

            // 2. Fetch user allergen keys
            var userKeys = await _allergenMatchingService.GetUserAllergenKeysAsync(userId);

            // 3. Get all active foods
            var allFoods = await _db.Foods.AsNoTracking().Where(f => f.IsActive != false).ToListAsync();
            var foodIds = allFoods.Select(f => f.Id).ToList();
            var foodAllergenMap = await _allergenMatchingService.GetFoodAllergenKeysAsync(foodIds);

            // 4. Score and filter candidates
            var scoredCandidates = new List<(Food Food, int Score, HashSet<string> FoodAllergens)>();
            foreach (var food in allFoods)
            {
                foodAllergenMap.TryGetValue(food.Id, out var allergens);
                allergens ??= new HashSet<string>(StringComparer.OrdinalIgnoreCase);

                // Exclude if it contains any user allergen
                if (userKeys.Any(uk => allergens.Contains(uk)))
                {
                    continue;
                }

                int score = 0;

                // Match Budget
                if (food.EstimatedPriceVnd.HasValue && food.EstimatedPriceVnd.Value <= budget)
                {
                    score += 10;
                }

                // Match Region
                if (!string.IsNullOrEmpty(food.Region) && !string.IsNullOrEmpty(preferredRegion))
                {
                    if (food.Region.Trim().ToLowerInvariant().Contains(preferredRegion))
                    {
                        score += 15;
                    }
                }

                // Match Liked keywords in name
                if (likedKeywords.Count > 0 && !string.IsNullOrEmpty(food.NameVi))
                {
                    var nameLower = food.NameVi.ToLowerInvariant();
                    if (likedKeywords.Any(kw => nameLower.Contains(kw.ToLowerInvariant())))
                    {
                        score += 20;
                    }
                }

                scoredCandidates.Add((food, score, allergens));
            }

            // 5. Select 10 distinct foods randomly from the top 30 candidates
            var topCandidates = scoredCandidates
                .OrderByDescending(c => c.Score)
                .Take(30)
                .ToList();

            if (topCandidates.Count == 0)
            {
                // Fallback: just take some active foods if no candidates matched filters
                topCandidates = allFoods.Select(f => (f, 0, new HashSet<string>())).Take(15).ToList();
            }

            var rand = new Random();
            var selectedList = topCandidates
                .OrderBy(_ => rand.Next())
                .Take(10)
                .ToList();

            // 6. Map to FoodResponse
            return selectedList.Select(item =>
            {
                var dto = new FoodResponse
                {
                    Id = item.Food.Id,
                    NameVi = item.Food.NameVi,
                    NameEn = item.Food.NameEn,
                    Category = item.Food.Category,
                    Description = item.Food.Description,
                    CaloriesKcal = item.Food.CaloriesKcal,
                    ProteinG = item.Food.ProteinG,
                    CarbsG = item.Food.CarbsG,
                    FatG = item.Food.FatG,
                    FiberG = item.Food.FiberG,
                    EstimatedPriceVnd = item.Food.EstimatedPriceVnd,
                    DefaultServingG = item.Food.DefaultServingG,
                    ImageUrl = item.Food.ImageUrl,
                    IsActive = item.Food.IsActive,
                    AllergenKeys = item.FoodAllergens.OrderBy(k => k).ToList(),
                    AllergenLabelsVi = AllergenCatalog.ToDisplayNamesVi(item.FoodAllergens).ToList()
                };

                var matchedKeys = item.FoodAllergens.Where(userKeys.Contains).ToList();
                dto.MatchedAllergens = AllergenCatalog.ToDisplayNamesVi(matchedKeys).ToList();
                dto.AllergyRiskLevel = matchedKeys.Count > 0 ? AllergenCatalog.RiskHigh : AllergenCatalog.RiskNone;
                dto.IsSafeForUser = AllergenCatalog.IsSafeForUser(dto.AllergyRiskLevel);
                return dto;
            }).ToList();
        }

        public async Task ApplyWheelSelectionAsync(Guid userId, Guid foodId, string mealType)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow.AddHours(7)); // Vietnam time zone
            
            // 1. Find or create today's meal plan header
            var plans = await _unitOfWork.MealPlanHeaders.FindAsync(p => 
                p.UserId == userId 
                && p.PlanType == "DAILY" 
                && p.StartDate == today 
                && p.IsActive);
            var plan = plans.FirstOrDefault();

            if (plan == null)
            {
                var health = await _healthProfileService.GetAsync(userId);
                plan = new MealPlanHeader
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Title = $"Daily plan {today:yyyy-MM-dd}",
                    PlanType = "DAILY",
                    StartDate = today,
                    EndDate = today,
                    TargetCalories = health?.TargetCalories ?? 2000,
                    GeneratedBy = "USER",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.MealPlanHeaders.AddAsync(plan);
                await _unitOfWork.CompleteAsync();
            }

            // 2. Add selected Food to MealPlanItem
            var item = new MealPlanItem
            {
                Id = Guid.NewGuid(),
                MealPlanId = plan.Id,
                MealType = string.IsNullOrEmpty(mealType) ? "Snack" : mealType,
                FoodId = foodId,
                PlannedDate = today,
                ScheduledTime = new TimeOnly(12, 0),
                IsCompleted = false,
                CreatedAt = DateTime.UtcNow
            };

            await _db.MealPlanItems.AddAsync(item);
            await _unitOfWork.CompleteAsync();
        }
    }
}
