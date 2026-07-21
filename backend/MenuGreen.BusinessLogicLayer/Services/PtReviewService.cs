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
    public class PtReviewService : IPtReviewService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IPlannedVsActualService _plannedVsActualService;
        private readonly NotiServiceWrapper _notificationService;

        public PtReviewService(
            IUnitOfWork unitOfWork,
            IPlannedVsActualService plannedVsActualService,
            INotificationService notificationService)
        {
            _unitOfWork = unitOfWork;
            _plannedVsActualService = plannedVsActualService;
            // Wrapped because INotificationService is injected and we can cast it
            _notificationService = new NotiServiceWrapper(notificationService);
        }

        public async Task<CreatePtReviewReportResponse> CreateReportAsync(Guid userId, CreatePtReviewReportRequest request)
        {
            // 0. Check connection with PT
            var connections = await _unitOfWork.CoachConnections.FindAsync(c =>
                c.ClientId == userId && c.Status == "Connected");
            if (!connections.Any())
            {
                throw new Exception("Bạn chưa Đăng ký kết nối với PT");
            }

            var weekStartDate = request.WeekStartDate;
            var weekEndDate = weekStartDate.AddDays(6);

            // 1. Load Health Profile
            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId);
            var healthProfile = healthProfiles.FirstOrDefault();
            var healthProfileSnapshot = new HealthProfileSnapshot();
            if (healthProfile != null)
            {
                healthProfileSnapshot.HeightCm = healthProfile.HeightCm;
                healthProfileSnapshot.WeightKg = healthProfile.WeightKg;
                healthProfileSnapshot.ActivityLevel = healthProfile.ActivityLevel;
                healthProfileSnapshot.Goal = healthProfile.Goal;
                healthProfileSnapshot.TargetCalories = healthProfile.TargetCalories;
                healthProfileSnapshot.TargetProteinG = healthProfile.TargetProteinG;
                healthProfileSnapshot.TargetCarbsG = healthProfile.TargetCarbsG;
                healthProfileSnapshot.TargetFatG = healthProfile.TargetFatG;
            }

            // 2. Fetch planned vs actual summaries
            var summary = await _plannedVsActualService.GetSummaryAsync(userId, weekStartDate, weekEndDate);
            var score = await _plannedVsActualService.GetAdherenceScoreAsync(userId, weekStartDate, weekEndDate);
            var drift = await _plannedVsActualService.GetDriftAnalysisAsync(userId, weekStartDate, weekEndDate);

            // 3. Fetch weight logs
            var startDateTime = weekStartDate.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc);
            var endDateTime = weekEndDate.ToDateTime(TimeOnly.MaxValue, DateTimeKind.Utc);
            var weightLogs = await _unitOfWork.WeightLogs.FindAsync(w => w.UserId == userId && w.RecordedAt >= startDateTime && w.RecordedAt <= endDateTime);
            var weightLogsList = weightLogs.Select(w => new WeightLogSnapshot
            {
                WeightKg = w.WeightKg,
                BodyFatPercent = w.BodyFatPercent,
                RecordedAt = w.RecordedAt
            }).ToList();

            // 4. Load daily meals details (planned and actual)
            var plans = await _unitOfWork.MealPlanHeaders.FindAsync(h => h.UserId == userId && h.StartDate >= weekStartDate && h.StartDate <= weekEndDate);
            var planIds = plans.Select(p => p.Id).ToList();
            var planItems = planIds.Any()
                ? (await _unitOfWork.MealPlanItems.FindAsync(i => planIds.Contains(i.MealPlanId))).ToList()
                : new List<MealPlanItem>();

            var mealLogs = (await _unitOfWork.MealLogs.FindAsync(l => l.UserId == userId && l.LoggedAt >= startDateTime && l.LoggedAt <= endDateTime)).ToList();

            var foodIds = planItems.Where(i => i.FoodId.HasValue).Select(i => i.FoodId!.Value)
                .Concat(mealLogs.Where(l => l.FoodId.HasValue).Select(l => l.FoodId!.Value))
                .Distinct()
                .ToList();
            var recipeIds = planItems.Where(i => i.RecipeId.HasValue).Select(i => i.RecipeId!.Value)
                .Concat(mealLogs.Where(l => l.RecipeId.HasValue).Select(l => l.RecipeId!.Value))
                .Distinct()
                .ToList();

            var foods = foodIds.Any()
                ? (await _unitOfWork.Foods.FindAsync(f => foodIds.Contains(f.Id))).ToDictionary(f => f.Id)
                : new Dictionary<Guid, Food>();

            var recipes = recipeIds.Any()
                ? (await _unitOfWork.Recipes.FindAsync(r => recipeIds.Contains(r.Id))).ToDictionary(r => r.Id)
                : new Dictionary<Guid, Recipe>();

            var dailyMeals = new List<DailyMealsSnapshot>();
            for (int i = 0; i < 7; i++)
            {
                var currentDate = weekStartDate.AddDays(i);
                var dayMeals = new DailyMealsSnapshot { Date = currentDate };

                // Planned Items for this day
                var itemsForDay = planItems.Where(item => item.PlannedDate == currentDate).ToList();
                foreach (var item in itemsForDay)
                {
                    foods.TryGetValue(item.FoodId ?? Guid.Empty, out var food);
                    recipes.TryGetValue(item.RecipeId ?? Guid.Empty, out var recipe);

                    dayMeals.PlannedItems.Add(new MealPlanItemSnapshot
                    {
                        Id = item.Id,
                        MealType = item.MealType ?? "snack",
                        FoodId = item.FoodId,
                        FoodName = food?.NameVi,
                        RecipeId = item.RecipeId,
                        RecipeName = recipe?.Title,
                        TargetCalories = item.TargetCalories,
                        IsCompleted = item.IsCompleted
                    });
                }

                // Actual Logs for this day
                var logsForDay = mealLogs.Where(log => log.LoggedAt.HasValue && DateOnly.FromDateTime(log.LoggedAt.Value) == currentDate).ToList();
                foreach (var log in logsForDay)
                {
                    foods.TryGetValue(log.FoodId ?? Guid.Empty, out var food);
                    recipes.TryGetValue(log.RecipeId ?? Guid.Empty, out var recipe);

                    dayMeals.ActualLogs.Add(new MealLogSnapshot
                    {
                        Id = log.Id,
                        MealType = log.MealType ?? "snack",
                        FoodId = log.FoodId,
                        FoodName = food?.NameVi,
                        RecipeId = log.RecipeId,
                        RecipeName = recipe?.Title,
                        CaloriesKcal = log.CaloriesKcal,
                        QuantityG = log.QuantityG,
                        Notes = log.Notes,
                        LoggedAt = log.LoggedAt
                    });
                }

                dailyMeals.Add(dayMeals);
            }

            var snapshot = new WeeklyReportSnapshot
            {
                RequestType = request.RequestType ?? "WeeklyReport",
                WeekStartDate = weekStartDate,
                StudentNote = request.StudentNote ?? string.Empty,
                CheckInWeight = request.CheckInWeight,
                CheckInBodyFat = request.CheckInBodyFat,
                TrainingDaysCount = request.TrainingDaysCount,
                BodyFeeling = request.BodyFeeling ?? string.Empty,
                StudentHealthProfile = healthProfileSnapshot,
                NutritionSummary = summary,
                AdherenceScore = score,
                DriftAnalysis = drift,
                WeightLogs = weightLogsList,
                DailyMeals = dailyMeals
            };

            var reportId = Guid.NewGuid();
            var token = Guid.NewGuid().ToString("N");
            var expiresAt = DateTime.UtcNow.AddDays(request.ExpirationDays);

            var ptReviewRequest = new PtReviewRequest
            {
                Id = reportId,
                UserId = userId,
                WeekStartDate = weekStartDate,
                ReviewToken = token,
                ExpiresAt = expiresAt,
                Status = "Pending",
                CreatedAt = DateTime.UtcNow,
                ReportDataJson = System.Text.Json.JsonSerializer.Serialize(snapshot, new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                })
            };

            await _unitOfWork.PtReviewRequests.AddAsync(ptReviewRequest);
            await _unitOfWork.CompleteAsync();

            try
            {
                await _notificationService.SendAsync(new NotificationSendRequest
                {
                    UserId = userId,
                    Type = "PT_REVIEW_SUBMITTED",
                    Title = "Đã gửi lộ trình cho PT",
                    Body = "Lộ trình ăn uống của bạn đã được gửi thành công đến PT. Đang chờ phản hồi."
                });
            }
            catch
            {
                // Silence notification failure
            }

            var shareLink = $"https://menugreen.vn/shared-report/{token}";

            return new CreatePtReviewReportResponse
            {
                ReportId = reportId,
                ShareLink = shareLink,
                Token = token,
                ExpiresAt = expiresAt
            };
        }

        public async Task<PtReviewRequestDetailResponse> GetSharedReportAsync(string token)
        {
            var requests = await _unitOfWork.PtReviewRequests.FindAsync(x => x.ReviewToken == token);
            var request = requests.FirstOrDefault() ?? throw new Exception("Review request does not exist or token is invalid.");

            if (request.ExpiresAt < DateTime.UtcNow)
            {
                throw new Exception("Link has expired.");
            }

            var user = await _unitOfWork.Users.GetByIdAsync(request.UserId);
            var profile = user != null ? await _unitOfWork.Profiles.GetByIdAsync(request.UserId) : null;
            var studentName = profile?.FullName ?? user?.Email ?? "Student";

            var reportData = System.Text.Json.JsonSerializer.Deserialize<WeeklyReportSnapshot>(request.ReportDataJson, new System.Text.Json.JsonSerializerOptions
            {
                PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
            });

            var suggestedChanges = new List<PtSuggestedChangeDto>();
            if (!string.IsNullOrEmpty(request.SuggestedChangesJson))
            {
                suggestedChanges = System.Text.Json.JsonSerializer.Deserialize<List<PtSuggestedChangeDto>>(request.SuggestedChangesJson, new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                }) ?? new List<PtSuggestedChangeDto>();
            }

            return new PtReviewRequestDetailResponse
            {
                ReportId = request.Id,
                StudentName = studentName,
                WeekStartDate = request.WeekStartDate,
                ExpiresAt = request.ExpiresAt,
                Status = request.Status,
                CreatedAt = request.CreatedAt,
                PtComment = request.PtComment ?? string.Empty,
                SuggestedCalorieTarget = request.SuggestedCalorieTarget,
                SuggestedProteinTarget = request.SuggestedProteinTarget,
                SuggestedChanges = suggestedChanges,
                ReportData = reportData,
                ReviewedAt = request.ReviewedAt,
                ActionedAt = request.ActionedAt,
                ReviewToken = request.ReviewToken,
                RequestType = reportData?.RequestType ?? ""
            };
        }

        public async Task<IEnumerable<PtReviewRequestDetailResponse>> GetMyRequestsAsync(Guid userId)
        {
            var requests = await _unitOfWork.PtReviewRequests.FindAsync(x => x.UserId == userId);
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            var profile = user != null ? await _unitOfWork.Profiles.GetByIdAsync(userId) : null;
            var studentName = profile?.FullName ?? user?.Email ?? "Student";

            var list = new List<PtReviewRequestDetailResponse>();
            foreach (var req in requests.OrderByDescending(r => r.CreatedAt))
            {
                var suggestedChanges = new List<PtSuggestedChangeDto>();
                if (!string.IsNullOrEmpty(req.SuggestedChangesJson))
                {
                    suggestedChanges = System.Text.Json.JsonSerializer.Deserialize<List<PtSuggestedChangeDto>>(req.SuggestedChangesJson, new System.Text.Json.JsonSerializerOptions
                    {
                        PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                    }) ?? new List<PtSuggestedChangeDto>();
                }

                string requestType = "";
                decimal? checkInWeight = null;
                decimal? checkInBodyFat = null;
                int? trainingDaysCount = null;
                string? bodyFeeling = null;
                string? studentNote = null;
                try
                {
                    if (!string.IsNullOrEmpty(req.ReportDataJson))
                    {
                        using var doc = System.Text.Json.JsonDocument.Parse(req.ReportDataJson);
                        if (doc.RootElement.TryGetProperty("requestType", out var prop))
                        {
                            requestType = prop.GetString() ?? "";
                        }
                        if (doc.RootElement.TryGetProperty("checkInWeight", out var wProp) && wProp.ValueKind != System.Text.Json.JsonValueKind.Null)
                        {
                            checkInWeight = wProp.GetDecimal();
                        }
                        if (doc.RootElement.TryGetProperty("checkInBodyFat", out var bfProp) && bfProp.ValueKind != System.Text.Json.JsonValueKind.Null)
                        {
                            checkInBodyFat = bfProp.GetDecimal();
                        }
                        if (doc.RootElement.TryGetProperty("trainingDaysCount", out var tdProp) && tdProp.ValueKind != System.Text.Json.JsonValueKind.Null)
                        {
                            trainingDaysCount = tdProp.GetInt32();
                        }
                        if (doc.RootElement.TryGetProperty("bodyFeeling", out var fProp) && fProp.ValueKind != System.Text.Json.JsonValueKind.Null)
                        {
                            bodyFeeling = fProp.GetString();
                        }
                        if (doc.RootElement.TryGetProperty("studentNote", out var nProp) && nProp.ValueKind != System.Text.Json.JsonValueKind.Null)
                        {
                            studentNote = nProp.GetString();
                        }
                    }
                }
                catch {}

                list.Add(new PtReviewRequestDetailResponse
                {
                    ReportId = req.Id,
                    StudentName = studentName,
                    WeekStartDate = req.WeekStartDate,
                    ExpiresAt = req.ExpiresAt,
                    Status = req.Status,
                    CreatedAt = req.CreatedAt,
                    PtComment = req.PtComment ?? string.Empty,
                    SuggestedCalorieTarget = req.SuggestedCalorieTarget,
                    SuggestedProteinTarget = req.SuggestedProteinTarget,
                    SuggestedChanges = suggestedChanges,
                    ReportData = null, // Skip heavy report details in list view
                    ReviewedAt = req.ReviewedAt,
                    ActionedAt = req.ActionedAt,
                    ReviewToken = req.ReviewToken,
                    RequestType = requestType,
                    CheckInWeight = checkInWeight,
                    CheckInBodyFat = checkInBodyFat,
                    TrainingDaysCount = trainingDaysCount,
                    BodyFeeling = bodyFeeling,
                    StudentNote = studentNote
                });
            }

            return list;
        }

        public async Task SubmitReviewAsync(string token, PtSubmitReviewRequest request)
        {
            var requests = await _unitOfWork.PtReviewRequests.FindAsync(x => x.ReviewToken == token);
            var requestEntity = requests.FirstOrDefault() ?? throw new Exception("Review request does not exist.");

            if (requestEntity.ExpiresAt < DateTime.UtcNow)
            {
                throw new Exception("Link has expired.");
            }

            if (requestEntity.Status != "Pending")
            {
                throw new Exception("This review request has already been responded to or applied.");
            }

            requestEntity.PtComment = request.Comment;
            requestEntity.SuggestedCalorieTarget = request.SuggestedCalorieTarget;
            requestEntity.SuggestedProteinTarget = request.SuggestedProteinTarget;
            requestEntity.SuggestedChangesJson = System.Text.Json.JsonSerializer.Serialize(request.SuggestedChanges ?? new List<PtSuggestedChangeDto>(), new System.Text.Json.JsonSerializerOptions
            {
                PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
            });
            requestEntity.Status = "Reviewed";
            requestEntity.ReviewedAt = DateTime.UtcNow;

            _unitOfWork.PtReviewRequests.Update(requestEntity);
            await _unitOfWork.CompleteAsync();

            // Send notification to student
            try
            {
                string requestType = "";
                try
                {
                    if (!string.IsNullOrEmpty(requestEntity.ReportDataJson))
                    {
                        using var doc = System.Text.Json.JsonDocument.Parse(requestEntity.ReportDataJson);
                        if (doc.RootElement.TryGetProperty("requestType", out var prop))
                        {
                            requestType = prop.GetString() ?? "";
                        }
                    }
                }
                catch {}

                bool isRouteApproval = requestType.Equals("RouteApproval", StringComparison.OrdinalIgnoreCase) || string.IsNullOrEmpty(requestType);

                await _notificationService.SendAsync(new NotificationSendRequest
                {
                    UserId = requestEntity.UserId,
                    Type = isRouteApproval ? "PT_ROUTE_APPROVAL" : "PT_REVIEW",
                    Title = isRouteApproval ? "Lộ trình dinh dưỡng đã được duyệt" : "Feedback from your coach",
                    Body = isRouteApproval 
                        ? "PT đã duyệt lộ trình dinh dưỡng của bạn. Hãy kiểm tra và áp dụng mục tiêu mới!" 
                        : "Your PT has sent feedback for your weekly report. Check it out and update your nutrition plan!"
                });
            }
            catch
            {
                // Silence notification failures to prevent breaking core PT Review Submission
            }
        }

        public async Task<PtReviewRequestDetailResponse> GetReviewResultAsync(Guid userId, Guid requestId)
        {
            var requestEntity = await _unitOfWork.PtReviewRequests.GetByIdAsync(requestId)
                ?? throw new Exception("Review request does not exist.");

            if (requestEntity.UserId != userId)
            {
                throw new Exception("Access denied.");
            }

            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            var profile = user != null ? await _unitOfWork.Profiles.GetByIdAsync(userId) : null;
            var studentName = profile?.FullName ?? user?.Email ?? "Student";

            var reportData = System.Text.Json.JsonSerializer.Deserialize<WeeklyReportSnapshot>(requestEntity.ReportDataJson, new System.Text.Json.JsonSerializerOptions
            {
                PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
            });

            var suggestedChanges = new List<PtSuggestedChangeDto>();
            if (!string.IsNullOrEmpty(requestEntity.SuggestedChangesJson))
            {
                suggestedChanges = System.Text.Json.JsonSerializer.Deserialize<List<PtSuggestedChangeDto>>(requestEntity.SuggestedChangesJson, new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                }) ?? new List<PtSuggestedChangeDto>();
            }

            return new PtReviewRequestDetailResponse
            {
                ReportId = requestEntity.Id,
                StudentName = studentName,
                WeekStartDate = requestEntity.WeekStartDate,
                ExpiresAt = requestEntity.ExpiresAt,
                Status = requestEntity.Status,
                CreatedAt = requestEntity.CreatedAt,
                PtComment = requestEntity.PtComment ?? string.Empty,
                SuggestedCalorieTarget = requestEntity.SuggestedCalorieTarget,
                SuggestedProteinTarget = requestEntity.SuggestedProteinTarget,
                SuggestedChanges = suggestedChanges,
                ReportData = reportData,
                ReviewedAt = requestEntity.ReviewedAt,
                ActionedAt = requestEntity.ActionedAt,
                CheckInWeight = reportData?.CheckInWeight,
                CheckInBodyFat = reportData?.CheckInBodyFat,
                TrainingDaysCount = reportData?.TrainingDaysCount,
                BodyFeeling = reportData?.BodyFeeling,
                StudentNote = reportData?.StudentNote
            };
        }

        public async Task ApplyReviewAsync(Guid userId, Guid requestId)
        {
            var requestEntity = await _unitOfWork.PtReviewRequests.GetByIdAsync(requestId)
                ?? throw new Exception("Review request does not exist.");

            if (requestEntity.UserId != userId)
            {
                throw new Exception("Access denied.");
            }

            if (requestEntity.Status != "Reviewed")
            {
                throw new Exception("Review request has not been responded to by PT or has already been processed.");
            }

            // 1. Update Health Profile target calorie/protein/macros
            var healthProfiles = await _unitOfWork.HealthProfiles.FindAsync(hp => hp.UserId == userId);
            var healthProfile = healthProfiles.FirstOrDefault();
            if (healthProfile != null)
            {
                if (requestEntity.SuggestedCalorieTarget.HasValue)
                {
                    healthProfile.TargetCalories = requestEntity.SuggestedCalorieTarget.Value;
                    if (requestEntity.SuggestedProteinTarget.HasValue)
                    {
                        healthProfile.TargetProteinG = requestEntity.SuggestedProteinTarget.Value;
                        // Proportional distribution of Fat and Carbs
                        var remainingCal = requestEntity.SuggestedCalorieTarget.Value - (requestEntity.SuggestedProteinTarget.Value * 4);
                        if (remainingCal > 0)
                        {
                            healthProfile.TargetCarbsG = (int)Math.Round((remainingCal * 0.60) / 4);
                            healthProfile.TargetFatG = (int)Math.Round((remainingCal * 0.40) / 9);
                        }
                    }
                    else
                    {
                        // Use default formula to redistribute macros based on target calories
                        HealthProfileMetricsCalculator.ApplyMacroTargets(healthProfile);
                    }
                }
                healthProfile.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.HealthProfiles.Update(healthProfile);
            }

            // Sync targets to UserAiProfile.Preferences JSON so frontend reflects changes
            var aiProfiles = await _unitOfWork.UserAiProfiles.FindAsync(up => up.UserId == userId);
            var aiProfile = aiProfiles.FirstOrDefault();
            if (aiProfile != null && !string.IsNullOrEmpty(aiProfile.Preferences))
            {
                try
                {
                    var options = new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                    var prefs = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(aiProfile.Preferences, options) ?? new();
                    
                    if (requestEntity.SuggestedCalorieTarget.HasValue)
                    {
                        prefs["trainingDayTargetCalories"] = requestEntity.SuggestedCalorieTarget.Value;
                    }
                    if (requestEntity.SuggestedProteinTarget.HasValue)
                    {
                        prefs["minProteinG"] = requestEntity.SuggestedProteinTarget.Value;
                    }
                    
                    aiProfile.Preferences = System.Text.Json.JsonSerializer.Serialize(prefs);
                    aiProfile.UpdatedAt = DateTime.UtcNow;
                    _unitOfWork.UserAiProfiles.Update(aiProfile);
                }
                catch {}
            }

            // 2. Apply suggested meal alterations to next week's plan (or current week if route approval)
            string requestType = "";
            try
            {
                if (!string.IsNullOrEmpty(requestEntity.ReportDataJson))
                {
                    using var doc = System.Text.Json.JsonDocument.Parse(requestEntity.ReportDataJson);
                    if (doc.RootElement.TryGetProperty("requestType", out var prop))
                    {
                        requestType = prop.GetString() ?? "";
                    }
                }
            }
            catch {}

            bool isRouteApproval = requestType.Equals("RouteApproval", StringComparison.OrdinalIgnoreCase) || string.IsNullOrEmpty(requestType);
            var targetStartDate = isRouteApproval ? requestEntity.WeekStartDate : requestEntity.WeekStartDate.AddDays(7);

            var suggestedChanges = new List<PtSuggestedChangeDto>();
            if (!string.IsNullOrEmpty(requestEntity.SuggestedChangesJson))
            {
                suggestedChanges = System.Text.Json.JsonSerializer.Deserialize<List<PtSuggestedChangeDto>>(requestEntity.SuggestedChangesJson, new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                }) ?? new List<PtSuggestedChangeDto>();
            }

            foreach (var change in suggestedChanges)
            {
                var targetDate = GetTargetDate(targetStartDate, change.DayOfWeek);
                if (!targetDate.HasValue) continue;

                var dailyPlans = await _unitOfWork.MealPlanHeaders.FindAsync(x =>
                    x.UserId == userId
                    && x.PlanType == "DAILY"
                    && x.StartDate == targetDate.Value
                    && x.IsActive);
                var planHeader = dailyPlans.OrderByDescending(x => x.UpdatedAt ?? x.CreatedAt).FirstOrDefault();

                if (planHeader == null)
                {
                    planHeader = new MealPlanHeader
                    {
                        Id = Guid.NewGuid(),
                        UserId = userId,
                        Title = $"Daily plan {targetDate:yyyy-MM-dd}",
                        PlanType = "DAILY",
                        StartDate = targetDate.Value,
                        EndDate = targetDate.Value,
                        TargetCalories = healthProfile?.TargetCalories ?? 2000,
                        GeneratedBy = "PT_SUGGESTION",
                        IsActive = true,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };
                    await _unitOfWork.MealPlanHeaders.AddAsync(planHeader);
                    await _unitOfWork.CompleteAsync(); // save header first to establish foreign keys
                }

                var normMealType = NormalizeMealType(change.MealType);
                var planItems = (await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == planHeader.Id)).ToList();
                
                var cleanAction = (change.Action ?? "Replace").Trim().ToLowerInvariant();

                if (cleanAction == "replace")
                {
                    var targetItem = planItems.FirstOrDefault(x =>
                        NormalizeMealType(x.MealType ?? "") == normMealType
                        && (!change.OldFoodId.HasValue || x.FoodId == change.OldFoodId.Value));

                    if (targetItem != null)
                    {
                        if (change.NewFoodId.HasValue)
                        {
                            targetItem.FoodId = change.NewFoodId.Value;
                            targetItem.RecipeId = null;
                            var food = await _unitOfWork.Foods.GetByIdAsync(change.NewFoodId.Value);
                            if (food != null) targetItem.TargetCalories = (int?)food.CaloriesKcal;
                        }
                        else if (change.NewRecipeId.HasValue)
                        {
                            targetItem.RecipeId = change.NewRecipeId.Value;
                            targetItem.FoodId = null;
                            var recipe = await _unitOfWork.Recipes.GetByIdAsync(change.NewRecipeId.Value);
                            if (recipe != null) targetItem.TargetCalories = recipe.EstimatedPriceVnd.HasValue ? 500 : 400;
                        }
                        _unitOfWork.MealPlanItems.Update(targetItem);
                    }
                    else
                    {
                        // Fallback to Add
                        var newItem = new MealPlanItem
                        {
                            Id = Guid.NewGuid(),
                            MealPlanId = planHeader.Id,
                            MealType = normMealType,
                            PlannedDate = targetDate.Value,
                            ScheduledTime = normMealType switch
                            {
                                "breakfast" => new TimeOnly(7, 30),
                                "lunch" => new TimeOnly(12, 0),
                                "dinner" => new TimeOnly(18, 30),
                                _ => new TimeOnly(15, 0)
                            },
                            IsCompleted = false,
                            CreatedAt = DateTime.UtcNow
                        };
                        if (change.NewFoodId.HasValue)
                        {
                            newItem.FoodId = change.NewFoodId.Value;
                            var food = await _unitOfWork.Foods.GetByIdAsync(change.NewFoodId.Value);
                            if (food != null) newItem.TargetCalories = (int?)food.CaloriesKcal;
                        }
                        else if (change.NewRecipeId.HasValue)
                        {
                            newItem.RecipeId = change.NewRecipeId.Value;
                        }
                        await _unitOfWork.MealPlanItems.AddAsync(newItem);
                    }
                }
                else if (cleanAction == "add")
                {
                    var newItem = new MealPlanItem
                    {
                        Id = Guid.NewGuid(),
                        MealPlanId = planHeader.Id,
                        MealType = normMealType,
                        PlannedDate = targetDate.Value,
                        ScheduledTime = normMealType switch
                        {
                            "breakfast" => new TimeOnly(7, 30),
                            "lunch" => new TimeOnly(12, 0),
                            "dinner" => new TimeOnly(18, 30),
                            _ => new TimeOnly(15, 0)
                        },
                        IsCompleted = false,
                        CreatedAt = DateTime.UtcNow
                    };
                    if (change.NewFoodId.HasValue)
                    {
                        newItem.FoodId = change.NewFoodId.Value;
                        var food = await _unitOfWork.Foods.GetByIdAsync(change.NewFoodId.Value);
                        if (food != null) newItem.TargetCalories = (int?)food.CaloriesKcal;
                    }
                    else if (change.NewRecipeId.HasValue)
                    {
                        newItem.RecipeId = change.NewRecipeId.Value;
                    }
                    await _unitOfWork.MealPlanItems.AddAsync(newItem);
                }
                else if (cleanAction == "remove")
                {
                    var targetItem = planItems.FirstOrDefault(x =>
                        NormalizeMealType(x.MealType ?? "") == normMealType
                        && (!change.OldFoodId.HasValue || x.FoodId == change.OldFoodId.Value));
                    if (targetItem != null)
                    {
                        _unitOfWork.MealPlanItems.Remove(targetItem);
                    }
                }
            }

            requestEntity.Status = "Applied";
            requestEntity.ActionedAt = DateTime.UtcNow;

            _unitOfWork.PtReviewRequests.Update(requestEntity);
            await _unitOfWork.CompleteAsync();
        }

        public async Task RejectReviewAsync(Guid userId, Guid requestId)
        {
            var requestEntity = await _unitOfWork.PtReviewRequests.GetByIdAsync(requestId)
                ?? throw new Exception("Review request does not exist.");

            if (requestEntity.UserId != userId)
            {
                throw new Exception("Access denied.");
            }

            if (requestEntity.Status != "Reviewed")
            {
                throw new Exception("Review request has not been responded to by PT or has already been processed.");
            }

            requestEntity.Status = "Rejected";
            requestEntity.ActionedAt = DateTime.UtcNow;

            _unitOfWork.PtReviewRequests.Update(requestEntity);
            await _unitOfWork.CompleteAsync();
        }

        private static DateOnly? GetTargetDate(DateOnly nextWeekStartDate, string dayOfWeekStr)
        {
            var cleanStr = (dayOfWeekStr ?? string.Empty).Trim().ToLowerInvariant();
            int offset = -1;
            if (cleanStr.Contains("mon") || cleanStr.Contains("hai") || cleanStr == "thứ 2" || cleanStr == "thu 2") offset = 0;
            else if (cleanStr.Contains("tue") || cleanStr.Contains("ba") || cleanStr == "thứ 3" || cleanStr == "thu 3") offset = 1;
            else if (cleanStr.Contains("wed") || cleanStr.Contains("tư") || cleanStr.Contains("tu") || cleanStr == "thứ 4" || cleanStr == "thu 4") offset = 2;
            else if (cleanStr.Contains("thu") || cleanStr.Contains("năm") || cleanStr.Contains("nam") || cleanStr == "thứ 5" || cleanStr == "thu 5") offset = 3;
            else if (cleanStr.Contains("fri") || cleanStr.Contains("sáu") || cleanStr.Contains("sau") || cleanStr == "thứ 6" || cleanStr == "thu 6") offset = 4;
            else if (cleanStr.Contains("sat") || cleanStr.Contains("bảy") || cleanStr.Contains("bay") || cleanStr == "thứ 7" || cleanStr == "thu 7") offset = 5;
            else if (cleanStr.Contains("sun") || cleanStr.Contains("chủ") || cleanStr.Contains("chu") || cleanStr == "cn") offset = 6;

            if (offset >= 0)
            {
                return nextWeekStartDate.AddDays(offset);
            }
            return null;
        }

        private static string NormalizeMealType(string mealType)
        {
            var normalized = (mealType ?? string.Empty).Trim().ToLowerInvariant();
            return normalized switch
            {
                "breakfast" or "lunch" or "dinner" or "snack" => normalized,
                "bữa sáng" or "bua sang" => "breakfast",
                "bữa trưa" or "bua trua" => "lunch",
                "bữa tối" or "bua toi" => "dinner",
                "bữa phụ" or "bua phu" => "snack",
                _ => normalized.Length > 0 ? normalized : "snack"
            };
        }
    }

    // A lightweight wrapper to send notifications safely
    internal class NotiServiceWrapper
    {
        private readonly INotificationService _service;
        public NotiServiceWrapper(INotificationService service) { _service = service; }
        public async Task SendAsync(NotificationSendRequest request)
        {
            var mapped = new MenuGreen.BusinessLogicLayer.DTOs.Requests.NotificationSendRequest
            {
                UserId = request.UserId,
                Type = request.Type,
                Title = request.Title,
                Body = request.Body,
                ScheduledAt = null
            };
            await _service.SendAsync(mapped);
        }
    }

    // Support models inside the snapshot
    public class WeeklyReportSnapshot
    {
        public string RequestType { get; set; } = "WeeklyReport";
        public DateOnly WeekStartDate { get; set; }
        public string StudentNote { get; set; } = string.Empty;
        public decimal? CheckInWeight { get; set; }
        public decimal? CheckInBodyFat { get; set; }
        public int? TrainingDaysCount { get; set; }
        public string BodyFeeling { get; set; } = string.Empty;
        public HealthProfileSnapshot StudentHealthProfile { get; set; } = new();
        public PlannedVsActualSummaryResponse NutritionSummary { get; set; } = new();
        public AdherenceScoreResponse AdherenceScore { get; set; } = new();
        public DriftAnalysisResponse DriftAnalysis { get; set; } = new();
        public List<WeightLogSnapshot> WeightLogs { get; set; } = new();
        public List<DailyMealsSnapshot> DailyMeals { get; set; } = new();
    }

    public class HealthProfileSnapshot
    {
        public decimal? HeightCm { get; set; }
        public decimal? WeightKg { get; set; }
        public string? ActivityLevel { get; set; }
        public string? Goal { get; set; }
        public int? TargetCalories { get; set; }
        public int? TargetProteinG { get; set; }
        public int? TargetCarbsG { get; set; }
        public int? TargetFatG { get; set; }
    }

    public class WeightLogSnapshot
    {
        public decimal? WeightKg { get; set; }
        public decimal? BodyFatPercent { get; set; }
        public DateTime? RecordedAt { get; set; }
    }

    public class DailyMealsSnapshot
    {
        public DateOnly Date { get; set; }
        public List<MealPlanItemSnapshot> PlannedItems { get; set; } = new();
        public List<MealLogSnapshot> ActualLogs { get; set; } = new();
    }

    public class MealPlanItemSnapshot
    {
        public Guid Id { get; set; }
        public string MealType { get; set; } = string.Empty;
        public Guid? FoodId { get; set; }
        public string? FoodName { get; set; }
        public Guid? RecipeId { get; set; }
        public string? RecipeName { get; set; }
        public int? TargetCalories { get; set; }
        public bool IsCompleted { get; set; }
    }

    public class MealLogSnapshot
    {
        public Guid Id { get; set; }
        public string MealType { get; set; } = string.Empty;
        public Guid? FoodId { get; set; }
        public string? FoodName { get; set; }
        public Guid? RecipeId { get; set; }
        public string? RecipeName { get; set; }
        public decimal? CaloriesKcal { get; set; }
        public decimal? QuantityG { get; set; }
        public string? Notes { get; set; }
        public DateTime? LoggedAt { get; set; }
    }
}
