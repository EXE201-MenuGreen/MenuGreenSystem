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
    public class PremiumProgramService : IPremiumProgramService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly SepayQrUrlBuilder _qrUrlBuilder;

        public PremiumProgramService(IUnitOfWork unitOfWork, SepayQrUrlBuilder qrUrlBuilder)
        {
            _unitOfWork = unitOfWork;
            _qrUrlBuilder = qrUrlBuilder;
        }

        private async Task EnsureSeedDataAsync()
        {
            var count = (await _unitOfWork.PremiumPrograms.GetAllAsync()).Count();
            if (count > 0) return;

            var programs = new List<PremiumProgram>
            {
                new()
                {
                    Id = Guid.NewGuid(),
                    Title = "Lộ trình giảm cân 8 tuần (Weight Loss Masterclass)",
                    DurationWeeks = 8,
                    TargetCaloriesDaily = 1500,
                    GoalType = "LoseWeight",
                    PriceVnd = 299000,
                    Description = "Gói chương trình được thiết kế chuyên biệt để giúp bạn cắt giảm calo thông minh, duy trì cảm giác no lâu và giảm cân an toàn mà không làm giảm cơ bắp.",
                    SampleMenu = "Bữa sáng: Sinh tố bơ chuối cải xoăn (350kcal) | Bữa trưa: Ức gà nướng áp chảo kem mù tạt ăn kèm súp lơ luộc (600kcal) | Bữa tối: Cá hồi áp chảo sốt chanh leo và salad xà lách (550kcal)",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new()
                {
                    Id = Guid.NewGuid(),
                    Title = "Lộ trình tăng cơ 12 tuần (Muscle Building Accelerator)",
                    DurationWeeks = 12,
                    TargetCaloriesDaily = 2500,
                    GoalType = "GainMuscle",
                    PriceVnd = 499000,
                    Description = "Lộ trình giàu protein chất lượng cao và carb phức hợp giúp tối ưu hóa quá trình phục hồi, phát triển cơ bắp tối đa và nâng cao thể lực tập luyện.",
                    SampleMenu = "Bữa sáng: 3 trứng ốp la, 2 lát bánh mì đen và quả bơ (600kcal) | Bữa trưa: Bò lúc lắc ăn kèm cơm gạo lứt và măng tây xào tỏi (1000kcal) | Bữa tối: Tôm áp chảo sốt bơ tỏi và khoai lang luộc (900kcal)",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new()
                {
                    Id = Guid.NewGuid(),
                    Title = "Lộ trình ăn sạch lành mạnh 8 tuần (Clean Eating Blueprint)",
                    DurationWeeks = 8,
                    TargetCaloriesDaily = 1900,
                    GoalType = "HealthyEating",
                    PriceVnd = 199000,
                    Description = "Thực đơn dinh dưỡng lành mạnh tập trung vào thực phẩm toàn phần (whole foods), loại bỏ chất béo bão hòa có hại, đồ chế biến sẵn và đường tinh luyện.",
                    SampleMenu = "Bữa sáng: Cháo yến mạch ngâm sữa chua Hy Lạp và quả mọng (450kcal) | Bữa trưa: Salad cá ngừ đậu đỏ, cà chua bi và dầu oliu (750kcal) | Bữa tối: Đậu hũ kho nấm hương và đĩa rau củ luộc thập cẩm (700kcal)",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                }
            };

            foreach (var p in programs)
            {
                await _unitOfWork.PremiumPrograms.AddAsync(p);
            }
            await _unitOfWork.CompleteAsync();
        }

        public async Task<IEnumerable<PremiumProgramResponse>> GetActiveProgramsAsync()
        {
            await EnsureSeedDataAsync();
            var list = await _unitOfWork.PremiumPrograms.FindAsync(x => x.IsActive);
            return list.Select(MapToResponse).ToList();
        }

        public async Task<PremiumProgramResponse> GetProgramByIdAsync(Guid id)
        {
            await EnsureSeedDataAsync();
            var program = await _unitOfWork.PremiumPrograms.GetByIdAsync(id)
                ?? throw new Exception("Premium program not found.");
            return MapToResponse(program);
        }

        public async Task<SepayOrderResponse> PurchaseProgramAsync(Guid userId, Guid programId)
        {
            await EnsureSeedDataAsync();
            var program = await _unitOfWork.PremiumPrograms.GetByIdAsync(programId)
                ?? throw new Exception("Premium program not found.");

            // Check if user already has an active program
            var currentActive = (await _unitOfWork.UserPremiumPrograms.FindAsync(
                x => x.UserId == userId && x.Status == "Active")).FirstOrDefault();
            if (currentActive != null)
            {
                throw new Exception("You have an active Premium program. Please complete your current program before starting a new one.");
            }

            // Check if there's already a pending purchase for this same program
            var existingPending = (await _unitOfWork.UserPremiumPrograms.FindAsync(
                x => x.UserId == userId && x.ProgramId == programId && x.Status == "PendingPayment")).FirstOrDefault();

            UserPremiumProgram userProgram;
            if (existingPending != null)
            {
                userProgram = existingPending;
            }
            else
            {
                userProgram = new UserPremiumProgram
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    ProgramId = programId,
                    Status = "PendingPayment",
                    CurrentWeek = 1,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.UserPremiumPrograms.AddAsync(userProgram);
                await _unitOfWork.CompleteAsync();
            }

            // Create a pending payment
            var orderCode = await GenerateUniqueOrderCodeAsync();
            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                UserPremiumProgramId = userProgram.Id,
                AmountVnd = program.PriceVnd,
                Status = "PENDING",
                PaymentMethod = "SEPAY",
                Provider = "SEPAY",
                ProviderOrderCode = orderCode,
                CreatedAt = DateTimeOffset.UtcNow,
                ExpiredAt = DateTimeOffset.UtcNow.AddMinutes(30)
            };

            await _unitOfWork.Payments.AddAsync(payment);
            await _unitOfWork.CompleteAsync();

            var qr = _qrUrlBuilder.Build(payment.AmountVnd, payment.ProviderOrderCode);

            return new SepayOrderResponse
            {
                PaymentId = payment.Id,
                UserSubscriptionId = Guid.Empty,
                UserPremiumProgramId = userProgram.Id,
                AmountVnd = payment.AmountVnd,
                Status = payment.Status,
                ProviderOrderCode = payment.ProviderOrderCode,
                TransferContent = payment.ProviderOrderCode,
                TransferMemo = qr.TransferMemo,
                QrImageUrl = qr.QrImageUrl,
                Receiver = new SepayReceiverInfo
                {
                    BankName = qr.Receiver.BankName,
                    AccountNumber = qr.Receiver.AccountNumber,
                    AccountHolderName = qr.Receiver.AccountHolderName
                },
                ExpiredAt = payment.ExpiredAt ?? payment.CreatedAt.AddMinutes(30)
            };
        }

        public async Task<UserPremiumProgramResponse> ActivateProgramAsync(Guid userId, Guid userProgramId, ProgramActivationRequest request)
        {
            var userProgram = await _unitOfWork.UserPremiumPrograms.GetByIdAsync(userProgramId)
                ?? throw new Exception("Program enrollment not found.");

            if (userProgram.UserId != userId)
            {
                throw new Exception("Invalid operation.");
            }

            if (userProgram.Status != "Paid" && userProgram.Status != "PendingPayment")
            {
                throw new Exception("This program has not been paid for or is already activated.");
            }

            var program = await _unitOfWork.PremiumPrograms.GetByIdAsync(userProgram.ProgramId)
                ?? throw new Exception("Program does not exist.");

            userProgram.Status = "Active";
            userProgram.StartDate = request.StartDate;
            userProgram.CurrentWeek = 1;
            userProgram.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.UserPremiumPrograms.Update(userProgram);

            // Generate milestones
            for (var w = 1; w <= program.DurationWeeks; w++)
            {
                var milestone = new UserProgramMilestone
                {
                    Id = Guid.NewGuid(),
                    UserProgramId = userProgram.Id,
                    WeekNumber = w,
                    IsUnlocked = w == 1,
                    IsCheckedIn = false,
                    UnlockedAt = w == 1 ? DateTime.UtcNow : null,
                    CreatedAt = DateTime.UtcNow
                };
                await _unitOfWork.UserProgramMilestones.AddAsync(milestone);
            }

            await _unitOfWork.CompleteAsync();

            // Automatically generate week 1 meal plan starting from the activation start date
            await GenerateWeeklyMealPlanAsync(userId, userProgram, 1, request.StartDate);

            return await MapToUserResponseAsync(userProgram);
        }

        public async Task<UserPremiumProgramResponse?> GetMyActiveProgramAsync(Guid userId)
        {
            var currentActive = (await _unitOfWork.UserPremiumPrograms.FindAsync(
                x => x.UserId == userId && x.Status == "Active")).FirstOrDefault();
            if (currentActive == null) return null;
            return await MapToUserResponseAsync(currentActive);
        }

        public async Task<IEnumerable<UserPremiumProgramResponse>> GetMyProgramsAsync(Guid userId)
        {
            var list = await _unitOfWork.UserPremiumPrograms.FindAsync(x => x.UserId == userId);
            var result = new List<UserPremiumProgramResponse>();
            foreach (var item in list)
            {
                result.Add(await MapToUserResponseAsync(item));
            }
            return result.OrderByDescending(x => x.CreatedAt);
        }

        public async Task<IEnumerable<UserProgramMilestoneResponse>> GetMyActiveMilestonesAsync(Guid userId)
        {
            var active = await GetMyActiveProgramAsync(userId);
            if (active == null)
            {
                throw new Exception("You do not have any active Premium program.");
            }
            return active.Milestones;
        }

        public async Task<UserPremiumProgramResponse> CheckInWeekAsync(Guid userId, int weekNumber, ProgramCheckInRequest request)
        {
            var activeProgram = (await _unitOfWork.UserPremiumPrograms.FindAsync(
                p => p.UserId == userId && p.Status == "Active")).FirstOrDefault()
                ?? throw new Exception("You do not have any active Premium program.");

            if (activeProgram.CurrentWeek != weekNumber)
            {
                throw new Exception($"Week {weekNumber} check-in request does not match the current week ({activeProgram.CurrentWeek}).");
            }

            var milestone = (await _unitOfWork.UserProgramMilestones.FindAsync(
                m => m.UserProgramId == activeProgram.Id && m.WeekNumber == weekNumber)).FirstOrDefault()
                ?? throw new Exception($"Milestone for week {weekNumber} not found.");

            if (milestone.IsCheckedIn)
            {
                throw new Exception($"Week {weekNumber} has already been checked in.");
            }

            var program = await _unitOfWork.PremiumPrograms.GetByIdAsync(activeProgram.ProgramId)
                ?? throw new Exception("Original program details not found.");

            // Update milestone
            milestone.WeightKg = request.WeightKg;
            milestone.BodyFatPercent = request.BodyFatPercent;
            milestone.IsCheckedIn = true;
            milestone.CheckInDate = DateTime.UtcNow;
            _unitOfWork.UserProgramMilestones.Update(milestone);

            // Log user weight and body fat to WeightLogs
            var weightLog = new WeightLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                WeightKg = request.WeightKg,
                BodyFatPercent = request.BodyFatPercent,
                RecordedAt = DateTime.UtcNow
            };
            await _unitOfWork.WeightLogs.AddAsync(weightLog);

            // Unlock next week if available
            if (activeProgram.CurrentWeek < program.DurationWeeks)
            {
                var nextWeek = activeProgram.CurrentWeek + 1;
                var nextMilestone = (await _unitOfWork.UserProgramMilestones.FindAsync(
                    m => m.UserProgramId == activeProgram.Id && m.WeekNumber == nextWeek)).FirstOrDefault();
                
                if (nextMilestone != null)
                {
                    nextMilestone.IsUnlocked = true;
                    nextMilestone.UnlockedAt = DateTime.UtcNow;
                    _unitOfWork.UserProgramMilestones.Update(nextMilestone);
                }

                activeProgram.CurrentWeek = nextWeek;
                activeProgram.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.UserPremiumPrograms.Update(activeProgram);

                // Auto-generate Meal Plan for the next week
                var nextWeekStartDate = activeProgram.StartDate!.Value.AddDays((nextWeek - 1) * 7);
                await GenerateWeeklyMealPlanAsync(userId, activeProgram, nextWeek, nextWeekStartDate);
            }

            await _unitOfWork.CompleteAsync();
            return await MapToUserResponseAsync(activeProgram);
        }

        public async Task<List<MilestoneWeightProgress>> GetMyActiveProgressTrendAsync(Guid userId)
        {
            var active = (await _unitOfWork.UserPremiumPrograms.FindAsync(
                p => p.UserId == userId && p.Status == "Active")).FirstOrDefault()
                ?? throw new Exception("You do not have any active Premium program.");

            var milestones = await _unitOfWork.UserProgramMilestones.FindAsync(
                m => m.UserProgramId == active.Id);

            return milestones
                .OrderBy(m => m.WeekNumber)
                .Select(m => new MilestoneWeightProgress
                {
                    WeekNumber = m.WeekNumber,
                    WeightKg = m.WeightKg,
                    BodyFatPercent = m.BodyFatPercent,
                    CheckInDate = m.CheckInDate
                })
                .ToList();
        }

        public async Task<UserPremiumProgramResponse> GraduateActiveProgramAsync(Guid userId)
        {
            var active = (await _unitOfWork.UserPremiumPrograms.FindAsync(
                p => p.UserId == userId && p.Status == "Active")).FirstOrDefault()
                ?? throw new Exception("You do not have any active Premium program.");

            var program = await _unitOfWork.PremiumPrograms.GetByIdAsync(active.ProgramId)
                ?? throw new Exception("Program does not exist.");

            var milestones = await _unitOfWork.UserProgramMilestones.FindAsync(
                m => m.UserProgramId == active.Id);

            var list = milestones.ToList();
            if (list.Count < program.DurationWeeks || list.Any(m => !m.IsCheckedIn))
            {
                throw new Exception("You need to check in for all weeks to graduate from the program.");
            }

            active.Status = "Completed";
            active.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.UserPremiumPrograms.Update(active);
            await _unitOfWork.CompleteAsync();

            return await MapToUserResponseAsync(active);
        }

        public async Task<ProgramReportResponse> GetMyProgramReportAsync(Guid userId, Guid userProgramId)
        {
            var userProgram = await _unitOfWork.UserPremiumPrograms.GetByIdAsync(userProgramId)
                ?? throw new Exception("Subscription program registration details not found.");

            if (userProgram.UserId != userId)
            {
                throw new Exception("You do not have permission to access this report.");
            }

            var program = await _unitOfWork.PremiumPrograms.GetByIdAsync(userProgram.ProgramId)
                ?? throw new Exception("The original program has been deleted.");

            var milestones = (await _unitOfWork.UserProgramMilestones.FindAsync(
                m => m.UserProgramId == userProgram.Id)).OrderBy(m => m.WeekNumber).ToList();

            var startWeight = milestones.FirstOrDefault(m => m.IsCheckedIn)?.WeightKg;
            var endWeight = milestones.LastOrDefault(m => m.IsCheckedIn)?.WeightKg;
            var weightChange = (startWeight.HasValue && endWeight.HasValue) ? (endWeight.Value - startWeight.Value) : (decimal?)null;

            var startFat = milestones.FirstOrDefault(m => m.IsCheckedIn)?.BodyFatPercent;
            var endFat = milestones.LastOrDefault(m => m.IsCheckedIn)?.BodyFatPercent;
            var fatChange = (startFat.HasValue && endFat.HasValue) ? (endFat.Value - startFat.Value) : (decimal?)null;

            // Compliance rate calculation
            var mealPlanHeaders = await _unitOfWork.MealPlanHeaders.FindAsync(
                h => h.UserId == userId && h.GeneratedBy == "PREMIUM_PROGRAM");
            
            var headerIds = mealPlanHeaders.Select(h => h.Id).ToList();
            double adherence = 100.0;

            if (headerIds.Any())
            {
                var mealItems = await _unitOfWork.MealPlanItems.FindAsync(
                    i => headerIds.Contains(i.MealPlanId));
                
                var itemsList = mealItems.ToList();
                if (itemsList.Any())
                {
                    var completed = itemsList.Count(i => i.IsCompleted);
                    adherence = Math.Round((double)completed / itemsList.Count * 100.0, 2);
                }
            }

            return new ProgramReportResponse
            {
                UserProgramId = userProgram.Id,
                ProgramTitle = program.Title,
                TotalWeeks = program.DurationWeeks,
                Status = userProgram.Status,
                StartDate = userProgram.StartDate,
                StartWeight = startWeight,
                EndWeight = endWeight,
                WeightChange = weightChange,
                StartBodyFat = startFat,
                EndBodyFat = endFat,
                BodyFatChange = fatChange,
                AverageAdherenceRate = adherence,
                ProgressTrend = milestones.Select(m => new MilestoneWeightProgress
                {
                    WeekNumber = m.WeekNumber,
                    WeightKg = m.WeightKg,
                    BodyFatPercent = m.BodyFatPercent,
                    CheckInDate = m.CheckInDate
                }).ToList()
            };
        }

        private async Task GenerateWeeklyMealPlanAsync(Guid userId, UserPremiumProgram userProgram, int weekNumber, DateOnly startDate)
        {
            var program = await _unitOfWork.PremiumPrograms.GetByIdAsync(userProgram.ProgramId)
                ?? throw new Exception("Program does not exist.");

            var mealPlanHeader = new MealPlanHeader
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = $"{program.Title} - Tuần {weekNumber}",
                PlanType = "weekly",
                StartDate = startDate,
                EndDate = startDate.AddDays(6),
                TargetCalories = program.TargetCaloriesDaily,
                GeneratedBy = "PREMIUM_PROGRAM",
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MealPlanHeaders.AddAsync(mealPlanHeader);
            await _unitOfWork.CompleteAsync();

            var allFoods = (await _unitOfWork.Foods.GetAllAsync()).Where(f => f.IsActive == true || f.IsActive == null).ToList();
            var allRecipes = (await _unitOfWork.Recipes.GetAllAsync()).Where(r => r.IsActive == true || r.IsActive == null).ToList();

            var foodMap = allFoods.ToDictionary(f => f.Id, f => f);
            var random = new Random();

            for (var d = 0; d < 7; d++)
            {
                var currentDate = startDate.AddDays(d);
                var mealTypes = new[] { "breakfast", "lunch", "dinner" };

                var breakfastCal = (decimal)(program.TargetCaloriesDaily * 0.25);
                var lunchCal = (decimal)(program.TargetCaloriesDaily * 0.40);
                var dinnerCal = (decimal)(program.TargetCaloriesDaily * 0.35);

                foreach (var mealType in mealTypes)
                {
                    var targetCal = mealType == "breakfast" ? breakfastCal : (mealType == "lunch" ? lunchCal : dinnerCal);
                    
                    var candidateRecipes = allRecipes
                        .Where(r => r.MealType != null && r.MealType.Contains(mealType, StringComparison.OrdinalIgnoreCase))
                        .ToList();

                    Guid? recipeId = null;
                    Guid? foodId = null;
                    int selectedCalories = (int)targetCal;

                    if (candidateRecipes.Any())
                    {
                        var ordered = candidateRecipes
                            .OrderBy(r => {
                                var recipeCal = (r.FoodId.HasValue && foodMap.TryGetValue(r.FoodId.Value, out var f)) ? (f.CaloriesKcal ?? 500m) : 500m;
                                return Math.Abs(recipeCal - targetCal);
                            })
                            .Take(5)
                            .ToList();
                        var selectedRecipe = ordered[random.Next(ordered.Count)];
                        recipeId = selectedRecipe.Id;
                        var finalCal = (selectedRecipe.FoodId.HasValue && foodMap.TryGetValue(selectedRecipe.FoodId.Value, out var f2)) ? (f2.CaloriesKcal ?? targetCal) : targetCal;
                        selectedCalories = (int)finalCal;
                    }
                    else
                    {
                        var candidateFoods = allFoods
                            .OrderBy(f => Math.Abs((f.CaloriesKcal ?? 300m) - targetCal))
                            .Take(10)
                            .ToList();
                        if (candidateFoods.Any())
                        {
                            var selectedFood = candidateFoods[random.Next(candidateFoods.Count)];
                            foodId = selectedFood.Id;
                            selectedCalories = (int)(selectedFood.CaloriesKcal ?? targetCal);
                        }
                    }

                    var item = new MealPlanItem
                    {
                        Id = Guid.NewGuid(),
                        MealPlanId = mealPlanHeader.Id,
                        MealType = mealType,
                        FoodId = foodId,
                        RecipeId = recipeId,
                        PlannedDate = currentDate,
                        ScheduledTime = mealType == "breakfast" ? new TimeOnly(7, 30) : (mealType == "lunch" ? new TimeOnly(12, 0) : new TimeOnly(18, 30)),
                        TargetCalories = selectedCalories,
                        IsCompleted = false,
                        CreatedAt = DateTime.UtcNow
                    };

                    await _unitOfWork.MealPlanItems.AddAsync(item);
                }
            }

            await _unitOfWork.CompleteAsync();
        }

        private async Task<string> GenerateUniqueOrderCodeAsync()
        {
            var random = new Random();
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            while (true)
            {
                var suffix = new string(Enumerable.Repeat(chars, 8).Select(s => s[random.Next(s.Length)]).ToArray());
                var code = $"PRM{suffix}";
                var existing = await _unitOfWork.Payments.FindAsync(p => p.ProviderOrderCode == code);
                if (!existing.Any())
                {
                    return code;
                }
            }
        }

        private PremiumProgramResponse MapToResponse(PremiumProgram p)
        {
            return new PremiumProgramResponse
            {
                Id = p.Id,
                Title = p.Title,
                Description = p.Description,
                DurationWeeks = p.DurationWeeks,
                TargetCaloriesDaily = p.TargetCaloriesDaily,
                GoalType = p.GoalType,
                PriceVnd = p.PriceVnd,
                SampleMenu = p.SampleMenu,
                IsActive = p.IsActive,
                CreatedAt = p.CreatedAt
            };
        }

        private async Task<UserPremiumProgramResponse> MapToUserResponseAsync(UserPremiumProgram up)
        {
            var program = await _unitOfWork.PremiumPrograms.GetByIdAsync(up.ProgramId);
            var milestones = await _unitOfWork.UserProgramMilestones.FindAsync(m => m.UserProgramId == up.Id);

            return new UserPremiumProgramResponse
            {
                Id = up.Id,
                UserId = up.UserId,
                ProgramId = up.ProgramId,
                ProgramTitle = program?.Title ?? string.Empty,
                StartDate = up.StartDate,
                Status = up.Status,
                CurrentWeek = up.CurrentWeek,
                CreatedAt = up.CreatedAt,
                Milestones = milestones.OrderBy(m => m.WeekNumber).Select(m => new UserProgramMilestoneResponse
                {
                    Id = m.Id,
                    WeekNumber = m.WeekNumber,
                    IsUnlocked = m.IsUnlocked,
                    IsCheckedIn = m.IsCheckedIn,
                    WeightKg = m.WeightKg,
                    BodyFatPercent = m.BodyFatPercent,
                    CheckInDate = m.CheckInDate,
                    UnlockedAt = m.UnlockedAt
                }).ToList()
            };
        }
    }
}
