using System;

namespace MenuGreen.BusinessLogicLayer.Helpers
{
    internal static class VietnamTime
    {
        private const int UtcOffsetHours = 7;

        public static DateOnly ToDate(DateTime value)
        {
            // Npgsql legacy timestamp mode can materialize timestamptz as
            // DateTimeKind.Local. Adding seven hours directly in that case
            // double-applies the Vietnam offset and moves evening meals to the
            // following day. Normalize the instant to UTC first.
            var utc = value.Kind switch
            {
                DateTimeKind.Utc => value,
                DateTimeKind.Local => value.ToUniversalTime(),
                _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
            };
            return DateOnly.FromDateTime(utc.AddHours(UtcOffsetHours));
        }

        public static DateTime RangeStartUtc(DateOnly date) => date
            .ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc)
            .AddHours(-UtcOffsetHours);

        public static DateTime RangeEndUtc(DateOnly date) => date
            .ToDateTime(TimeOnly.MaxValue, DateTimeKind.Utc)
            .AddHours(-UtcOffsetHours);
    }
}
