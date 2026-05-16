using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.Extensions.Configuration;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class EmailService : IEmailService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;

        public EmailService(HttpClient httpClient, IConfiguration configuration)
        {
            _httpClient = httpClient;
            _configuration = configuration;
        }

        public async Task SendVerificationEmailAsync(string toEmail, string verificationLink)
        {
            var apiKey = _configuration["Resend:ApiKey"];
            if (string.IsNullOrEmpty(apiKey))
            {
                throw new Exception("Resend API Key is missing in configuration.");
            }

            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

            // Vì đang test ở chế độ Sandbox của Resend, 'from' bắt buộc phải là onboarding@resend.dev
            var payload = new
            {
                from = "MenuGreen <onboarding@resend.dev>",
                to = new[] { toEmail },
                subject = "MenuGreen - Xác nhận địa chỉ Email của bạn",
                html = $@"
                    <div style='font-family: Arial, sans-serif; padding: 20px;'>
                        <h2 style='color: #2e7d32;'>Chào mừng bạn đến với MenuGreen! 🌱</h2>
                        <p>Cảm ơn bạn đã đăng ký tài khoản. Vui lòng bấm vào nút bên dưới để xác nhận địa chỉ email của bạn:</p>
                        <a href='{verificationLink}' style='display: inline-block; padding: 10px 20px; color: #fff; background-color: #4caf50; text-decoration: none; border-radius: 5px; margin-top: 10px;'>Xác nhận Email ngay</a>
                        <p style='margin-top: 20px; font-size: 12px; color: #777;'>Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email này.</p>
                    </div>"
            };

            var content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync("https://api.resend.com/emails", content);
            
            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                throw new Exception($"Lỗi gửi email từ Resend: {error}");
            }
        }
    }
}
