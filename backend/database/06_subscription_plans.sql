-- =============================================================================
-- MenuGreen Seed Data - Table: subscription_plans
-- Sequence Number: 06
--
-- 2026-07-24: Xóa hẳn 2 plan "Pro Tháng/GYM" và "Pro Năm" khỏi catalog.
-- Dự án chỉ còn 4 gói chính: Free, Casual, Gym/PT, Office.
-- File SQL này dùng DROP TABLE IF EXISTS + CASCADE ở đầu nên nếu chạy lại
-- từ đầu trên DB production, toàn bộ subscription_plans + subscriptions +
-- user_subscriptions sẽ bị reset. Chỉ chạy file này khi dựng DB mới.
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS subscription_plans CASCADE;

CREATE TABLE subscription_plans (
    "Id" uuid NOT NULL,
    "Name" text NULL,
    "Description" text NULL,
    "DurationDays" integer NULL,
    "PriceVnd" integer NULL,
    "FeatureGroup" text NULL,
    "IsActive" boolean NULL,
    CONSTRAINT "PK_subscription_plans" PRIMARY KEY ("Id")
);

INSERT INTO subscription_plans ("Id", "Name", "Description", "DurationDays", "PriceVnd", "FeatureGroup", "IsActive")
VALUES
('10000000-0000-0000-0000-000000000001', 'Cơ bản', 'Quản lý thực đơn cơ bản, tính calo theo chuẩn', NULL, 0, 'basic', true),
('10000000-0000-0000-0000-000000000004', 'Office', 'Kế hoạch cơm hộp, nhắc nhở và tiện ích cho nhân viên văn phòng', 1, 0, 'office', true),
('10000000-0000-0000-0000-000000000005', 'Gói Gym/PT', E'Mục tiêu calo, protein và lịch tập\nPT Review qua liên kết bảo mật\nKết nối huấn luyện viên và quản lý quyền truy cập\nLộ trình thể hình 8–12 tuần', NULL, 0, 'gym', true)
ON CONFLICT DO NOTHING;

-- Keep the full seed usable on its own; script 58 remains the idempotent
-- production patch for databases that were seeded before Casual existed.
INSERT INTO subscription_plans (
    "Id", "Name", "Description", "DurationDays", "PriceVnd", "FeatureGroup", "IsActive"
)
VALUES (
    '10000000-0000-0000-0000-000000000006',
    'Gói Casual',
    E'Vòng quay 10 món ăn cá nhân hóa và an toàn\nKhởi động thực đơn, ghi nhật ký nhanh trong một chạm\nThẻ kiến thức dinh dưỡng theo lịch sử ăn uống',
    NULL,
    0,
    'casual',
    true
)
ON CONFLICT DO NOTHING;

COMMIT;
