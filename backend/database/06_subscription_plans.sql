-- =============================================================================
-- MenuGreen Seed Data - Table: subscription_plans
-- Sequence Number: 06
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
('10000000-0000-0000-0000-000000000002', 'Pro Tháng/GYM', 'Thực đơn nâng cao, phân tích dinh dưỡng, hỗ trợ AI 24/7', 30, 99000, 'pro', true),
('10000000-0000-0000-0000-000000000003', 'Pro Năm', 'Tất cả tính năng Pro, tiết kiệm 20%, hỗ trợ offline và xuất báo cáo PDF', 365, 790000, 'pro', true),
('10000000-0000-0000-0000-000000000004', 'Gói Gym/PT', E'Mục tiêu calo, protein và lịch tập\nPT Review qua liên kết bảo mật\nKết nối huấn luyện viên và quản lý quyền truy cập\nLộ trình thể hình 8–12 tuần', NULL, 0, 'gym', true)
ON CONFLICT DO NOTHING;

COMMIT;
