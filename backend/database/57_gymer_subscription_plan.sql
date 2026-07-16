-- Add the standalone Gym/PT package without recreating subscription tables.
-- Safe to run against an existing database. Price is intentionally 0 VND and
-- can be edited later through SubscriptionPlan management.
BEGIN;

INSERT INTO subscription_plans (
    "Id",
    "Name",
    "Description",
    "DurationDays",
    "PriceVnd",
    "FeatureGroup",
    "IsActive"
)
VALUES (
    '10000000-0000-0000-0000-000000000004',
    'Gói Gym/PT',
    E'Mục tiêu calo, protein và lịch tập\nPT Review qua liên kết bảo mật\nKết nối huấn luyện viên và quản lý quyền truy cập\nLộ trình thể hình 8–12 tuần',
    NULL,
    0,
    'gym',
    true
)
ON CONFLICT ("Id") DO UPDATE SET
    "Name" = EXCLUDED."Name",
    "Description" = EXCLUDED."Description",
    "DurationDays" = EXCLUDED."DurationDays",
    "FeatureGroup" = EXCLUDED."FeatureGroup",
    "IsActive" = EXCLUDED."IsActive";

COMMIT;
