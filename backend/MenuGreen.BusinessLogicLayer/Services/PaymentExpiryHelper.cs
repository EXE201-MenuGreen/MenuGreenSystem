using System;
using MenuGreen.DataAccessLayer.Entities;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    internal static class PaymentExpiryHelper
    {
        public static bool IsExpired(Payment payment) =>
            payment.Status == "PENDING" &&
            payment.ExpiredAt.HasValue &&
            payment.ExpiredAt.Value < DateTimeOffset.UtcNow;

        public static void MarkExpired(Payment payment)
        {
            payment.Status = "EXPIRED";
            payment.UpdatedAt = DateTimeOffset.UtcNow;
        }

        public static async Task<Payment> RefreshPendingExpiryAsync(Payment payment, IUnitOfWork unitOfWork)
        {
            if (!IsExpired(payment))
            {
                return payment;
            }

            MarkExpired(payment);
            unitOfWork.Payments.Update(payment);
            await unitOfWork.CompleteAsync();
            return payment;
        }
    }
}
