using MenuGreen.DataAccessLayer.Context;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MenuGreen.DataAccessLayer.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260721103000_AddCasualSubscriptionPlan")]
    public partial class AddCasualSubscriptionPlan : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                @"INSERT INTO subscription_plans
                    (""Id"", ""Name"", ""Description"", ""DurationDays"", ""PriceVnd"", ""FeatureGroup"", ""IsActive"")
                  VALUES
                    ('10000000-0000-0000-0000-000000000005',
                     'Gói Casual',
                     E'Vòng quay 10 món ăn cá nhân hóa và an toàn\nKhởi động thực đơn, ghi nhật ký nhanh trong một chạm\nThẻ kiến thức dinh dưỡng theo lịch sử ăn uống',
                     NULL,
                     0,
                     'casual',
                     TRUE)
                  ON CONFLICT (""Id"") DO UPDATE SET
                    ""Name"" = EXCLUDED.""Name"",
                    ""Description"" = EXCLUDED.""Description"",
                    ""DurationDays"" = EXCLUDED.""DurationDays"",
                    ""FeatureGroup"" = EXCLUDED.""FeatureGroup"",
                    ""IsActive"" = EXCLUDED.""IsActive"";"
            );

            migrationBuilder.Sql(
                @"INSERT INTO micro_learning_cards
                    (""Id"", ""Title"", ""Summary"", ""Category"", ""Tips"", ""ImageUrl"", ""QuizQuestion"", ""QuizOptions"", ""CorrectOptionIndex"", ""PointsReward"", ""IsActive"", ""CreatedAt"")
                  VALUES
                    ('e1000000-0000-0000-0000-000000000009',
                     'Bổ sung chất xơ mỗi ngày',
                     'Chất xơ hỗ trợ tiêu hóa, giúp no lâu và góp phần ổn định đường huyết. Hãy tăng dần rau, trái cây và ngũ cốc nguyên hạt trong các bữa ăn.',
                     'Fiber',
                     'Dành một nửa đĩa ăn cho rau củ|Ưu tiên trái cây nguyên quả thay vì nước ép|Chọn gạo lứt hoặc ngũ cốc nguyên hạt khi phù hợp',
                     NULL, NULL, NULL, NULL, 0, TRUE, NOW())
                  ON CONFLICT (""Id"") DO UPDATE SET
                    ""Title"" = EXCLUDED.""Title"",
                    ""Summary"" = EXCLUDED.""Summary"",
                    ""Category"" = EXCLUDED.""Category"",
                    ""Tips"" = EXCLUDED.""Tips"",
                    ""IsActive"" = EXCLUDED.""IsActive"";"
            );
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                @"DELETE FROM micro_learning_cards c
                  WHERE c.""Id"" = 'e1000000-0000-0000-0000-000000000009'
                    AND NOT EXISTS (
                        SELECT 1 FROM user_card_interactions i WHERE i.""CardId"" = c.""Id""
                    );"
            );

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
