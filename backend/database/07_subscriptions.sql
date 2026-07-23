-- =============================================================================
-- MenuGreen Seed Data - Table: subscriptions
-- Sequence Number: 07
--
-- 2026-07-24: Bỏ 3 dòng tham chiếu PlanId Pro (đã xóa khỏi 06_subscription_plans.sql).
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS subscriptions CASCADE;

CREATE TABLE subscriptions (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "PlanId" uuid NOT NULL,
    "Status" text NULL,
    "AutoRenew" boolean NULL,
    "StartedAt" timestamp with time zone NULL,
    "ExpiresAt" timestamp with time zone NULL,
    CONSTRAINT "PK_subscriptions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_subscriptions_subscription_plans_PlanId" FOREIGN KEY ("PlanId") REFERENCES subscription_plans ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_subscriptions_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

-- Seed dữ liệu mẫu cho 4 gói chính (không còn Pro).
INSERT INTO subscriptions ("Id", "UserId", "PlanId", "Status", "AutoRenew", "StartedAt", "ExpiresAt")
SELECT
    '00000000-1111-2222-3333-44444444440a',
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    '10000000-0000-0000-0000-000000000005',
    'Active',
    true,
    now() - interval '15 days',
    now() + interval '350 days'
WHERE NOT EXISTS (
    SELECT 1 FROM subscriptions WHERE "Id" = '00000000-1111-2222-3333-44444444440a'
);

COMMIT;