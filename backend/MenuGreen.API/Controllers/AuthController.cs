using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [AllowAnonymous]
    [Microsoft.AspNetCore.RateLimiting.EnableRateLimiting("AuthPolicy")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        // Register new account and send OTP verification via email.
        [HttpPost("register")]
        [Microsoft.AspNetCore.RateLimiting.EnableRateLimiting("OtpPolicy")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var response = await _authService.RegisterAsync(request);
                return Ok(response);
            }
            catch (Exception)
            {
                return BadRequest(new { Message = "Registration could not be completed." });
            }
        }

        [HttpPost("verify-otp")]
        [Microsoft.AspNetCore.RateLimiting.EnableRateLimiting("OtpPolicy")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var verified = await _authService.VerifyOtpAsync(request.Email, request.OtpCode);
                return verified
                    ? Ok(new { Message = "OTP verified successfully." })
                    : BadRequest(new { Message = "Invalid or expired OTP." });
            }
            catch (Exception)
            {
                return BadRequest(new { Message = "OTP verification failed." });
            }
        }

        [HttpPost("forgot-password")]
        [Microsoft.AspNetCore.RateLimiting.EnableRateLimiting("OtpPolicy")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var response = await _authService.ForgotPasswordAsync(request);
                return Ok(response);
            }
            catch (Exception)
            {
                return Ok(
                    new
                    {
                        Success = true,
                        Message = "If the email exists, an OTP has been sent.",
                    }
                );
            }
        }

        [HttpPost("reset-password")]
        [Microsoft.AspNetCore.RateLimiting.EnableRateLimiting("OtpPolicy")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var response = await _authService.ResetPasswordAsync(request);
                return Ok(response);
            }
            catch (Exception)
            {
                return BadRequest(new { Message = "Invalid or expired password reset request." });
            }
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var response = await _authService.LoginAsync(request);
                return Ok(response);
            }
            catch (Exception)
            {
                return Unauthorized(new { Message = "Invalid email or password." });
            }
        }

        [HttpPost("refresh-token")]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var response = await _authService.RefreshTokenAsync(request.RefreshToken);
                return Ok(response);
            }
            catch (Exception)
            {
                return Unauthorized(new { Message = "Invalid or expired refresh token." });
            }
        }

        [HttpPost("logout")]
        public async Task<IActionResult> Logout([FromBody] RefreshTokenRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                await _authService.LogoutAsync(request.RefreshToken);
                return Ok(new { Message = "Logged out successfully." });
            }
            catch (Exception)
            {
                return BadRequest(new { Message = "Logout could not be completed." });
            }
        }

        [HttpPost("google")]
        public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var response = await _authService.LoginWithGoogleAsync(request.IdToken);
                return Ok(response);
            }
            catch (Exception)
            {
                return Unauthorized(new { Message = "Invalid or expired Google sign-in token." });
            }
        }
    }
}
