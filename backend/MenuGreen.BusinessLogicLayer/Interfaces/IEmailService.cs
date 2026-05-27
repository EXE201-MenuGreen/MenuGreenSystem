using System.Threading.Tasks;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IEmailService
    {
        Task SendVerificationEmailAsync(string toEmail, string otpCode);
    }
}
