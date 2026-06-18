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
    public class CoachService : ICoachService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INotificationService _notificationService;

        public CoachService(IUnitOfWork unitOfWork, INotificationService notificationService)
        {
            _unitOfWork = unitOfWork;
            _notificationService = notificationService;
        }

        public async Task<IEnumerable<CoachProfileResponse>> GetCoachesAsync(string? specialty, int? minPrice, int? maxPrice)
        {
            var coaches = await _unitOfWork.CoachProfiles.FindAsync(c => c.IsActive);
            var list = coaches.ToList();

            if (!string.IsNullOrWhiteSpace(specialty))
            {
                list = list.Where(c => c.Specialty.Contains(specialty, StringComparison.OrdinalIgnoreCase)).ToList();
            }

            if (minPrice.HasValue)
            {
                list = list.Where(c => c.PriceVnd >= minPrice.Value).ToList();
            }

            if (maxPrice.HasValue)
            {
                list = list.Where(c => c.PriceVnd <= maxPrice.Value).ToList();
            }

            var results = new List<CoachProfileResponse>();
            foreach (var item in list)
            {
                var profile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == item.UserId)).FirstOrDefault();
                results.Add(new CoachProfileResponse
                {
                    Id = item.Id,
                    UserId = item.UserId,
                    FullName = profile?.FullName ?? "Chuyên gia MenuGreen",
                    AvatarUrl = profile?.AvatarUrl ?? string.Empty,
                    Specialty = item.Specialty,
                    Bio = item.Bio,
                    ExperienceYears = item.ExperienceYears,
                    CertificateUrl = item.CertificateUrl,
                    PriceVnd = item.PriceVnd,
                    IsActive = item.IsActive,
                    CreatedAt = item.CreatedAt
                });
            }

            return results;
        }

        public async Task<CoachProfileResponse> GetCoachByIdAsync(Guid coachId)
        {
            var item = await _unitOfWork.CoachProfiles.GetByIdAsync(coachId)
                ?? throw new Exception("Không tìm thấy hồ sơ Coach.");

            var profile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == item.UserId)).FirstOrDefault();
            return new CoachProfileResponse
            {
                Id = item.Id,
                UserId = item.UserId,
                FullName = profile?.FullName ?? "Chuyên gia MenuGreen",
                AvatarUrl = profile?.AvatarUrl ?? string.Empty,
                Specialty = item.Specialty,
                Bio = item.Bio,
                ExperienceYears = item.ExperienceYears,
                CertificateUrl = item.CertificateUrl,
                PriceVnd = item.PriceVnd,
                IsActive = item.IsActive,
                CreatedAt = item.CreatedAt
            };
        }

        public async Task<CoachProfileResponse> RegisterCoachAsync(Guid userId, CoachRegisterRequest request)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId)
                ?? throw new Exception("Người dùng không tồn tại.");

            // Find or create Coach Role
            var coachRole = (await _unitOfWork.Roles.FindAsync(r => r.Name == "Coach")).FirstOrDefault();
            if (coachRole == null)
            {
                coachRole = new Role
                {
                    Id = Guid.NewGuid(),
                    Name = "Coach",
                    Description = "Personal trainer, nutritionist, or health expert role",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.Roles.AddAsync(coachRole);
                await _unitOfWork.CompleteAsync();
            }

            // Upgrade User role to Coach
            user.RoleId = coachRole.Id;
            user.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.Users.Update(user);

            // Find or create Coach Profile
            var existingProfile = (await _unitOfWork.CoachProfiles.FindAsync(c => c.UserId == userId)).FirstOrDefault();
            if (existingProfile != null)
            {
                existingProfile.Specialty = request.Specialty;
                existingProfile.Bio = request.Bio;
                existingProfile.ExperienceYears = request.ExperienceYears;
                existingProfile.CertificateUrl = request.CertificateUrl;
                existingProfile.PriceVnd = request.PriceVnd;
                existingProfile.IsActive = true;
                existingProfile.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.CoachProfiles.Update(existingProfile);
            }
            else
            {
                existingProfile = new CoachProfile
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Specialty = request.Specialty,
                    Bio = request.Bio,
                    ExperienceYears = request.ExperienceYears,
                    CertificateUrl = request.CertificateUrl,
                    PriceVnd = request.PriceVnd,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.CoachProfiles.AddAsync(existingProfile);
            }

            await _unitOfWork.CompleteAsync();

            var userProfile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == userId)).FirstOrDefault();
            return new CoachProfileResponse
            {
                Id = existingProfile.Id,
                UserId = existingProfile.UserId,
                FullName = userProfile?.FullName ?? "Chuyên gia MenuGreen",
                AvatarUrl = userProfile?.AvatarUrl ?? string.Empty,
                Specialty = existingProfile.Specialty,
                Bio = existingProfile.Bio,
                ExperienceYears = existingProfile.ExperienceYears,
                CertificateUrl = existingProfile.CertificateUrl,
                PriceVnd = existingProfile.PriceVnd,
                IsActive = existingProfile.IsActive,
                CreatedAt = existingProfile.CreatedAt
            };
        }

        public async Task<bool> ConnectCoachAsync(Guid clientId, Guid coachId)
        {
            var coachProf = await _unitOfWork.CoachProfiles.GetByIdAsync(coachId);
            var coachUserId = coachProf != null ? coachProf.UserId : coachId;

            var clientUser = await _unitOfWork.Users.GetByIdAsync(clientId);
            var coachUser = await _unitOfWork.Users.GetByIdAsync(coachUserId);

            if (clientUser == null || coachUser == null)
            {
                throw new Exception("Học viên hoặc Coach không tồn tại.");
            }

            var existingConnection = (await _unitOfWork.CoachConnections.FindAsync(
                c => c.ClientId == clientId && c.CoachId == coachUserId)).FirstOrDefault();

            if (existingConnection != null)
            {
                existingConnection.Status = "Pending";
                existingConnection.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.CoachConnections.Update(existingConnection);
            }
            else
            {
                var connection = new CoachConnection
                {
                    Id = Guid.NewGuid(),
                    ClientId = clientId,
                    CoachId = coachUserId,
                    Status = "Pending",
                    IsAccessGranted = false,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.CoachConnections.AddAsync(connection);
            }

            await _unitOfWork.CompleteAsync();

            // Send notification to Coach
            var clientProfile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == clientId)).FirstOrDefault();
            var clientName = clientProfile?.FullName ?? clientUser.Email;
            await _notificationService.SendAsync(new NotificationSendRequest
            {
                UserId = coachUserId,
                Type = "connection_request",
                Title = "Yêu cầu kết nối học viên mới",
                Body = $"{clientName} muốn kết nối và thuê bạn làm huấn luyện viên dinh dưỡng.",
                ScheduledAt = null
            });

            return true;
        }

        public async Task<bool> ApproveConnectionAsync(Guid coachId, Guid clientId, bool approve)
        {
            var connection = (await _unitOfWork.CoachConnections.FindAsync(
                c => c.CoachId == coachId && c.ClientId == clientId)).FirstOrDefault()
                ?? throw new Exception("Không tìm thấy yêu cầu kết nối.");

            connection.Status = approve ? "Connected" : "Rejected";
            connection.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.CoachConnections.Update(connection);
            await _unitOfWork.CompleteAsync();

            // Send notification to Client
            var coachProfile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == coachId)).FirstOrDefault();
            var coachName = coachProfile?.FullName ?? "Huấn luyện viên của bạn";
            var actionText = approve ? "chấp nhận" : "từ chối";
            await _notificationService.SendAsync(new NotificationSendRequest
            {
                UserId = clientId,
                Type = "connection_response",
                Title = approve ? "Yêu cầu kết nối thành công" : "Yêu cầu kết nối bị từ chối",
                Body = $"Huấn luyện viên {coachName} đã {actionText} yêu cầu kết nối của bạn.",
                ScheduledAt = null
            });

            return true;
        }

        public async Task<IEnumerable<CoachClientSummaryResponse>> GetMyClientsAsync(Guid coachId)
        {
            var connections = await _unitOfWork.CoachConnections.FindAsync(
                c => c.CoachId == coachId && c.Status == "Connected");

            var results = new List<CoachClientSummaryResponse>();

            foreach (var conn in connections)
            {
                var client = await _unitOfWork.Users.GetByIdAsync(conn.ClientId);
                if (client == null) continue;

                var profile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == conn.ClientId)).FirstOrDefault();
                
                // Get Streak
                var mealLogs = await _unitOfWork.MealLogs.FindAsync(x => x.UserId == conn.ClientId);
                var streak = CalculateStreak(mealLogs.Select(x => x.LoggedAt).ToList());

                // Get Active Program Title
                var activeProgram = (await _unitOfWork.UserPremiumPrograms.FindAsync(
                    up => up.UserId == conn.ClientId && up.Status == "Active")).FirstOrDefault();
                var activeProgramTitle = string.Empty;
                if (activeProgram != null)
                {
                    var prog = await _unitOfWork.PremiumPrograms.GetByIdAsync(activeProgram.ProgramId);
                    activeProgramTitle = prog?.Title ?? string.Empty;
                }

                // Get drift alerts
                var activeAlerts = await _unitOfWork.GoalDriftAlerts.FindAsync(
                    a => a.UserId == conn.ClientId && a.IsAcknowledged == false && a.IsDismissed == false);
                var hasAlert = activeAlerts.Any();

                results.Add(new CoachClientSummaryResponse
                {
                    ClientId = conn.ClientId,
                    FullName = profile?.FullName ?? client.Email,
                    Email = client.Email,
                    AvatarUrl = profile?.AvatarUrl ?? string.Empty,
                    ConnectionStatus = conn.Status,
                    IsAccessGranted = conn.IsAccessGranted,
                    CurrentStreak = streak,
                    HasCalorieDriftAlert = hasAlert,
                    ActiveProgramTitle = activeProgramTitle,
                    ConnectedAt = conn.UpdatedAt
                });
            }

            return results.OrderByDescending(x => x.ConnectedAt);
        }

        public async Task<bool> GrantAccessAsync(Guid clientId, Guid coachId)
        {
            var coachProf = await _unitOfWork.CoachProfiles.GetByIdAsync(coachId);
            var coachUserId = coachProf != null ? coachProf.UserId : coachId;

            var connection = (await _unitOfWork.CoachConnections.FindAsync(
                c => c.ClientId == clientId && c.CoachId == coachUserId && c.Status == "Connected")).FirstOrDefault()
                ?? throw new Exception("Không tìm thấy kết nối hoạt động với Coach này.");

            connection.IsAccessGranted = true;
            connection.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.CoachConnections.Update(connection);
            await _unitOfWork.CompleteAsync();

            return true;
        }

        public async Task<bool> RevokeAccessAsync(Guid clientId, Guid coachId)
        {
            var coachProf = await _unitOfWork.CoachProfiles.GetByIdAsync(coachId);
            var coachUserId = coachProf != null ? coachProf.UserId : coachId;

            var connection = (await _unitOfWork.CoachConnections.FindAsync(
                c => c.ClientId == clientId && c.CoachId == coachUserId && c.Status == "Connected")).FirstOrDefault()
                ?? throw new Exception("Không tìm thấy kết nối hoạt động với Coach này.");

            connection.IsAccessGranted = false;
            connection.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.CoachConnections.Update(connection);
            await _unitOfWork.CompleteAsync();

            return true;
        }

        private async Task EnsureAccessAllowedAsync(Guid coachId, Guid clientId)
        {
            var connection = (await _unitOfWork.CoachConnections.FindAsync(
                c => c.CoachId == coachId && c.ClientId == clientId && c.Status == "Connected")).FirstOrDefault();

            if (connection == null)
            {
                throw new UnauthorizedAccessException("Bạn không có kết nối huấn luyện hợp lệ với học viên này.");
            }

            if (!connection.IsAccessGranted)
            {
                throw new UnauthorizedAccessException("Học viên chưa cấp quyền cho bạn truy cập dữ liệu sức khỏe.");
            }
        }

        public async Task<object> GetClientProfileAsync(Guid coachId, Guid clientId)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);

            var profile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == clientId)).FirstOrDefault();
            var health = (await _unitOfWork.HealthProfiles.FindAsync(h => h.UserId == clientId)).FirstOrDefault();
            
            var userAllergies = await _unitOfWork.UserAllergies.FindAsync(ua => ua.UserId == clientId);
            var allergyIds = userAllergies.Select(ua => ua.AllergyId).ToList();
            var allergies = allergyIds.Any()
                ? (await _unitOfWork.Allergies.FindAsync(a => allergyIds.Contains(a.Id))).Select(a => a.Name).ToList()
                : new List<string>();

            return new
            {
                ClientId = clientId,
                FullName = profile?.FullName ?? "Chưa thiết lập",
                AvatarUrl = profile?.AvatarUrl ?? string.Empty,
                HeightCm = health?.HeightCm,
                WeightKg = health?.WeightKg,
                BodyFatPercent = health?.BodyFatPercent,
                ActivityLevel = health?.ActivityLevel,
                Goal = health?.Goal,
                Bmi = health?.Bmi,
                TargetCalories = health?.TargetCalories,
                TargetProteinG = health?.TargetProteinG,
                TargetCarbsG = health?.TargetCarbsG,
                TargetFatG = health?.TargetFatG,
                Allergies = allergies
            };
        }

        public async Task<IEnumerable<ClientNutritionSummaryResponse>> GetClientNutritionSummaryAsync(Guid coachId, Guid clientId, int days)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);

            var cutoff = DateTime.UtcNow.Date.AddDays(-days);
            var logs = await _unitOfWork.MealLogs.FindAsync(x => x.UserId == clientId && x.LoggedAt >= cutoff);
            var health = (await _unitOfWork.HealthProfiles.FindAsync(h => h.UserId == clientId)).FirstOrDefault();
            var profile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == clientId)).FirstOrDefault();

            var targetCalories = health?.TargetCalories ?? 2000;
            var targetProtein = health?.TargetProteinG ?? 150;
            var targetCarbs = health?.TargetCarbsG ?? 200;
            var targetFat = health?.TargetFatG ?? 65;

            var grouped = logs
                .Where(x => x.LoggedAt.HasValue)
                .GroupBy(x => DateOnly.FromDateTime(x.LoggedAt!.Value))
                .Select(g => new ClientNutritionSummaryResponse
                {
                    ClientId = clientId,
                    FullName = profile?.FullName ?? string.Empty,
                    Date = g.Key,
                    ActualCalories = g.Sum(x => x.CaloriesKcal ?? 0),
                    TargetCalories = targetCalories,
                    ActualProtein = g.Sum(x => x.ProteinG ?? 0),
                    TargetProtein = targetProtein,
                    ActualCarbs = g.Sum(x => x.CarbsG ?? 0),
                    TargetCarbs = targetCarbs,
                    ActualFat = g.Sum(x => x.FatG ?? 0),
                    TargetFat = targetFat
                })
                .OrderByDescending(x => x.Date)
                .ToList();

            return grouped;
        }

        public async Task<IEnumerable<ClientWeightTrendResponse>> GetClientWeightTrendAsync(Guid coachId, Guid clientId)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);

            var logs = await _unitOfWork.WeightLogs.FindAsync(x => x.UserId == clientId);
            return logs
                .OrderBy(x => x.RecordedAt)
                .Select(x => new ClientWeightTrendResponse
                {
                    Id = x.Id,
                    WeightKg = x.WeightKg,
                    BodyFatPercent = x.BodyFatPercent,
                    RecordedAt = x.RecordedAt
                })
                .ToList();
        }

        public async Task<CoachFeedbackResponse> AddFeedbackAsync(Guid coachId, Guid clientId, CoachFeedbackCreateRequest request)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);

            var feedback = new CoachFeedback
            {
                Id = Guid.NewGuid(),
                ClientId = clientId,
                CoachId = coachId,
                FeedbackType = request.FeedbackType,
                TargetId = request.TargetId,
                MealType = request.MealType,
                LogDate = request.LogDate,
                Content = request.Content,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.CoachFeedbacks.AddAsync(feedback);
            await _unitOfWork.CompleteAsync();

            var coachProfile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == coachId)).FirstOrDefault();
            var coachName = coachProfile?.FullName ?? "Huấn luyện viên của bạn";

            // Trigger notification to Client
            var bodyText = $"Huấn luyện viên {coachName} đã gửi nhận xét mới cho bạn: \"{request.Content}\"";
            await _notificationService.SendAsync(new NotificationSendRequest
            {
                UserId = clientId,
                Type = "coach_feedback",
                Title = "Lời khuyên mới từ Coach",
                Body = bodyText,
                ScheduledAt = null
            });

            return new CoachFeedbackResponse
            {
                Id = feedback.Id,
                ClientId = feedback.ClientId,
                CoachId = feedback.CoachId,
                CoachName = coachName,
                FeedbackType = feedback.FeedbackType,
                TargetId = feedback.TargetId,
                MealType = feedback.MealType,
                LogDate = feedback.LogDate,
                Content = feedback.Content,
                CreatedAt = feedback.CreatedAt
            };
        }

        public async Task<IEnumerable<CoachFeedbackResponse>> GetFeedbacksAsync(Guid userId)
        {
            var feedbacks = await _unitOfWork.CoachFeedbacks.FindAsync(
                f => f.ClientId == userId || f.CoachId == userId);

            var results = new List<CoachFeedbackResponse>();
            foreach (var item in feedbacks)
            {
                var coachProfile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == item.CoachId)).FirstOrDefault();
                results.Add(new CoachFeedbackResponse
                {
                    Id = item.Id,
                    ClientId = item.ClientId,
                    CoachId = item.CoachId,
                    CoachName = coachProfile?.FullName ?? "Huấn luyện viên",
                    FeedbackType = item.FeedbackType,
                    TargetId = item.TargetId,
                    MealType = item.MealType,
                    LogDate = item.LogDate,
                    Content = item.Content,
                    CreatedAt = item.CreatedAt
                });
            }

            return results.OrderByDescending(x => x.CreatedAt);
        }

        public async Task<MealPlanResponse> AdjustClientMealPlanAsync(Guid coachId, Guid clientId, Guid planId, MealPlanUpsertRequest request)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);

            var plan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(planId)
                ?? throw new Exception("Không tìm thấy thực đơn kế hoạch.");
            
            if (plan.UserId != clientId)
            {
                throw new Exception("Thực đơn này không phải của học viên được chỉ định.");
            }

            plan.Title = request.Title;
            plan.PlanType = request.PlanType;
            plan.StartDate = request.StartDate;
            plan.EndDate = request.EndDate;
            plan.TargetCalories = request.TargetCalories;
            plan.GeneratedBy = "COACH";
            plan.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.MealPlanHeaders.Update(plan);

            // Replace items
            var existingItems = await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == plan.Id);
            _unitOfWork.MealPlanItems.RemoveRange(existingItems);
            await _unitOfWork.CompleteAsync();

            foreach (var item in request.Items)
            {
                await _unitOfWork.MealPlanItems.AddAsync(new MealPlanItem
                {
                    Id = Guid.NewGuid(),
                    MealPlanId = plan.Id,
                    MealType = item.MealType,
                    FoodId = item.FoodId,
                    RecipeId = item.RecipeId,
                    PlannedDate = item.PlannedDate,
                    ScheduledTime = item.ScheduledTime,
                    TargetCalories = item.TargetCalories,
                    IsCompleted = item.IsCompleted,
                    CreatedAt = DateTime.UtcNow
                });
            }

            await _unitOfWork.CompleteAsync();

            // Send notification to Client
            var coachProfile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == coachId)).FirstOrDefault();
            var coachName = coachProfile?.FullName ?? "Huấn luyện viên";
            await _notificationService.SendAsync(new NotificationSendRequest
            {
                UserId = clientId,
                Type = "meal_plan_adjusted",
                Title = "Thực đơn đã được điều chỉnh",
                Body = $"Huấn luyện viên {coachName} đã trực tiếp điều chỉnh thực đơn kế hoạch của bạn.",
                ScheduledAt = null
            });

            return await MapMealPlanAsync(plan);
        }

        public async Task<HealthProfileResponse> AdjustClientHealthTargetsAsync(Guid coachId, Guid clientId, ClientHealthTargetsAdjustRequest request)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);

            var health = (await _unitOfWork.HealthProfiles.FindAsync(h => h.UserId == clientId)).FirstOrDefault()
                ?? throw new Exception("Học viên chưa thiết lập hồ sơ sức khỏe.");

            health.TargetCalories = request.TargetCalories;
            health.TargetProteinG = request.TargetProteinG;
            health.TargetCarbsG = request.TargetCarbsG;
            health.TargetFatG = request.TargetFatG;
            health.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.HealthProfiles.Update(health);
            await _unitOfWork.CompleteAsync();

            // Send notification to Client
            var coachProfile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == coachId)).FirstOrDefault();
            var coachName = coachProfile?.FullName ?? "Huấn luyện viên";
            await _notificationService.SendAsync(new NotificationSendRequest
            {
                UserId = clientId,
                Type = "targets_adjusted",
                Title = "Mục tiêu dinh dưỡng được cập nhật",
                Body = $"Huấn luyện viên {coachName} đã thiết lập lại mục tiêu Calo/Macros cho bạn.",
                ScheduledAt = null
            });

            return new HealthProfileResponse
            {
                UserId = health.UserId,
                HeightCm = health.HeightCm,
                WeightKg = health.WeightKg,
                BodyFatPercent = health.BodyFatPercent,
                ActivityLevel = health.ActivityLevel,
                Goal = health.Goal,
                Bmi = health.Bmi,
                BmrKcal = health.BmrKcal,
                TdeeKcal = health.TdeeKcal,
                TargetCalories = health.TargetCalories,
                TargetProteinG = health.TargetProteinG,
                TargetCarbsG = health.TargetCarbsG,
                TargetFatG = health.TargetFatG
            };
        }

        private async Task<MealPlanResponse> MapMealPlanAsync(MealPlanHeader entity)
        {
            var items = await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == entity.Id);
            var responseItems = new List<MealPlanItemResponse>();
            foreach (var item in items)
            {
                Food? food = null;
                Recipe? recipe = null;
                if (item.FoodId.HasValue) food = await _unitOfWork.Foods.GetByIdAsync(item.FoodId.Value);
                if (item.RecipeId.HasValue) recipe = await _unitOfWork.Recipes.GetByIdAsync(item.RecipeId.Value);
                var price = food?.EstimatedPriceVnd ?? recipe?.EstimatedPriceVnd;

                responseItems.Add(new MealPlanItemResponse
                {
                    Id = item.Id,
                    MealPlanId = item.MealPlanId,
                    MealType = item.MealType,
                    FoodId = item.FoodId,
                    RecipeId = item.RecipeId,
                    PlannedDate = item.PlannedDate,
                    ScheduledTime = item.ScheduledTime,
                    TargetCalories = item.TargetCalories,
                    IsCompleted = item.IsCompleted,
                    FoodName = food?.NameVi,
                    RecipeName = recipe?.Title,
                    SourceEntityType = item.FoodId.HasValue ? "Food" : item.RecipeId.HasValue ? "Recipe" : null,
                    Status = item.IsCompleted ? "done" : "planned",
                    EstimatedPriceVnd = price
                });
            }

            return new MealPlanResponse
            {
                Id = entity.Id,
                Title = entity.Title ?? string.Empty,
                PlanType = entity.PlanType,
                StartDate = entity.StartDate,
                EndDate = entity.EndDate,
                TargetCalories = entity.TargetCalories,
                GeneratedBy = entity.GeneratedBy,
                IsActive = entity.IsActive,
                TotalCalories = responseItems.Sum(x => x.TargetCalories ?? 0),
                TotalProteinG = 0,
                TotalCarbsG = 0,
                TotalFatG = 0,
                Items = responseItems
            };
        }

        private static int CalculateStreak(List<DateTime?> loggedDates)
        {
            if (loggedDates == null || loggedDates.Count == 0) return 0;

            var distinctDates = loggedDates
                .Where(x => x.HasValue)
                .Select(x => DateOnly.FromDateTime(x!.Value))
                .Distinct()
                .OrderByDescending(x => x)
                .ToList();

            if (distinctDates.Count == 0) return 0;

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var yesterday = today.AddDays(-1);

            if (distinctDates[0] != today && distinctDates[0] != yesterday)
            {
                return 0;
            }

            int streak = 0;
            var currentDate = distinctDates[0];

            foreach (var date in distinctDates)
            {
                if (date == currentDate)
                {
                    streak++;
                    currentDate = currentDate.AddDays(-1);
                }
                else if (date == currentDate.AddDays(-1))
                {
                    streak++;
                    currentDate = date.AddDays(-1);
                }
                else
                {
                    break;
                }
            }

            return streak;
        }
    }
}
