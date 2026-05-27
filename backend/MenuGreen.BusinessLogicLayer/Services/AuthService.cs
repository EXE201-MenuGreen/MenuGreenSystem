using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class AuthService : IAuthService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IConfiguration _configuration;
        private readonly IEmailService _emailService;

        public AuthService(IUnitOfWork unitOfWork, IConfiguration configuration, IEmailService emailService)
        {
            _unitOfWork = unitOfWork;
            _configuration = configuration;
            _emailService = emailService;
        }

        public async Task<RegisterResponse> RegisterAsync(RegisterRequest request)
        {
            var normalizedEmail = request.Email.Trim().ToLowerInvariant();
            var existingUsers = await _unitOfWork.Users.FindAsync(u => u.Email == normalizedEmail);
            if (existingUsers.Any()) throw new Exception("Email is already registered.");

            var userRole = (await _unitOfWork.Roles.FindAsync(r => r.Name == "User")).FirstOrDefault();
            if (userRole == null)
            {
                userRole = new Role
                {
                    Id = Guid.NewGuid(),
                    Name = "User",
                    Description = "Standard User Role",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.Roles.AddAsync(userRole);
                await _unitOfWork.CompleteAsync();
            }

            var user = new User
            {
                Id = Guid.NewGuid(),
                RoleId = userRole.Id,
                Email = normalizedEmail,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                EmailConfirmed = false,
                IsActive = false
            };

            var profile = new Profile { UserId = user.Id, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow };
            var health = new HealthProfile { UserId = user.Id, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow };
            var otp = GenerateOtp();
            var verification = new EmailVerification
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                OtpCode = otp,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddMinutes(10)
            };

            await _unitOfWork.Users.AddAsync(user);
            await _unitOfWork.Profiles.AddAsync(profile);
            await _unitOfWork.HealthProfiles.AddAsync(health);
            await _unitOfWork.EmailVerifications.AddAsync(verification);
            await _unitOfWork.CompleteAsync();

            await _emailService.SendVerificationEmailAsync(user.Email, otp);

            return new RegisterResponse
            {
                UserId = user.Id,
                Email = user.Email,
                Message = "Đăng ký thành công. Vui lòng kiểm tra email để lấy OTP xác thực.",
                RequiresOtpVerification = true
            };
        }

        public async Task<AuthResponse> LoginAsync(LoginRequest request)
        {
            var normalizedEmail = request.Email.Trim().ToLowerInvariant();
            var user = (await _unitOfWork.Users.FindAsync(u => u.Email == normalizedEmail)).FirstOrDefault();
            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash)) throw new Exception("Invalid email or password.");
            if (!user.EmailConfirmed) throw new Exception("Please verify your OTP before logging in.");
            if (!user.IsActive) throw new Exception("Your account has been locked.");

            user.LastSignInAt = DateTime.UtcNow;
            _unitOfWork.Users.Update(user);

            var roleName = (await _unitOfWork.Roles.FindAsync(r => r.Id == user.RoleId)).FirstOrDefault()?.Name ?? "User";
            var profile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == user.Id)).FirstOrDefault();
            var accessToken = GenerateJwtToken(user, roleName);
            var refreshToken = GenerateRefreshToken();

            await _unitOfWork.Sessions.AddAsync(new Session
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                RefreshToken = refreshToken,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            });
            await _unitOfWork.CompleteAsync();

            return new AuthResponse { UserId = user.Id, Email = user.Email, FullName = profile?.FullName ?? string.Empty, AccessToken = accessToken, RefreshToken = refreshToken };
        }

        public async Task<AuthResponse> RefreshTokenAsync(string refreshToken)
        {
            var session = (await _unitOfWork.Sessions.FindAsync(s => s.RefreshToken == refreshToken)).FirstOrDefault();
            if (session == null || session.ExpiresAt < DateTime.UtcNow) throw new Exception("Invalid or expired refresh token.");

            var user = await _unitOfWork.Users.GetByIdAsync(session.UserId);
            if (user == null || !user.IsActive) throw new Exception("Your account has been locked or does not exist.");

            var roleName = (await _unitOfWork.Roles.FindAsync(r => r.Id == user.RoleId)).FirstOrDefault()?.Name ?? "User";
            var profile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == user.Id)).FirstOrDefault();
            var newAccessToken = GenerateJwtToken(user, roleName);
            var newRefreshToken = GenerateRefreshToken();

            session.RefreshToken = newRefreshToken;
            session.ExpiresAt = DateTime.UtcNow.AddDays(7);
            _unitOfWork.Sessions.Update(session);
            await _unitOfWork.CompleteAsync();

            return new AuthResponse { UserId = user.Id, Email = user.Email, FullName = profile?.FullName ?? string.Empty, AccessToken = newAccessToken, RefreshToken = newRefreshToken };
        }

        public async Task<bool> VerifyOtpAsync(string email, string otpCode)
        {
            var normalizedEmail = email.Trim().ToLowerInvariant();
            var user = (await _unitOfWork.Users.FindAsync(u => u.Email == normalizedEmail)).FirstOrDefault();
            if (user == null) return false;

            var verification = (await _unitOfWork.EmailVerifications.FindAsync(v => v.UserId == user.Id && v.OtpCode == otpCode)).FirstOrDefault();
            if (verification == null || verification.ExpiresAt < DateTime.UtcNow || verification.VerifiedAt != null) return false;

            user.EmailConfirmed = true;
            user.IsActive = true;
            user.UpdatedAt = DateTime.UtcNow;
            verification.VerifiedAt = DateTime.UtcNow;
            _unitOfWork.Users.Update(user);
            _unitOfWork.EmailVerifications.Update(verification);
            await _unitOfWork.CompleteAsync();
            return true;
        }

        public async Task LogoutAsync(string refreshToken)
        {
            var session = (await _unitOfWork.Sessions.FindAsync(s => s.RefreshToken == refreshToken)).FirstOrDefault();
            if (session == null) return;
            _unitOfWork.Sessions.Remove(session);
            await _unitOfWork.CompleteAsync();
        }

        private string GenerateOtp() => RandomNumberGenerator.GetInt32(100000, 999999).ToString();

        private string GenerateRefreshToken()
        {
            var randomNumber = new byte[32];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(randomNumber);
            return Convert.ToBase64String(randomNumber);
        }

        private string GenerateJwtToken(User user, string roleName)
        {
            var secretKey = _configuration["JwtSettings:SecretKey"] ?? "super_secret_key_menu_green_1234567890_super_long";
            var key = Encoding.ASCII.GetBytes(secretKey);
            var expiryMinutes = int.TryParse(_configuration["JwtSettings:ExpiryMinutes"], out var exp) ? exp : 120;
            var tokenHandler = new JwtSecurityTokenHandler();
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Email, user.Email),
                    new Claim(ClaimTypes.Role, roleName)
                }),
                Expires = DateTime.UtcNow.AddMinutes(expiryMinutes),
                Issuer = _configuration["JwtSettings:Issuer"],
                Audience = _configuration["JwtSettings:Audience"],
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };
            return tokenHandler.WriteToken(tokenHandler.CreateToken(tokenDescriptor));
        }
    }
}
