using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using FirebaseAdmin;
using FirebaseAdmin.Auth;
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
                    Description = "User Role",
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
                OtpCode = HashOtp(user.Id, otp),
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
                Message = "Registration successful. Please check your email for the verification OTP.",
                RequiresOtpVerification = true
            };
        }

        public async Task<AuthResponse> LoginAsync(LoginRequest request)
        {
            var normalizedEmail = request.Email.Trim().ToLowerInvariant();
            var user = (await _unitOfWork.Users.FindAsync(u => u.Email == normalizedEmail)).FirstOrDefault();
            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                throw new Exception("Invalid email or password.");
            if (!user.EmailConfirmed)
                throw new Exception("Please verify your OTP before logging in.");
            if (!user.IsActive)
                throw new Exception("Your account has been locked.");

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
                RefreshToken = HashToken(refreshToken),
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            });
            await _unitOfWork.CompleteAsync();

            return new AuthResponse { UserId = user.Id, Email = user.Email, FullName = profile?.FullName ?? string.Empty, AccessToken = accessToken, RefreshToken = refreshToken };
        }

        public async Task<AuthResponse> RefreshTokenAsync(string refreshToken)
        {
            var refreshTokenHash = HashToken(refreshToken);
            var session = (
                await _unitOfWork.Sessions.FindAsync(s =>
                    s.RefreshToken == refreshTokenHash || s.RefreshToken == refreshToken
                )
            ).FirstOrDefault();
            if (session == null || session.ExpiresAt < DateTime.UtcNow)
                throw new Exception("Invalid or expired refresh token.");

            var user = await _unitOfWork.Users.GetByIdAsync(session.UserId);
            if (user == null || !user.IsActive)
                throw new Exception("Your account has been locked or does not exist.");

            var roleName = (await _unitOfWork.Roles.FindAsync(r => r.Id == user.RoleId)).FirstOrDefault()?.Name ?? "User";
            var profile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == user.Id)).FirstOrDefault();
            var newAccessToken = GenerateJwtToken(user, roleName);
            var newRefreshToken = GenerateRefreshToken();

            session.RefreshToken = HashToken(newRefreshToken);
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

            var expectedOtpHash = HashOtp(user.Id, otpCode);
            var verification = (
                await _unitOfWork.EmailVerifications.FindAsync(v =>
                    v.UserId == user.Id && v.VerifiedAt == null
                )
            )
                .OrderByDescending(v => v.CreatedAt)
                .FirstOrDefault(v =>
                    FixedTimeEquals(v.OtpCode, expectedOtpHash)
                    || FixedTimeEquals(v.OtpCode, otpCode)
                );
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

        public async Task<ForgotPasswordResponse> ForgotPasswordAsync(ForgotPasswordRequest request)
        {
            var normalizedEmail = request.Email.Trim().ToLowerInvariant();
            var user = (await _unitOfWork.Users.FindAsync(u => u.Email == normalizedEmail)).FirstOrDefault();
            if (user == null)
            {
                return new ForgotPasswordResponse { Success = true, Message = "If the email exists, an OTP has been sent." };
            }

            var oldVerifications = await _unitOfWork.EmailVerifications.FindAsync(v => v.UserId == user.Id && v.VerifiedAt == null);
            foreach (var item in oldVerifications)
            {
                item.VerifiedAt = DateTime.UtcNow;
                _unitOfWork.EmailVerifications.Update(item);
            }

            var otp = GenerateOtp();
            var verification = new EmailVerification
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                OtpCode = HashOtp(user.Id, otp),
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddMinutes(10)
            };

            await _unitOfWork.EmailVerifications.AddAsync(verification);
            await _unitOfWork.CompleteAsync();

            await _emailService.SendForgotPasswordEmailAsync(user.Email, otp);

            return new ForgotPasswordResponse { Success = true, Message = "Password recovery OTP has been sent to your email." };
        }

        public async Task<ForgotPasswordResponse> ResetPasswordAsync(ResetPasswordRequest request)
        {
            var normalizedEmail = request.Email.Trim().ToLowerInvariant();
            var user = (await _unitOfWork.Users.FindAsync(u => u.Email == normalizedEmail)).FirstOrDefault();
            if (user == null)
            {
                throw new Exception("Email does not exist.");
            }

            var expectedOtpHash = HashOtp(user.Id, request.OtpCode);
            var verification = (
                await _unitOfWork.EmailVerifications.FindAsync(v =>
                    v.UserId == user.Id && v.VerifiedAt == null
                )
            )
                .OrderByDescending(v => v.CreatedAt)
                .FirstOrDefault(v =>
                    FixedTimeEquals(v.OtpCode, expectedOtpHash)
                    || FixedTimeEquals(v.OtpCode, request.OtpCode)
                );
            if (verification == null || verification.ExpiresAt < DateTime.UtcNow || verification.VerifiedAt != null)
            {
                throw new Exception("Invalid or expired OTP.");
            }

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            user.UpdatedAt = DateTime.UtcNow;
            verification.VerifiedAt = DateTime.UtcNow;
            _unitOfWork.Users.Update(user);
            _unitOfWork.EmailVerifications.Update(verification);

            var sessions = await _unitOfWork.Sessions.FindAsync(s => s.UserId == user.Id);
            foreach (var session in sessions)
            {
                _unitOfWork.Sessions.Remove(session);
            }

            await _unitOfWork.CompleteAsync();

            return new ForgotPasswordResponse { Success = true, Message = "Password reset successful." };
        }

        public async Task LogoutAsync(string refreshToken)
        {
            var refreshTokenHash = HashToken(refreshToken);
            var session = (
                await _unitOfWork.Sessions.FindAsync(s =>
                    s.RefreshToken == refreshTokenHash || s.RefreshToken == refreshToken
                )
            ).FirstOrDefault();
            if (session == null) return;
            _unitOfWork.Sessions.Remove(session);
            await _unitOfWork.CompleteAsync();
        }

        public async Task<AuthResponse> LoginWithGoogleAsync(string idToken)
        {
            if (string.IsNullOrWhiteSpace(idToken))
                throw new Exception("Invalid Google sign-in token.");

            if (FirebaseApp.DefaultInstance == null)
                throw new Exception("Google sign-in is not configured on the server.");

            FirebaseToken decoded;
            try
            {
                decoded = await FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(idToken);
            }
            catch
            {
                throw new Exception("Invalid or expired Google sign-in token.");
            }

            if (!decoded.Claims.TryGetValue("email", out var emailObj) || emailObj == null)
                throw new Exception("Google account does not have an email address.");

            var normalizedEmail = emailObj.ToString()!.Trim().ToLowerInvariant();
            decoded.Claims.TryGetValue("name", out var nameObj);
            var displayName = nameObj?.ToString()?.Trim() ?? string.Empty;

            var user = (await _unitOfWork.Users.FindAsync(u => u.Email == normalizedEmail)).FirstOrDefault();
            Profile? profile;

            if (user == null)
            {
                var userRole = (await _unitOfWork.Roles.FindAsync(r => r.Name == "User")).FirstOrDefault();
                if (userRole == null)
                {
                    userRole = new Role
                    {
                        Id = Guid.NewGuid(),
                        Name = "User",
                        Description = "User Role",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };
                    await _unitOfWork.Roles.AddAsync(userRole);
                    await _unitOfWork.CompleteAsync();
                }

                var now = DateTime.UtcNow;
                user = new User
                {
                    Id = Guid.NewGuid(),
                    RoleId = userRole.Id,
                    Email = normalizedEmail,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString("N")),
                    EmailConfirmed = true,
                    IsActive = true,
                    LastSignInAt = now,
                    CreatedAt = now,
                    UpdatedAt = now
                };

                profile = new Profile
                {
                    UserId = user.Id,
                    FullName = string.IsNullOrWhiteSpace(displayName) ? null : displayName,
                    CreatedAt = now,
                    UpdatedAt = now
                };

                var health = new HealthProfile { UserId = user.Id, CreatedAt = now, UpdatedAt = now };

                await _unitOfWork.Users.AddAsync(user);
                await _unitOfWork.Profiles.AddAsync(profile);
                await _unitOfWork.HealthProfiles.AddAsync(health);
                await _unitOfWork.CompleteAsync();
            }
            else
            {
                if (!user.IsActive)
                    throw new Exception("Your account has been locked.");

                if (!user.EmailConfirmed)
                {
                    user.EmailConfirmed = true;
                    user.IsActive = true;
                }

                user.LastSignInAt = DateTime.UtcNow;
                user.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.Users.Update(user);

                profile = (await _unitOfWork.Profiles.FindAsync(p => p.UserId == user.Id)).FirstOrDefault();
                if (profile != null &&
                    string.IsNullOrWhiteSpace(profile.FullName) &&
                    !string.IsNullOrWhiteSpace(displayName))
                {
                    profile.FullName = displayName;
                    profile.UpdatedAt = DateTime.UtcNow;
                    _unitOfWork.Profiles.Update(profile);
                }
            }

            return await IssueAuthResponseAsync(user, profile);
        }

        private async Task<AuthResponse> IssueAuthResponseAsync(User user, Profile? profile)
        {
            var roleName = (await _unitOfWork.Roles.FindAsync(r => r.Id == user.RoleId)).FirstOrDefault()?.Name ?? "User";
            profile ??= (await _unitOfWork.Profiles.FindAsync(p => p.UserId == user.Id)).FirstOrDefault();

            var accessToken = GenerateJwtToken(user, roleName);
            var refreshToken = GenerateRefreshToken();

            await _unitOfWork.Sessions.AddAsync(new Session
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                RefreshToken = HashToken(refreshToken),
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            });
            await _unitOfWork.CompleteAsync();

            return new AuthResponse
            {
                UserId = user.Id,
                Email = user.Email,
                FullName = profile?.FullName ?? string.Empty,
                AccessToken = accessToken,
                RefreshToken = refreshToken
            };
        }

        private string GenerateOtp() => RandomNumberGenerator.GetInt32(100000, 999999).ToString();

        private string GenerateRefreshToken()
        {
            var randomNumber = new byte[32];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(randomNumber);
            return Convert.ToBase64String(randomNumber);
        }

        private static string HashToken(string token)
        {
            var hash = SHA256.HashData(Encoding.UTF8.GetBytes(token));
            return Convert.ToHexString(hash);
        }

        private string HashOtp(Guid userId, string otp)
        {
            var secretKey =
                _configuration["JwtSettings:SecretKey"]
                ?? Environment.GetEnvironmentVariable("JWT_SECRET_KEY")
                ?? throw new InvalidOperationException("JWT signing key is not configured.");
            using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secretKey));
            var hash = hmac.ComputeHash(
                Encoding.UTF8.GetBytes($"{userId:N}:{otp}")
            );

            // The legacy database column is VARCHAR(20). Fifteen HMAC bytes encode
            // to exactly 20 Base64 characters while retaining 120 bits of entropy.
            return Convert.ToBase64String(hash, 0, 15);
        }

        private static bool FixedTimeEquals(string left, string right)
        {
            var leftBytes = Encoding.UTF8.GetBytes(left);
            var rightBytes = Encoding.UTF8.GetBytes(right);
            return leftBytes.Length == rightBytes.Length
                && CryptographicOperations.FixedTimeEquals(leftBytes, rightBytes);
        }

        private string GenerateJwtToken(User user, string roleName)
        {
            var secretKey = _configuration["JwtSettings:SecretKey"]
                            ?? Environment.GetEnvironmentVariable("JWT_SECRET_KEY")
                            ?? throw new InvalidOperationException("JwtSettings:SecretKey is not configured.");
            var key = Encoding.UTF8.GetBytes(secretKey);
            var expiryMinutes = int.TryParse(
                _configuration["JwtSettings:ExpiryMinutes"],
                out var exp
            )
                ? Math.Clamp(exp, 5, 60)
                : 60;
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
