using MenuGreen.DataAccessLayer.Context;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MenuGreen.DataAccessLayer.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260716160000_AddGymerSubscriptionPlan")]
    public partial class AddGymerSubscriptionPlan : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                @"INSERT INTO subscription_plans
                    (""Id"", ""Name"", ""Description"", ""DurationDays"", ""PriceVnd"", ""FeatureGroup"", ""IsActive"")
                  VALUES
                    ('10000000-0000-0000-0000-000000000005',
                     'Gói Gym/PT',
                     E'Mục tiêu calo, protein và lịch tập\nPT Review qua liên kết bảo mật\nKết nối huấn luyện viên và quản lý quyền truy cập\nLộ trình thể hình 8–12 tuần',
                     NULL,
                     0,
                     'gym',
                     TRUE)
                  ON CONFLICT (""Id"") DO NOTHING;"
            );
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                @"DELETE FROM subscription_plans p
                  WHERE p.""Id"" = '10000000-0000-0000-0000-000000000005'
                    AND NOT EXISTS (
                        SELECT 1
                        FROM user_subscriptions s
                        WHERE s.""SubscriptionPlanId"" = p.""Id""
                    );"
            );
        }
    }
}
