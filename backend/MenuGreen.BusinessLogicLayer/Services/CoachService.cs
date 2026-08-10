using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
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
        private readonly IMealPlanService _mealPlanService;
        private readonly IDailyStarterService _dailyStarterService;
        private readonly IPtReviewService _ptReviewService;
        private readonly IRecipeService _recipeService;

        public CoachService(
            IUnitOfWork unitOfWork, 
            INotificationService notificationService,
            IMealPlanService mealPlanService,
            IDailyStarterService dailyStarterService,
            IPtReviewService ptReviewService,
            IRecipeService recipeService)
        {
            _unitOfWork = unitOfWork;
            _notificationService = notificationService;
            _mealPlanService = mealPlanService;
            _dailyStarterService = dailyStarterService;
            _ptReviewService = ptReviewService;
            _recipeService = recipeService;
        }

        public async Task<IEnumerable<CoachProfileResponse>> GetCoachesAsync(string? specialty, int? minPrice, int? maxPrice)
        {
            var coaches = await _unitOfWork.CoachProfiles.FindAsync(c =>
                c.IsActive
                && c.ApplicationStatus == "Approved"
                && c.User != null
                && c.User.IsActive
                && c.User.Role != null
                && c.User.Role.Name == "Coach",
                asNoTracking: true);
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
                    FullName = profile?.FullName ?? "MenuGreen Expert",
                    AvatarUrl = profile?.AvatarUrl ?? string.Empty,
                    Specialty = item.Specialty,
                    Headline = item.Headline,
                    Bio = item.Bio,
                    ExperienceYears = item.ExperienceYears,
                    CertificateUrl = item.CertificateUrl,
                    City = item.City,
                    Languages = ParseStringList(item.LanguagesJson),
                    CoachingStyles = ParseStringList(item.CoachingStylesJson),
                    ClientLevels = ParseStringList(item.ClientLevelsJson),
                    Certificates = ParseCertificates(item.CertificatesJson),
                    GalleryUrls = ParseStringList(item.GalleryUrlsJson),
                    Achievements = item.Achievements,
                    ApplicationStatus = item.ApplicationStatus,
                    PriceVnd = item.PriceVnd,
                    IsActive = item.IsActive,
                    CreatedAt = item.CreatedAt
                });
            }

            return results;
        }

        public async Task<CoachProfileResponse> GetCoachByIdAsync(Guid coachId)
        {
            var item = (await _unitOfWork.CoachProfiles.FindAsync(c =>
                    c.Id == coachId
                    && c.IsActive
                    && c.ApplicationStatus == "Approved"
                    && c.User != null
                    && c.User.IsActive
                    && c.User.Role != null
                    && c.User.Role.Name == "Coach",
                    asNoTracking: true))
                .FirstOrDefault()
                ?? throw new Exception("Coach profile not found.");

            var profile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == item.UserId)).FirstOrDefault();
            return new CoachProfileResponse
            {
                Id = item.Id,
                UserId = item.UserId,
                FullName = profile?.FullName ?? "MenuGreen Expert",
                AvatarUrl = profile?.AvatarUrl ?? string.Empty,
                Specialty = item.Specialty,
                Headline = item.Headline,
                Bio = item.Bio,
                ExperienceYears = item.ExperienceYears,
                CertificateUrl = item.CertificateUrl,
                City = item.City,
                Languages = ParseStringList(item.LanguagesJson),
                CoachingStyles = ParseStringList(item.CoachingStylesJson),
                ClientLevels = ParseStringList(item.ClientLevelsJson),
                Certificates = ParseCertificates(item.CertificatesJson),
                GalleryUrls = ParseStringList(item.GalleryUrlsJson),
                Achievements = item.Achievements,
                ApplicationStatus = item.ApplicationStatus,
                PriceVnd = item.PriceVnd,
                IsActive = item.IsActive,
                CreatedAt = item.CreatedAt
            };
        }

        public async Task<CoachProfileResponse> RegisterCoachAsync(Guid userId, CoachRegisterRequest request)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId)
                ?? throw new Exception("User does not exist.");

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
                existingProfile.ApplicationStatus = "PendingReview";
                existingProfile.ReviewNote = null;
                existingProfile.SubmittedAt = DateTime.UtcNow;
                existingProfile.IsActive = false;
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
                    ApplicationStatus = "PendingReview",
                    SubmittedAt = DateTime.UtcNow,
                    IsActive = false,
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
                Headline = existingProfile.Headline,
                Bio = existingProfile.Bio,
                ExperienceYears = existingProfile.ExperienceYears,
                CertificateUrl = existingProfile.CertificateUrl,
                City = existingProfile.City,
                Languages = ParseStringList(existingProfile.LanguagesJson),
                CoachingStyles = ParseStringList(existingProfile.CoachingStylesJson),
                ClientLevels = ParseStringList(existingProfile.ClientLevelsJson),
                Certificates = ParseCertificates(existingProfile.CertificatesJson),
                GalleryUrls = ParseStringList(existingProfile.GalleryUrlsJson),
                Achievements = existingProfile.Achievements,
                ApplicationStatus = existingProfile.ApplicationStatus,
                PriceVnd = existingProfile.PriceVnd,
                IsActive = existingProfile.IsActive,
                CreatedAt = existingProfile.CreatedAt
            };
        }

        public async Task<bool> ConnectCoachAsync(Guid clientId, Guid coachId)
        {
            var coachProf = (await _unitOfWork.CoachProfiles.FindAsync(c =>
                    (c.Id == coachId || c.UserId == coachId)
                    && c.IsActive
                    && c.ApplicationStatus == "Approved"
                    && c.User != null
                    && c.User.IsActive
                    && c.User.Role != null
                    && c.User.Role.Name == "Coach"))
                .FirstOrDefault()
                ?? throw new Exception("Coach profile not found.");
            var coachUserId = coachProf.UserId;

            var clientUser = await _unitOfWork.Users.GetByIdAsync(clientId);
            var coachUser = await _unitOfWork.Users.GetByIdAsync(coachUserId);

            if (clientUser == null || coachUser == null)
            {
                throw new Exception("Student or Coach does not exist.");
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
                Title = "New student connection request",
                Body = $"{clientName} wants to connect and hire you as their nutrition coach.",
                ScheduledAt = null
            });

            return true;
        }

        public async Task<bool> ApproveConnectionAsync(Guid coachId, Guid clientId, bool approve)
        {
            var connection = (await _unitOfWork.CoachConnections.FindAsync(
                c => c.CoachId == coachId && c.ClientId == clientId)).FirstOrDefault()
                ?? throw new Exception("Connection request not found.");

            connection.Status = approve ? "Connected" : "Rejected";
            if (approve)
            {
                connection.IsAccessGranted = true;
            }
            connection.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.CoachConnections.Update(connection);
            await _unitOfWork.CompleteAsync();

            // Send notification to Client
            var coachProfile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == coachId)).FirstOrDefault();
            var coachName = coachProfile?.FullName ?? "Your coach";
            var actionText = approve ? "accepted" : "rejected";
            await _notificationService.SendAsync(new NotificationSendRequest
            {
                UserId = clientId,
                Type = "connection_response",
                Title = approve ? "Connection request accepted" : "Connection request rejected",
                Body = $"Coach {coachName} has {actionText} your connection request.",
                ScheduledAt = null
            });

            return true;
        }

        public async Task<IEnumerable<CoachClientSummaryResponse>> GetMyClientsAsync(Guid coachId)
        {
            var connections = await _unitOfWork.CoachConnections.FindAsync(
                c => c.CoachId == coachId && (c.Status == "Pending" || c.Status == "Connected"));

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

                var pendingRouteRequests = await _unitOfWork.PtReviewRequests.FindAsync(r =>
                    r.UserId == conn.ClientId
                    && r.Status == "Pending"
                    && r.CreatedByRole != "Coach");
                var pendingRouteApprovalCount = pendingRouteRequests.Count(request =>
                    IsRouteApprovalRequest(request)
                    && IsRouteApprovalAssignedToCoach(request, coachId));

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
                    PendingRouteApprovalCount = pendingRouteApprovalCount,
                    ConnectedAt = conn.UpdatedAt
                });
            }

            return results.OrderByDescending(x => x.ConnectedAt);
        }

        public async Task<IEnumerable<MyCoachResponse>> GetMyCoachesAsync(Guid clientId)
        {
            var connections = await _unitOfWork.CoachConnections.FindAsync(c =>
                c.ClientId == clientId && (c.Status == "Pending" || c.Status == "Connected"));
            var results = new List<MyCoachResponse>();
            foreach (var connection in connections)
            {
                var coachProfile = (await _unitOfWork.CoachProfiles.FindAsync(c =>
                        c.UserId == connection.CoachId
                        && c.IsActive
                        && c.ApplicationStatus == "Approved"
                        && c.User != null
                        && c.User.IsActive
                        && c.User.Role != null
                        && c.User.Role.Name == "Coach",
                        asNoTracking: true))
                    .FirstOrDefault();
                if (coachProfile == null) continue;
                var profile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == connection.CoachId)).FirstOrDefault();
                results.Add(new MyCoachResponse
                {
                    Id = coachProfile.Id,
                    UserId = coachProfile.UserId,
                    FullName = profile?.FullName ?? "MenuGreen Expert",
                    AvatarUrl = profile?.AvatarUrl ?? string.Empty,
                    Specialty = coachProfile.Specialty,
                    Headline = coachProfile.Headline,
                    Bio = coachProfile.Bio,
                    ExperienceYears = coachProfile.ExperienceYears,
                    CertificateUrl = coachProfile.CertificateUrl,
                    City = coachProfile.City,
                    Languages = ParseStringList(coachProfile.LanguagesJson),
                    CoachingStyles = ParseStringList(coachProfile.CoachingStylesJson),
                    ClientLevels = ParseStringList(coachProfile.ClientLevelsJson),
                    Certificates = ParseCertificates(coachProfile.CertificatesJson),
                    GalleryUrls = ParseStringList(coachProfile.GalleryUrlsJson),
                    Achievements = coachProfile.Achievements,
                    ApplicationStatus = coachProfile.ApplicationStatus,
                    PriceVnd = coachProfile.PriceVnd,
                    IsActive = coachProfile.IsActive,
                    CreatedAt = coachProfile.CreatedAt,
                    ConnectionStatus = connection.Status,
                    IsAccessGranted = connection.IsAccessGranted,
                    ConnectedAt = connection.UpdatedAt
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
                ?? throw new Exception("Active connection with this coach not found.");

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
                ?? throw new Exception("Active connection with this coach not found.");

            connection.IsAccessGranted = false;
            connection.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.CoachConnections.Update(connection);
            await _unitOfWork.CompleteAsync();

            return true;
        }

        public async Task<bool> DisconnectCoachAsync(Guid clientId, Guid coachId)
        {
            var coachProf = await _unitOfWork.CoachProfiles.GetByIdAsync(coachId);
            var coachUserId = coachProf != null ? coachProf.UserId : coachId;

            var connection = (await _unitOfWork.CoachConnections.FindAsync(
                c => c.ClientId == clientId && c.CoachId == coachUserId)).FirstOrDefault()
                ?? throw new Exception("Connection with this coach not found.");

            _unitOfWork.CoachConnections.Remove(connection);
            await _unitOfWork.CompleteAsync();

            return true;
        }

        private async Task EnsureAccessAllowedAsync(Guid coachId, Guid clientId)
        {
            var connection = (await _unitOfWork.CoachConnections.FindAsync(
                c => c.CoachId == coachId && c.ClientId == clientId && c.Status == "Connected")).FirstOrDefault();

            if (connection == null)
            {
                throw new UnauthorizedAccessException("You do not have a valid coaching connection with this student.");
            }

            if (!connection.IsAccessGranted)
            {
                throw new UnauthorizedAccessException("Student has not granted you access to their health data.");
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
                FullName = profile?.FullName ?? "Not set",
                AvatarUrl = profile?.AvatarUrl ?? string.Empty,
                HeightCm = health?.HeightCm,
                WeightKg = health?.WeightKg,
                TargetWeightKg = health?.TargetWeightKg,
                BodyFatPercent = health?.BodyFatPercent,
                ActivityLevel = health?.ActivityLevel,
                Goal = health?.Goal,
                Bmi = health?.Bmi,
                BmrKcal = health?.BmrKcal,
                TdeeKcal = health?.TdeeKcal,
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
            var coachName = coachProfile?.FullName ?? "Your coach";

            // Trigger notification to Client
            var bodyText = $"Coach {coachName} sent you new feedback: \"{request.Content}\"";
            await _notificationService.SendAsync(new NotificationSendRequest
            {
                UserId = clientId,
                Type = "coach_feedback",
                Title = "New advice from Coach",
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
                    CoachName = coachProfile?.FullName ?? "Coach",
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
            await EnsureRoutePlanAssignedToCoachAsync(coachId, clientId, planId);

            var plan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(planId)
                ?? throw new Exception("Meal plan not found.");
            
            if (plan.UserId != clientId)
            {
                throw new Exception("This meal plan does not belong to the specified student.");
            }

            if (string.Equals(plan.Status, "Approved", StringComparison.OrdinalIgnoreCase))
            {
                throw new Exception("Lộ trình đã duyệt không thể chỉnh sửa. Hãy tạo lộ trình mới.");
            }

            plan.Title = request.Title;
            plan.PlanType = request.PlanType;
            plan.StartDate = request.StartDate;
            plan.EndDate = request.EndDate;
            plan.TargetCalories = request.TargetCalories;
            plan.MinCalories = request.MinCalories;
            plan.MaxCalories = request.MaxCalories;
            plan.CoachNotes = request.CoachNotes?.Trim();
            plan.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.MealPlanHeaders.Update(plan);

            // A null Items list means header-only adjustment.
            if (request.Items != null)
            {
                var existingItems = await _unitOfWork.MealPlanItems.FindAsync(x => x.MealPlanId == plan.Id);
                _unitOfWork.MealPlanItems.RemoveRange(existingItems);
                await _unitOfWork.CompleteAsync();
                foreach (var item in request.Items)
                {
                    await _unitOfWork.MealPlanItems.AddAsync(new MealPlanItem
                    {
                        Id = Guid.NewGuid(), MealPlanId = plan.Id, MealType = item.MealType,
                        FoodId = item.FoodId, RecipeId = item.RecipeId, PlannedDate = item.PlannedDate,
                        ScheduledTime = item.ScheduledTime, TargetCalories = item.TargetCalories,
                        QuantityG = (decimal?)item.QuantityG,
                        IsCompleted = item.IsCompleted, CreatedAt = DateTime.UtcNow
                    });
                }
            }

            await _unitOfWork.CompleteAsync();

            // Send notification to Client
            var coachProfile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == coachId)).FirstOrDefault();
            var coachName = coachProfile?.FullName ?? "Coach";
            await _notificationService.SendAsync(new NotificationSendRequest
            {
                UserId = clientId,
                Type = "meal_plan_adjusted",
                Title = "Meal plan has been adjusted",
                Body = $"Coach {coachName} has directly adjusted your meal plan.",
                ScheduledAt = null
            });

            return await MapMealPlanAsync(plan);
        }

        public async Task<HealthProfileResponse> AdjustClientHealthTargetsAsync(Guid coachId, Guid clientId, ClientHealthTargetsAdjustRequest request)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);

            var health = (await _unitOfWork.HealthProfiles.FindAsync(h => h.UserId == clientId)).FirstOrDefault()
                ?? throw new Exception("Student has not set up their health profile.");

            health.TargetCalories = request.TargetCalories;
            health.TargetProteinG = request.TargetProteinG;
            health.TargetCarbsG = request.TargetCarbsG;
            health.TargetFatG = request.TargetFatG;
            health.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.HealthProfiles.Update(health);
            await _unitOfWork.CompleteAsync();

            // Send notification to Client
            var coachProfile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == coachId)).FirstOrDefault();
            var coachName = coachProfile?.FullName ?? "Coach";
            await _notificationService.SendAsync(new NotificationSendRequest
            {
                UserId = clientId,
                Type = "targets_adjusted",
                Title = "Nutrition targets have been updated",
                Body = $"Coach {coachName} has updated your Calorie/Macros targets.",
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
                var calories = item.TargetCalories;
                decimal? protein = item.ProteinG;
                decimal? carbs = item.CarbsG;
                decimal? fat = item.FatG;

                if (food != null)
                {
                    calories ??= (int)Math.Round(food.CaloriesKcal ?? 0);
                    protein ??= food.ProteinG;
                    carbs ??= food.CarbsG;
                    fat ??= food.FatG;
                }
                else if (recipe != null)
                {
                    var nutrition = await _recipeService.GetNutritionAsync(recipe.Id);
                    calories ??= (int)Math.Round(nutrition.CaloriesKcal);
                    protein ??= nutrition.ProteinG;
                    carbs ??= nutrition.CarbsG;
                    fat ??= nutrition.FatG;
                }

                responseItems.Add(new MealPlanItemResponse
                {
                    Id = item.Id,
                    MealPlanId = item.MealPlanId,
                    MealType = item.MealType,
                    FoodId = item.FoodId,
                    RecipeId = item.RecipeId,
                    PlannedDate = item.PlannedDate,
                    ScheduledTime = item.ScheduledTime,
                    TargetCalories = calories,
                    QuantityG = item.QuantityG ?? food?.DefaultServingG ?? 100m,
                    ProteinG = protein,
                    CarbsG = carbs,
                    FatG = fat,
                    IsCompleted = item.IsCompleted,
                    FoodName = food?.NameVi,
                    RecipeName = recipe?.Title,
                    SourceEntityType = item.FoodId.HasValue ? "Food" : item.RecipeId.HasValue ? "Recipe" : null,
                    Status = item.IsCompleted ? "done" : "planned",
                    EstimatedPriceVnd = price
                });
            }

            var resolvedPlanType = entity.PlanType;
            if (entity.StartDate == entity.EndDate || (entity.Title != null && entity.Title.StartsWith("Daily plan", StringComparison.OrdinalIgnoreCase)))
            {
                resolvedPlanType = "DAILY";
            }
            var resolvedStatus = IsApprovalOutdated(entity)
                ? "Active"
                : entity.Status;

            return new MealPlanResponse
            {
                Id = entity.Id,
                Title = entity.Title ?? string.Empty,
                PlanType = resolvedPlanType ?? "DAILY",
                StartDate = entity.StartDate,
                EndDate = entity.EndDate,
                TargetCalories = entity.TargetCalories,
                MinCalories = entity.MinCalories,
                MaxCalories = entity.MaxCalories,
                CoachNotes = entity.CoachNotes,
                GeneratedBy = entity.GeneratedBy,
                Status = resolvedStatus,
                ApprovedAt = resolvedStatus == "Approved" ? entity.ApprovedAt : null,
                IsActive = entity.IsActive,
                TotalCalories = responseItems.Sum(x => x.TargetCalories ?? 0),
                TotalProteinG = (int)Math.Round(responseItems.Sum(x => x.ProteinG ?? 0)),
                TotalCarbsG = (int)Math.Round(responseItems.Sum(x => x.CarbsG ?? 0)),
                TotalFatG = (int)Math.Round(responseItems.Sum(x => x.FatG ?? 0)),
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

        public async Task<IEnumerable<MealPlanResponse>> GetClientMealPlansAsync(Guid coachId, Guid clientId, DateOnly? from, DateOnly? to, string? planType)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);

            var plans = await _unitOfWork.MealPlanHeaders.FindAsync(x => x.UserId == clientId && x.IsActive);
            var query = plans.AsEnumerable();
            var routeAssignments = await GetRoutePlanAssignmentsAsync(clientId);
            query = query.Where(plan =>
                !routeAssignments.TryGetValue(plan.Id, out var assignedCoachId)
                || assignedCoachId == coachId);

            if (from.HasValue && to.HasValue)
            {
                // Filter theo ngày bắt đầu của plan (StartDate) nằm trong khoảng [from, to].
                // Lý do: tab "Lộ trình" của Coach đang hiển thị các plan "được tạo vào"
                // ngày/tuần/tháng đang xem, không phải các plan "trải dài qua" khoảng đó.
                // Dùng overlap (StartDate <= to && EndDate >= from) sẽ trả về cùng plan
                // cho mọi filter (ví dụ plan daily thực tế bị lưu StartDate=26/07, EndDate=02/08
                // do picker mặc định 1 tuần), làm user tưởng filter không hoạt động.
                query = query.Where(x => x.StartDate >= from.Value && x.StartDate <= to.Value);
            }
            else if (from.HasValue)
            {
                query = query.Where(x => x.StartDate >= from.Value);
            }
            else if (to.HasValue)
            {
                query = query.Where(x => x.StartDate <= to.Value);
            }

            if (!string.IsNullOrEmpty(planType))
            {
                var targetType = planType.Trim().ToUpperInvariant();
                if (targetType == "DAILY")
                {
                    query = query.Where(x =>
                        string.Equals(x.PlanType, "DAILY", StringComparison.OrdinalIgnoreCase) ||
                        x.StartDate == x.EndDate ||
                        (x.Title != null && x.Title.StartsWith("Daily plan", StringComparison.OrdinalIgnoreCase)));
                }
                else if (targetType == "WEEKLY")
                {
                    query = query.Where(x =>
                        string.Equals(x.PlanType, "WEEKLY", StringComparison.OrdinalIgnoreCase) &&
                        x.StartDate != x.EndDate &&
                        !(x.Title != null && x.Title.StartsWith("Daily plan", StringComparison.OrdinalIgnoreCase)));
                }
                else if (targetType == "MONTHLY")
                {
                    query = query.Where(x =>
                        string.Equals(x.PlanType, "MONTHLY", StringComparison.OrdinalIgnoreCase));
                }
            }

            var responses = new List<MealPlanResponse>();
            foreach (var plan in query.OrderByDescending(p => p.StartDate).ThenByDescending(p => p.CreatedAt))
            {
                responses.Add(await MapMealPlanAsync(plan));
            }
            return responses;
        }

        public async Task<MealPlanResponse> GetClientMealPlanDetailAsync(Guid coachId, Guid clientId, Guid planId)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);
            await EnsureRoutePlanAssignedToCoachAsync(coachId, clientId, planId);

            var plan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(planId);
            if (plan == null || plan.UserId != clientId)
            {
                throw new Exception("Meal plan not found.");
            }
            return await MapMealPlanAsync(plan);
        }

        public async Task<MealPlanResponse> CreateClientMealPlanAsync(Guid coachId, Guid clientId, MealPlanUpsertRequest request)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);

            var plan = new MealPlanHeader
            {
                Id = Guid.NewGuid(),
                UserId = clientId,
                Title = request.Title ?? $"Client plan {request.StartDate:yyyy-MM-dd}",
                PlanType = request.PlanType ?? "DAILY",
                StartDate = request.StartDate ?? DateOnly.FromDateTime(DateTime.UtcNow),
                EndDate = request.EndDate ?? DateOnly.FromDateTime(DateTime.UtcNow),
                TargetCalories = request.TargetCalories,
                MinCalories = request.MinCalories,
                MaxCalories = request.MaxCalories,
                CoachNotes = request.CoachNotes?.Trim(),
                GeneratedBy = "COACH",
                Status = "Draft",
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.MealPlanHeaders.AddAsync(plan);
            await _unitOfWork.CompleteAsync();

            if (request.Items != null && request.Items.Any())
            {
                foreach (var item in request.Items)
                {
                    await _unitOfWork.MealPlanItems.AddAsync(new MealPlanItem
                    {
                        Id = Guid.NewGuid(),
                        MealPlanId = plan.Id,
                        MealType = item.MealType,
                        FoodId = item.FoodId,
                        RecipeId = item.RecipeId,
                        PlannedDate = item.PlannedDate ?? plan.StartDate,
                        ScheduledTime = item.ScheduledTime,
                        TargetCalories = item.TargetCalories,
                        QuantityG = (decimal?)item.QuantityG,
                        IsCompleted = false,
                        Origin = "coach",
                        CreatedAt = DateTime.UtcNow
                    });
                }
                await _unitOfWork.CompleteAsync();
            }

            return await MapMealPlanAsync(plan);
        }

        public async Task<MealPlanResponse> SubmitClientMealPlanAsync(
            Guid coachId,
            Guid clientId,
            Guid planId,
            CoachSubmitMealPlanRequest? request)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);
            await EnsureRoutePlanAssignedToCoachAsync(coachId, clientId, planId);

            var plan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(planId);
            if (plan == null || plan.UserId != clientId)
            {
                throw new Exception("Meal plan not found.");
            }

            // A Gymer -> PT route-approval request owns the approval flow.
            // Editing that plan must not turn it into a Coach -> Gymer
            // PersonalProgram that the Gymer has to accept again.
            var pendingRouteRequests = (await _unitOfWork.PtReviewRequests.FindAsync(r =>
                r.UserId == clientId
                && r.Status == "Pending"
                && r.CreatedByRole != "Coach"))
                .Where(IsRouteApprovalRequest)
                .OrderByDescending(r => r.CreatedAt)
                .ToList();
            var matchedRequest = FindMatchingRouteApprovalRequest(
                plan,
                pendingRouteRequests
            );

            if (
                string.Equals(plan.Status, "Approved", StringComparison.OrdinalIgnoreCase)
                && !IsApprovalOutdated(plan)
            )
            {
                throw new Exception("Lộ trình này đã được duyệt và gửi cho học viên.");
            }
            if (
                string.Equals(
                    plan.Status,
                    "PendingAcceptance",
                    StringComparison.OrdinalIgnoreCase)
                && matchedRequest == null
            )
            {
                throw new Exception("Lộ trình đang chờ Gymer chấp nhận.");
            }

            // A plan created by the PT must be accepted by the Gymer before it
            // becomes active. Keep the existing Gymer -> PT approval path below
            // for plans originally created by the student.
            if (
                matchedRequest == null
                && string.Equals(
                    plan.GeneratedBy,
                    "COACH",
                    StringComparison.OrdinalIgnoreCase
                )
            )
            {
                var mappedPlan = await MapMealPlanAsync(plan);
                var health = (await _unitOfWork.HealthProfiles.FindAsync(
                    item => item.UserId == clientId
                )).FirstOrDefault();
                var startDate =
                    plan.StartDate ?? DateOnly.FromDateTime(DateTime.UtcNow.AddHours(7));
                var endDate = plan.EndDate ?? startDate;
                var durationDays = Math.Max(1, endDate.DayNumber - startDate.DayNumber + 1);
                var durationWeeks = Math.Clamp(
                    (int)Math.Ceiling(durationDays / 7d),
                    1,
                    52
                );
                var targetCalories =
                    plan.TargetCalories ?? health?.TargetCalories ?? 2000;
                var minCalories = request?.MinCalories ?? plan.MinCalories;
                var maxCalories = request?.MaxCalories ?? plan.MaxCalories;
                var coachNotes = string.IsNullOrWhiteSpace(request?.Notes)
                    ? plan.CoachNotes
                    : request!.Notes!.Trim();

                await _ptReviewService.CreatePersonalProgramAsync(
                    coachId,
                    new CreatePersonalProgramRequest
                    {
                        ClientId = clientId,
                        Title = plan.Title ?? $"Lộ trình {startDate:dd/MM/yyyy}",
                        Description =
                            $"Lộ trình {plan.PlanType ?? "DAILY"} từ "
                            + $"{startDate:dd/MM/yyyy} đến {endDate:dd/MM/yyyy}.",
                        DurationWeeks = durationWeeks,
                        WeekStartDate = startDate,
                        TargetCaloriesDaily = targetCalories,
                        MinCalories = minCalories,
                        MaxCalories = maxCalories,
                        TargetProteinG = Math.Clamp(
                            health?.TargetProteinG ?? 120,
                            20,
                            400
                        ),
                        TargetCarbsG = Math.Clamp(
                            health?.TargetCarbsG ?? 250,
                            50,
                            600
                        ),
                        TargetFatG = Math.Clamp(
                            health?.TargetFatG ?? 70,
                            20,
                            250
                        ),
                        CoachComment = coachNotes,
                        MealPlanId = plan.Id,
                        PlanType = plan.PlanType,
                        StartDate = startDate,
                        EndDate = endDate,
                        Meals = mappedPlan.Items.Select(item =>
                            new PersonalProgramMealDto
                            {
                                Id = item.Id,
                                PlannedDate = item.PlannedDate ?? startDate,
                                MealType = item.MealType ?? "snack",
                                FoodId = item.FoodId,
                                FoodName = item.FoodName,
                                RecipeId = item.RecipeId,
                                RecipeName = item.RecipeName,
                                TargetCalories = item.TargetCalories,
                                QuantityG = item.QuantityG,
                                ProteinG = item.ProteinG,
                                CarbsG = item.CarbsG,
                                FatG = item.FatG
                            }
                        ).ToList()
                    }
                );

                return await MapMealPlanAsync(plan);
            }

            var now = DateTime.UtcNow;
            if (matchedRequest != null)
            {
                plan.GeneratedBy = "PT_APPROVED";
            }
            plan.Status = "Approved";
            plan.ApprovedAt = now;
            plan.UpdatedAt = now;
            _unitOfWork.MealPlanHeaders.Update(plan);

            // The Gymer-facing "Tôi gửi PT" tab is backed by PtReviewRequest,
            // not MealPlanHeader. Mark the latest matching route request as
            // Reviewed so it no longer remains "Chờ phản hồi".
            if (matchedRequest != null)
            {
                matchedRequest.Status = "Reviewed";
                matchedRequest.ReviewedAt = now;
                matchedRequest.PtComment = string.IsNullOrWhiteSpace(request?.Notes)
                    ? "PT đã duyệt và gửi lộ trình dinh dưỡng."
                    : request!.Notes!.Trim();
                if (plan.TargetCalories.HasValue)
                {
                    matchedRequest.SuggestedCalorieTarget = plan.TargetCalories;
                }
                _unitOfWork.PtReviewRequests.Update(matchedRequest);
            }

            await _unitOfWork.CompleteAsync();

            var coachProfile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == coachId)).FirstOrDefault();
            var coachName = coachProfile?.FullName ?? "Coach";
            var noteMsg = !string.IsNullOrWhiteSpace(request?.Notes)
                ? $" Lời nhắn: {request!.Notes}"
                : "";
            await _notificationService.SendAsync(new NotificationSendRequest
            {
                UserId = clientId,
                Type = "meal_plan_approved",
                Title = "PT đã duyệt lộ trình ăn uống",
                Body = $"Coach {coachName} đã duyệt lộ trình ăn uống của bạn.{noteMsg}",
                ScheduledAt = null,
                ActionUrl = matchedRequest == null
                    ? null
                    : $"gymer_route_approval:{matchedRequest.Id}"
            });

            return await MapMealPlanAsync(plan);
        }

        private static bool IsApprovalOutdated(MealPlanHeader plan)
        {
            return string.Equals(
                    plan.Status,
                    "Approved",
                    StringComparison.OrdinalIgnoreCase)
                && plan.ApprovedAt.HasValue
                && plan.UpdatedAt.HasValue
                && plan.UpdatedAt.Value > plan.ApprovedAt.Value;
        }

        private static bool IsRouteApprovalRequest(PtReviewRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.ReportDataJson))
                {
                    return true;
                }

                using var document = System.Text.Json.JsonDocument.Parse(request.ReportDataJson);
                if (!document.RootElement.TryGetProperty("requestType", out var requestType))
                {
                    return true;
                }

                var value = requestType.GetString();
                return string.IsNullOrWhiteSpace(value)
                    || value.Equals("RouteApproval", StringComparison.OrdinalIgnoreCase);
            }
            catch
            {
                // Legacy requests did not always include requestType and were
                // treated as RouteApproval by PtReviewService.
                return true;
            }
        }

        private static PtReviewRequest? FindMatchingRouteApprovalRequest(
            MealPlanHeader plan,
            IReadOnlyCollection<PtReviewRequest> pendingRequests)
        {
            var exactMatch = pendingRequests.FirstOrDefault(request =>
                GetRouteApprovalMealPlanId(request) == plan.Id
            );
            if (exactMatch != null)
            {
                return exactMatch;
            }

            // New requests carry MealPlanId and are matched exactly. This
            // fallback supports requests created before MealPlanId was stored,
            // but never claims a plan that was genuinely created by the PT.
            if (string.Equals(
                plan.GeneratedBy,
                "COACH",
                StringComparison.OrdinalIgnoreCase
            ))
            {
                return null;
            }

            if (plan.StartDate.HasValue || plan.EndDate.HasValue)
            {
                var planStart = plan.StartDate ?? plan.EndDate!.Value;
                var planEnd = plan.EndDate ?? plan.StartDate!.Value;
                var dateMatch = pendingRequests.FirstOrDefault(request =>
                    !GetRouteApprovalMealPlanId(request).HasValue
                    && planStart <= request.WeekStartDate.AddDays(6)
                    && planEnd >= request.WeekStartDate
                );
                if (dateMatch != null)
                {
                    return dateMatch;
                }
            }

            return null;
        }

        private static Guid? GetRouteApprovalMealPlanId(PtReviewRequest request)
        {
            try
            {
                using var document = System.Text.Json.JsonDocument.Parse(
                    request.ReportDataJson
                );
                if (
                    document.RootElement.TryGetProperty("mealPlanId", out var mealPlanId)
                    && mealPlanId.ValueKind == System.Text.Json.JsonValueKind.String
                    && Guid.TryParse(mealPlanId.GetString(), out var parsed)
                )
                {
                    return parsed;
                }
            }
            catch
            {
                // Legacy snapshots may be empty or malformed.
            }

            return null;
        }

        private static bool IsRouteApprovalAssignedToCoach(
            PtReviewRequest request,
            Guid coachId)
        {
            var assignedCoachId = GetRouteApprovalAssignedCoachId(request);
            return !assignedCoachId.HasValue || assignedCoachId.Value == coachId;
        }

        private static Guid? GetRouteApprovalAssignedCoachId(
            PtReviewRequest request)
        {
            try
            {
                using var document = JsonDocument.Parse(request.ReportDataJson);
                if (
                    document.RootElement.TryGetProperty(
                        "assignedCoachId",
                        out var assignedCoachId)
                    && assignedCoachId.ValueKind == JsonValueKind.String
                    && Guid.TryParse(assignedCoachId.GetString(), out var parsed)
                )
                {
                    return parsed;
                }
            }
            catch
            {
                // Legacy snapshots are scoped by the active connection.
            }

            return null;
        }

        private async Task<Dictionary<Guid, Guid>> GetRoutePlanAssignmentsAsync(
            Guid clientId)
        {
            var requests = (await _unitOfWork.PtReviewRequests.FindAsync(request =>
                    request.UserId == clientId
                    && request.CreatedByRole != "Coach"))
                .Where(IsRouteApprovalRequest)
                .OrderBy(request => request.CreatedAt);

            var assignments = new Dictionary<Guid, Guid>();
            foreach (var request in requests)
            {
                var planId = GetRouteApprovalMealPlanId(request);
                var assignedCoachId = GetRouteApprovalAssignedCoachId(request);
                if (planId.HasValue && assignedCoachId.HasValue)
                {
                    assignments[planId.Value] = assignedCoachId.Value;
                }
            }

            return assignments;
        }

        private async Task EnsureRoutePlanAssignedToCoachAsync(
            Guid coachId,
            Guid clientId,
            Guid planId)
        {
            var assignments = await GetRoutePlanAssignmentsAsync(clientId);
            if (
                assignments.TryGetValue(planId, out var assignedCoachId)
                && assignedCoachId != coachId
            )
            {
                throw new UnauthorizedAccessException(
                    "This meal plan was sent to another coach.");
            }
        }

        public async Task DeleteClientMealPlanAsync(Guid coachId, Guid clientId, Guid planId)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);
            await EnsureRoutePlanAssignedToCoachAsync(coachId, clientId, planId);

            var plan = await _unitOfWork.MealPlanHeaders.GetByIdAsync(planId);
            if (plan == null || plan.UserId != clientId)
            {
                throw new Exception("Meal plan not found.");
            }

            plan.IsActive = false;
            plan.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.MealPlanHeaders.Update(plan);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<MealPlanResponse?> GetClientMealPlanAsync(Guid coachId, Guid clientId, DateOnly date)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);
            return await _mealPlanService.GetByDateAsync(clientId, date);
        }

        public async Task<object> GetClientSuggestionsAsync(
            Guid coachId,
            Guid clientId,
            DateOnly? date,
            int targetCalories = 0,
            int? minCalories = null,
            int? maxCalories = null,
            decimal? minProteinG = null,
            decimal? maxProteinG = null,
            int top = 10)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);
            if (
                minCalories.HasValue
                && maxCalories.HasValue
                && minCalories.Value > maxCalories.Value
            )
            {
                throw new Exception("Calo tối thiểu không được lớn hơn calo tối đa.");
            }
            if (
                minProteinG.HasValue
                && maxProteinG.HasValue
                && minProteinG.Value > maxProteinG.Value
            )
            {
                throw new Exception("Protein tối thiểu không được lớn hơn protein tối đa.");
            }

            var planDate = date ?? DateOnly.FromDateTime(DateTime.UtcNow.AddHours(7));
            if (targetCalories == 0)
            {
                var health = (await _unitOfWork.HealthProfiles.FindAsync(h => h.UserId == clientId)).FirstOrDefault();
                targetCalories = health?.TargetCalories ?? 2000;
                var scoped = await ResolveClientGymConfigurationAsync(
                    clientId,
                    planDate
                );
                targetCalories = scoped.TargetCalories ?? targetCalories;
                minCalories ??= scoped.MinCalories;
                maxCalories ??= scoped.MaxCalories;
            }

            if (minCalories.HasValue && targetCalories < minCalories.Value)
            {
                targetCalories = minCalories.Value;
            }
            if (maxCalories.HasValue && targetCalories > maxCalories.Value)
            {
                targetCalories = maxCalories.Value;
            }

            return await _dailyStarterService.GetRecommendationsAsync(clientId, new RecommendationRequest
            {
                TargetCalories = targetCalories > 0 ? targetCalories : null,
                MinCalories = minCalories,
                MaxCalories = maxCalories,
                MinProteinG = minProteinG,
                MaxProteinG = maxProteinG,
                Date = planDate,
                Top = top
            });
        }

        public async Task<object> GetClientGymConfigurationAsync(
            Guid coachId,
            Guid clientId,
            DateOnly? date)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);
            var planDate = date ?? DateOnly.FromDateTime(DateTime.UtcNow.AddHours(7));
            var health = (await _unitOfWork.HealthProfiles.FindAsync(
                item => item.UserId == clientId
            )).FirstOrDefault();
            var scoped = await ResolveClientGymConfigurationAsync(
                clientId,
                planDate
            );
            var target = scoped.TargetCalories ?? health?.TargetCalories ?? 2000;
            if (scoped.MinCalories.HasValue && target < scoped.MinCalories.Value)
                target = scoped.MinCalories.Value;
            if (scoped.MaxCalories.HasValue && target > scoped.MaxCalories.Value)
                target = scoped.MaxCalories.Value;

            return new
            {
                Date = planDate.ToString("yyyy-MM-dd"),
                TargetCalories = target,
                scoped.MinCalories,
                scoped.MaxCalories,
                scoped.HasConfiguration,
                scoped.Scope
            };
        }

        public async Task<CoachApplicationResponse> GetMyApplicationAsync(Guid userId)
        {
            var application = (await _unitOfWork.CoachProfiles.FindAsync(x => x.UserId == userId))
                .FirstOrDefault() ?? throw new Exception("Coach application not found.");
            return await MapApplicationAsync(application);
        }

        public async Task<CoachApplicationResponse> SaveApplicationDraftAsync(
            Guid userId,
            CoachApplicationUpsertRequest request)
        {
            var application = await GetApplicationEntityByUserIdAsync(userId);
            if (application.ApplicationStatus == "PendingReview")
            {
                throw new Exception("The application is being reviewed and cannot be edited.");
            }
            if (application.ApplicationStatus == "Suspended")
            {
                throw new Exception("The coach account is suspended.");
            }

            await ApplyApplicationChangesAsync(application, request);
            if (application.ApplicationStatus != "Approved")
            {
                application.ApplicationStatus = "Draft";
                application.IsActive = false;
            }
            application.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.CoachProfiles.Update(application);
            await _unitOfWork.CompleteAsync();
            return await MapApplicationAsync(application);
        }

        public async Task<CoachApplicationResponse> SubmitApplicationAsync(
            Guid userId,
            CoachApplicationUpsertRequest request)
        {
            var application = await GetApplicationEntityByUserIdAsync(userId);
            if (application.ApplicationStatus == "PendingReview")
            {
                throw new Exception("The application is already being reviewed.");
            }
            if (application.ApplicationStatus == "Suspended")
            {
                throw new Exception("The coach account is suspended.");
            }

            ValidateApplicationForSubmit(request);
            await ApplyApplicationChangesAsync(application, request);
            application.ApplicationStatus = "PendingReview";
            application.IsActive = false;
            application.ReviewNote = null;
            application.SubmittedAt = DateTime.UtcNow;
            application.ReviewedAt = null;
            application.ReviewedByUserId = null;
            application.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.CoachProfiles.Update(application);
            await _unitOfWork.CompleteAsync();
            return await MapApplicationAsync(application);
        }

        public async Task<IEnumerable<CoachApplicationResponse>> GetApplicationsForAdminAsync(string? status)
        {
            var applications = await _unitOfWork.CoachProfiles.GetAllAsync();
            var filtered = string.IsNullOrWhiteSpace(status)
                ? applications
                : applications.Where(x => string.Equals(
                    x.ApplicationStatus,
                    status.Trim(),
                    StringComparison.OrdinalIgnoreCase));

            var result = new List<CoachApplicationResponse>();
            foreach (var application in filtered
                .OrderByDescending(x => x.SubmittedAt ?? x.UpdatedAt))
            {
                result.Add(await MapApplicationAsync(application));
            }
            return result;
        }

        public async Task<CoachApplicationResponse> GetApplicationForAdminAsync(Guid applicationId)
        {
            var application = await _unitOfWork.CoachProfiles.GetByIdAsync(applicationId)
                ?? throw new Exception("Coach application not found.");
            return await MapApplicationAsync(application);
        }

        public async Task<CoachApplicationResponse> ReviewApplicationAsync(
            Guid adminUserId,
            Guid applicationId,
            CoachApplicationReviewRequest request)
        {
            var application = await _unitOfWork.CoachProfiles.GetByIdAsync(applicationId)
                ?? throw new Exception("Coach application not found.");
            var decision = request.Decision.Trim();
            if (!string.Equals(decision, "Approve", StringComparison.OrdinalIgnoreCase)
                && string.IsNullOrWhiteSpace(request.Reason))
            {
                throw new Exception("A reason is required for this decision.");
            }

            if (string.Equals(decision, "Approve", StringComparison.OrdinalIgnoreCase))
            {
                application.ApplicationStatus = "Approved";
                application.IsActive = true;
                application.ReviewNote = null;
            }
            else if (string.Equals(decision, "NeedsRevision", StringComparison.OrdinalIgnoreCase))
            {
                application.ApplicationStatus = "NeedsRevision";
                application.IsActive = false;
                application.ReviewNote = request.Reason?.Trim();
            }
            else if (string.Equals(decision, "Reject", StringComparison.OrdinalIgnoreCase))
            {
                application.ApplicationStatus = "Rejected";
                application.IsActive = false;
                application.ReviewNote = request.Reason?.Trim();
            }
            else if (string.Equals(decision, "Suspend", StringComparison.OrdinalIgnoreCase))
            {
                application.ApplicationStatus = "Suspended";
                application.IsActive = false;
                application.ReviewNote = request.Reason?.Trim();
            }
            else
            {
                throw new Exception("Unsupported review decision.");
            }

            application.ReviewedAt = DateTime.UtcNow;
            application.ReviewedByUserId = adminUserId;
            application.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.CoachProfiles.Update(application);
            await _unitOfWork.CompleteAsync();

            var approved = application.ApplicationStatus == "Approved";
            await _notificationService.SendAsync(new NotificationSendRequest
            {
                UserId = application.UserId,
                Type = "coach_application_review",
                Title = approved ? "Hồ sơ PT đã được duyệt" : "Hồ sơ PT cần cập nhật",
                Body = approved
                    ? "Hồ sơ của bạn đã được xác minh. Bạn có thể bắt đầu nhận học viên."
                    : application.ReviewNote ?? "Vui lòng kiểm tra lại hồ sơ PT của bạn.",
                ScheduledAt = null
            });

            return await MapApplicationAsync(application);
        }

        private async Task<ClientGymConfiguration> ResolveClientGymConfigurationAsync(
            Guid clientId,
            DateOnly date)
        {
            var profile = (await _unitOfWork.UserAiProfiles.FindAsync(
                item => item.UserId == clientId
            )).FirstOrDefault();
            if (string.IsNullOrWhiteSpace(profile?.Preferences))
            {
                return new ClientGymConfiguration();
            }

            try
            {
                using var document = JsonDocument.Parse(profile.Preferences);
                var root = document.RootElement;
                var dateString = date.ToString("yyyy-MM-dd");
                var monday = date.AddDays(
                    -(7 + (date.DayOfWeek - DayOfWeek.Monday)) % 7
                );
                var weekString = monday.ToString("yyyy-MM-dd");
                var monthString = date.ToString("yyyy-MM");

                var schedule =
                    root.TryGetProperty("weeklyTrainingSchedule", out var scheduleNode)
                    && scheduleNode.ValueKind == JsonValueKind.String
                        ? scheduleNode.GetString() ?? string.Empty
                        : string.Empty;
                var isTraining = schedule
                    .Split(',', StringSplitOptions.RemoveEmptyEntries)
                    .Select(day => day.Trim())
                    .Contains(
                        date.DayOfWeek.ToString(),
                        StringComparer.OrdinalIgnoreCase
                    );

                int? target = null;
                int? min = null;
                int? max = null;
                var hasConfiguration = false;
                var scope = "profile";

                if (
                    TryFindScopedElement(
                        root,
                        "dailyDetails",
                        "dateString",
                        dateString,
                        out var daily)
                )
                {
                    hasConfiguration = true;
                    scope = "day";
                    if (
                        daily.TryGetProperty("isTraining", out var trainingNode)
                        && (
                            trainingNode.ValueKind == JsonValueKind.True
                            || trainingNode.ValueKind == JsonValueKind.False
                        )
                    )
                    {
                        isTraining = trainingNode.GetBoolean();
                    }
                    if (TryReadInt32(daily, "customCalories", out var value))
                        target = value;
                    if (TryReadInt32(daily, "minCalories", out value))
                        min = value;
                    if (TryReadInt32(daily, "maxCalories", out value))
                        max = value;
                }

                if (
                    TryFindScopedElement(
                        root,
                        "weeklyDetails",
                        "weekStartDateString",
                        weekString,
                        out var weekly)
                )
                {
                    hasConfiguration = true;
                    if (scope == "profile") scope = "week";
                    if (
                        target == null
                        && TryReadInt32(weekly, "customCalories", out var value)
                    )
                        target = value;
                    if (min == null && TryReadInt32(weekly, "minCalories", out value))
                        min = value;
                    if (max == null && TryReadInt32(weekly, "maxCalories", out value))
                        max = value;
                }

                if (
                    TryFindScopedElement(
                        root,
                        "monthlyDetails",
                        "monthString",
                        monthString,
                        out var monthly)
                )
                {
                    hasConfiguration = true;
                    if (scope == "profile") scope = "month";
                    if (
                        target == null
                        && TryReadInt32(monthly, "customCalories", out var value)
                    )
                        target = value;
                    if (min == null && TryReadInt32(monthly, "minCalories", out value))
                        min = value;
                    if (max == null && TryReadInt32(monthly, "maxCalories", out value))
                        max = value;
                }

                if (target == null)
                {
                    if (
                        isTraining
                        && TryReadInt32(
                            root,
                            "trainingDayTargetCalories",
                            out var trainingCalories)
                    )
                        target = trainingCalories;
                    else if (
                        !isTraining
                        && TryReadInt32(
                            root,
                            "restDayTargetCalories",
                            out var restCalories)
                    )
                        target = restCalories;

                    if (min == null && TryReadInt32(root, "minCalories", out var value))
                        min = value;
                    if (max == null && TryReadInt32(root, "maxCalories", out value))
                        max = value;
                }

                return new ClientGymConfiguration
                {
                    TargetCalories = target,
                    MinCalories = min,
                    MaxCalories = max,
                    HasConfiguration = hasConfiguration,
                    Scope = scope
                };
            }
            catch (JsonException)
            {
                return new ClientGymConfiguration();
            }
        }

        private static bool TryFindScopedElement(
            JsonElement root,
            string arrayName,
            string keyName,
            string keyValue,
            out JsonElement matched)
        {
            matched = default;
            if (
                !root.TryGetProperty(arrayName, out var array)
                || array.ValueKind != JsonValueKind.Array
            )
            {
                return false;
            }

            foreach (var item in array.EnumerateArray())
            {
                if (
                    item.ValueKind == JsonValueKind.Object
                    && item.TryGetProperty(keyName, out var key)
                    && key.ValueKind == JsonValueKind.String
                    && key.GetString() == keyValue
                )
                {
                    matched = item;
                    return true;
                }
            }
            return false;
        }

        private static bool TryReadInt32(
            JsonElement parent,
            string propertyName,
            out int value)
        {
            value = default;
            return parent.ValueKind == JsonValueKind.Object
                && parent.TryGetProperty(propertyName, out var property)
                && property.ValueKind == JsonValueKind.Number
                && property.TryGetInt32(out value);
        }

        private sealed class ClientGymConfiguration
        {
            public int? TargetCalories { get; init; }
            public int? MinCalories { get; init; }
            public int? MaxCalories { get; init; }
            public bool HasConfiguration { get; init; }
            public string Scope { get; init; } = "profile";
        }

        private async Task<CoachProfile> GetApplicationEntityByUserIdAsync(Guid userId)
        {
            return (await _unitOfWork.CoachProfiles.FindAsync(x => x.UserId == userId))
                .FirstOrDefault() ?? throw new Exception("Coach application not found.");
        }

        private async Task ApplyApplicationChangesAsync(
            CoachProfile application,
            CoachApplicationUpsertRequest request)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(application.UserId)
                ?? throw new Exception("User does not exist.");
            var profile = (await _unitOfWork.Profiles.FindAsync(x => x.UserId == application.UserId))
                .FirstOrDefault();
            if (profile == null)
            {
                profile = new Profile
                {
                    UserId = application.UserId,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.Profiles.AddAsync(profile);
            }
            else
            {
                _unitOfWork.Profiles.Update(profile);
            }

            profile.FullName = request.FullName.Trim();
            profile.AvatarUrl = request.AvatarUrl.Trim();
            profile.DateOfBirth = request.DateOfBirth;
            profile.Gender = request.Gender.Trim();
            profile.UpdatedAt = DateTime.UtcNow;

            var specialties = NormalizeList(request.Specialties, 5);
            application.Specialty = string.Join(", ", specialties);
            application.Headline = request.Headline.Trim();
            application.Bio = request.Bio.Trim();
            application.ExperienceYears = request.ExperienceYears;
            application.PhoneNumber = request.PhoneNumber.Trim();
            application.City = request.City.Trim();
            application.LanguagesJson = JsonSerializer.Serialize(NormalizeList(request.Languages, 8));
            application.CoachingStylesJson = JsonSerializer.Serialize(NormalizeList(request.CoachingStyles, 6));
            application.ClientLevelsJson = JsonSerializer.Serialize(NormalizeList(request.ClientLevels, 5));
            application.CertificatesJson = JsonSerializer.Serialize(request.Certificates.Take(10));
            application.CertificateUrl = request.Certificates
                .Select(x => x.ImageUrl?.Trim())
                .FirstOrDefault(x => !string.IsNullOrWhiteSpace(x));
            application.GalleryUrlsJson = JsonSerializer.Serialize(
                NormalizeList(request.GalleryUrls, 8));
            application.Achievements = request.Achievements.Trim();
            application.IdentityDocumentUrl = request.IdentityDocumentUrl?.Trim();
            application.UpdatedAt = DateTime.UtcNow;

            user.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.Users.Update(user);
        }

        private static void ValidateApplicationForSubmit(CoachApplicationUpsertRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.FullName))
                throw new Exception("Full name is required.");
            if (string.IsNullOrWhiteSpace(request.AvatarUrl))
                throw new Exception("A profile photo is required.");
            if (!request.DateOfBirth.HasValue)
                throw new Exception("Date of birth is required.");
            if (string.IsNullOrWhiteSpace(request.PhoneNumber))
                throw new Exception("Phone number is required.");
            if (string.IsNullOrWhiteSpace(request.City))
                throw new Exception("City is required.");
            if (request.Languages.Count == 0)
                throw new Exception("At least one language is required.");
            if (string.IsNullOrWhiteSpace(request.Headline))
                throw new Exception("Professional headline is required.");
            if (request.Bio.Trim().Length < 80)
                throw new Exception("Biography must contain at least 80 characters.");
            if (request.Specialties.Count == 0)
                throw new Exception("At least one specialty is required.");
            if (request.Certificates.Count == 0)
                throw new Exception("At least one professional certificate is required.");
            if (request.Certificates.Any(x =>
                string.IsNullOrWhiteSpace(x.Name)
                || string.IsNullOrWhiteSpace(x.Issuer)
                || string.IsNullOrWhiteSpace(x.ImageUrl)))
                throw new Exception("Certificate name, issuer and image are required.");
            if (string.IsNullOrWhiteSpace(request.IdentityDocumentUrl))
                throw new Exception("An identity verification image is required.");
            if (request.GalleryUrls.Count == 0)
                throw new Exception("At least one portfolio image is required.");
        }

        private async Task<CoachApplicationResponse> MapApplicationAsync(CoachProfile application)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(application.UserId);
            var profile = (await _unitOfWork.Profiles.FindAsync(x => x.UserId == application.UserId))
                .FirstOrDefault();
            return new CoachApplicationResponse
            {
                Id = application.Id,
                UserId = application.UserId,
                FullName = profile?.FullName ?? string.Empty,
                AvatarUrl = profile?.AvatarUrl ?? string.Empty,
                Email = user?.Email ?? string.Empty,
                DateOfBirth = profile?.DateOfBirth,
                Gender = profile?.Gender ?? string.Empty,
                PhoneNumber = application.PhoneNumber,
                Specialty = application.Specialty,
                Headline = application.Headline,
                Bio = application.Bio,
                ExperienceYears = application.ExperienceYears,
                CertificateUrl = application.CertificateUrl,
                City = application.City,
                Languages = ParseStringList(application.LanguagesJson),
                CoachingStyles = ParseStringList(application.CoachingStylesJson),
                ClientLevels = ParseStringList(application.ClientLevelsJson),
                Certificates = ParseCertificates(application.CertificatesJson),
                GalleryUrls = ParseStringList(application.GalleryUrlsJson),
                Achievements = application.Achievements,
                IdentityDocumentUrl = application.IdentityDocumentUrl,
                ApplicationStatus = application.ApplicationStatus,
                ReviewNote = application.ReviewNote,
                SubmittedAt = application.SubmittedAt,
                ReviewedAt = application.ReviewedAt,
                ReviewedByUserId = application.ReviewedByUserId,
                PriceVnd = application.PriceVnd,
                IsActive = application.IsActive,
                CreatedAt = application.CreatedAt,
                UpdatedAt = application.UpdatedAt
            };
        }

        private static IReadOnlyList<string> NormalizeList(IEnumerable<string>? values, int max)
        {
            return (values ?? Array.Empty<string>())
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Select(x => x.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Take(max)
                .ToArray();
        }

        private static IReadOnlyList<string> ParseStringList(string? json)
        {
            if (string.IsNullOrWhiteSpace(json)) return Array.Empty<string>();
            try
            {
                return JsonSerializer.Deserialize<List<string>>(json) ?? new List<string>();
            }
            catch (JsonException)
            {
                return Array.Empty<string>();
            }
        }

        private static IReadOnlyList<CoachCertificateResponse> ParseCertificates(string? json)
        {
            if (string.IsNullOrWhiteSpace(json)) return Array.Empty<CoachCertificateResponse>();
            try
            {
                return JsonSerializer.Deserialize<List<CoachCertificateResponse>>(json)
                    ?? new List<CoachCertificateResponse>();
            }
            catch (JsonException)
            {
                return Array.Empty<CoachCertificateResponse>();
            }
        }

        public async Task<IEnumerable<object>> GetClientReviewRequestsAsync(Guid coachId, Guid clientId)
        {
            await EnsureAccessAllowedAsync(coachId, clientId);
            return await _ptReviewService.GetMyRequestsAsync(clientId);
        }
    }
}
