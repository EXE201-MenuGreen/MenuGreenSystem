using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
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

        public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
        {
            // 1. Check if email already exists
            var existingUsers = await _unitOfWork.Users.FindAsync(u => u.Email == request.Email);
            if (existingUsers.Any())
            {
                throw new Exception("Email is already registered.");
            }

            // 2. Hash the password
            string passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

            // Find or create "User" role
            var roles = await _unitOfWork.Roles.FindAsync(r => r.Name == "User");
            var userRole = roles.FirstOrDefault();
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

            // 3. Create User entity
            var newUser = new User
            {
                Id = Guid.NewGuid(),
                RoleId = userRole.Id,
                Email = request.Email,
                PasswordHash = passwordHash,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                IsActive = true,
                EmailConfirmed = false
            };

            // 4. Create default Profile and HealthProfile entities
            var newProfile = new Profile
            {
                UserId = newUser.Id,
                FullName = request.FullName,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            var newHealthProfile = new HealthProfile
            {
                UserId = newUser.Id,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            // 5. Save to database using Unit of Work
            await _unitOfWork.Users.AddAsync(newUser);
            await _unitOfWork.Profiles.AddAsync(newProfile);
            await _unitOfWork.HealthProfiles.AddAsync(newHealthProfile);
            await _unitOfWork.CompleteAsync();

            // 6. Generate Verification Token & Send Email
            var verificationToken = GenerateEmailVerificationToken(newUser);
            var verificationLink = $"http://localhost:5000/api/auth/verify-email?token={verificationToken}";
            
            // Note: In production, consider sending emails in a background task/queue to not block the request
            await _emailService.SendVerificationEmailAsync(newUser.Email, verificationLink);

            // 7. Generate Access Token and Refresh Token
            var accessToken = GenerateJwtToken(newUser, "User");
            var refreshToken = GenerateRefreshToken();
            
            var session = new Session
            {
                Id = Guid.NewGuid(),
                UserId = newUser.Id,
                RefreshToken = refreshToken,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            };
            await _unitOfWork.Sessions.AddAsync(session);
            await _unitOfWork.CompleteAsync();
            
            return new AuthResponse
            {
                UserId = newUser.Id,
                Email = newUser.Email,
                FullName = newProfile.FullName,
                AccessToken = accessToken,
                RefreshToken = refreshToken 
            };
        }

        public async Task<AuthResponse> LoginAsync(LoginRequest request)
        {
            var users = await _unitOfWork.Users.FindAsync(u => u.Email == request.Email);
            var user = users.FirstOrDefault();

            if (user == null)
                throw new Exception("Invalid email or password.");

            if (!user.IsActive)
                throw new Exception("Your account has been locked. Please contact the administrator.");

            // Optional: Block login if email is not verified
            // if (!user.EmailConfirmed)
            //    throw new Exception("Please verify your email before logging in.");

            bool isPasswordValid = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
            if (!isPasswordValid)
                throw new Exception("Invalid email or password.");

            var profiles = await _unitOfWork.Profiles.FindAsync(p => p.UserId == user.Id);
            var profile = profiles.FirstOrDefault();

            user.LastSignInAt = DateTime.UtcNow;
            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();

            var roleName = "User";
            var roleEntities = await _unitOfWork.Roles.FindAsync(r => r.Id == user.RoleId);
            if (roleEntities.Any())
            {
                roleName = roleEntities.First().Name;
            }

            var accessToken = GenerateJwtToken(user, roleName);
            var refreshToken = GenerateRefreshToken();
            
            var session = new Session
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                RefreshToken = refreshToken,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            };
            await _unitOfWork.Sessions.AddAsync(session);
            await _unitOfWork.CompleteAsync();

            return new AuthResponse
            {
                UserId = user.Id,
                Email = user.Email,
                FullName = profile?.FullName ?? "",
                AccessToken = accessToken,
                RefreshToken = refreshToken
            };
        }

        public async Task<AuthResponse> RefreshTokenAsync(string refreshToken)
        {
            var sessions = await _unitOfWork.Sessions.FindAsync(s => s.RefreshToken == refreshToken);
            var session = sessions.FirstOrDefault();

            if (session == null || session.ExpiresAt < DateTime.UtcNow)
            {
                throw new Exception("Invalid or expired refresh token.");
            }

            var user = await _unitOfWork.Users.GetByIdAsync(session.UserId);
            if (user == null || !user.IsActive)
            {
                throw new Exception("Your account has been locked or does not exist.");
            }

            var profiles = await _unitOfWork.Profiles.FindAsync(p => p.UserId == user.Id);
            var profile = profiles.FirstOrDefault();

            // Generate new tokens
            var roleName = "User";
            var roleEntities = await _unitOfWork.Roles.FindAsync(r => r.Id == user.RoleId);
            if (roleEntities.Any())
            {
                roleName = roleEntities.First().Name;
            }

            var newAccessToken = GenerateJwtToken(user, roleName);
            var newRefreshToken = GenerateRefreshToken();

            // Update session
            session.RefreshToken = newRefreshToken;
            session.ExpiresAt = DateTime.UtcNow.AddDays(7);
            _unitOfWork.Sessions.Update(session);
            
            user.LastSignInAt = DateTime.UtcNow;
            _unitOfWork.Users.Update(user);
            
            await _unitOfWork.CompleteAsync();

            return new AuthResponse
            {
                UserId = user.Id,
                Email = user.Email,
                FullName = profile?.FullName ?? "",
                AccessToken = newAccessToken,
                RefreshToken = newRefreshToken
            };
        }

        public async Task<bool> VerifyEmailAsync(string token)
        {
            var secretKey = _configuration["JwtSettings:SecretKey"] ?? "super_secret_key_menu_green_1234567890_super_long";
            var key = Encoding.ASCII.GetBytes(secretKey);

            var tokenHandler = new JwtSecurityTokenHandler();
            try
            {
                tokenHandler.ValidateToken(token, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidateIssuer = true,
                    ValidIssuer = _configuration["JwtSettings:Issuer"],
                    ValidateAudience = true,
                    ValidAudience = _configuration["JwtSettings:Audience"],
                    ClockSkew = TimeSpan.Zero
                }, out SecurityToken validatedToken);

                var jwtToken = (JwtSecurityToken)validatedToken;
                var userIdString = jwtToken.Claims.First(x => x.Type == "email_verification_user_id").Value;
                
                if (Guid.TryParse(userIdString, out Guid userId))
                {
                    var user = await _unitOfWork.Users.GetByIdAsync(userId);
                    if (user != null && !user.EmailConfirmed)
                    {
                        user.EmailConfirmed = true;
                        _unitOfWork.Users.Update(user);
                        await _unitOfWork.CompleteAsync();
                        return true;
                    }
                }
                return false;
            }
            catch
            {
                return false;
            }
        }

        private string GenerateEmailVerificationToken(User user)
        {
            var secretKey = _configuration["JwtSettings:SecretKey"] ?? "super_secret_key_menu_green_1234567890_super_long";
            var key = Encoding.ASCII.GetBytes(secretKey);

            var tokenHandler = new JwtSecurityTokenHandler();
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim("email_verification_user_id", user.Id.ToString())
                }),
                // Token expires in 24 hours
                Expires = DateTime.UtcNow.AddHours(24),
                Issuer = _configuration["JwtSettings:Issuer"],
                Audience = _configuration["JwtSettings:Audience"],
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }

        private string GenerateJwtToken(User user, string roleName)
        {
            var secretKey = _configuration["JwtSettings:SecretKey"] ?? "super_secret_key_menu_green_1234567890_super_long";
            var key = Encoding.ASCII.GetBytes(secretKey);
            var expiryMinutes = int.TryParse(_configuration["JwtSettings:ExpiryMinutes"], out int exp) ? exp : 120;

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

            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }

        private string GenerateRefreshToken()
        {
            var randomNumber = new byte[32];
            using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();
            rng.GetBytes(randomNumber);
            return Convert.ToBase64String(randomNumber);
        }
    }
}
