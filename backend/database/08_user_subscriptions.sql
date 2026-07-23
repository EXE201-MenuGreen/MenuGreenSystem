-- =============================================================================
-- MenuGreen Seed Data - Table: user_subscriptions
-- Sequence Number: 08
--
-- 2026-07-24: Bỏ 14 dòng tham chiếu SubscriptionPlanId Pro (đã xóa khỏi
-- 06_subscription_plans.sql). FK RESTRICT sẽ chặn nếu còn insert tham chiếu
-- ID Pro không tồn tại.
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS user_subscriptions CASCADE;

CREATE TABLE user_subscriptions (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "SubscriptionPlanId" uuid NOT NULL,
    "Status" character varying(50) NOT NULL,
    "StartDate" timestamp with time zone NOT NULL,
    "EndDate" timestamp with time zone NOT NULL,
    "CancelledAt" timestamp with time zone NULL,
    "RenewedAt" timestamp with time zone NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_user_subscriptions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_user_subscriptions_subscription_plans_SubscriptionPlanId" FOREIGN KEY ("SubscriptionPlanId") REFERENCES subscription_plans ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_user_subscriptions_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

-- Seed dữ liệu mẫu cho 4 gói chính (không còn Pro).
INSERT INTO user_subscriptions ("Id", "UserId", "SubscriptionPlanId", "Status", "StartDate", "EndDate", "CancelledAt", "RenewedAt", "CreatedAt", "UpdatedAt")
VALUES
('00e3373b-a66f-4ae4-acf1-873d4f21e735', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '10000000-0000-0000-0000-000000000005', 'Active', now() - interval '15 days', now() + interval '350 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('5a589d0c-0879-4211-bcde-b80d8f872a2c', 'ffffffff-ffff-ffff-ffff-ffffffffffff', '10000000-0000-0000-0000-000000000006', 'Active', now() - interval '15 days', now() + interval '350 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('137a2257-8c0b-4b56-b4fa-be8da55e7c14', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', '10000000-0000-0000-0000-000000000004', 'Active', now() - interval '15 days', now() + interval '15 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days')
ON CONFLICT DO NOTHING;

COMMIT;