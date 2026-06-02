using System;

namespace MenuGreen.BusinessLogicLayer.Services
{
    internal static class DbExceptionHelper
    {
        public static bool IsUniqueConstraintViolation(Exception exception)
        {
            for (var current = exception; current != null; current = current.InnerException)
            {
                var message = current.Message;
                if (message.Contains("23505", StringComparison.Ordinal) ||
                    message.Contains("duplicate key", StringComparison.OrdinalIgnoreCase) ||
                    message.Contains("unique constraint", StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }

            return false;
        }
    }
}
