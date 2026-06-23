-- =============================================================================
-- MenuGreen Seed Data - Table: subscriptions
-- Sequence Number: 07
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

INSERT INTO subscriptions ("Id", "UserId", "PlanId", "Status", "AutoRenew", "StartedAt", "ExpiresAt")
VALUES
('00000000-1111-2222-3333-444444444401', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '10000000-0000-0000-0000-000000000003', 'Expired', false, now() - interval '375 days', now() - interval '10 days'),
('00000000-1111-2222-3333-444444444402', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '10000000-0000-0000-0000-000000000002', 'Active', true, now() - interval '15 days', now() + interval '15 days'),
('00000000-1111-2222-3333-444444444403', 'ffffffff-ffff-ffff-ffff-ffffffffffff', '10000000-0000-0000-0000-000000000003', 'Active', true, now() - interval '15 days', now() + interval '350 days')
ON CONFLICT DO NOTHING;

COMMIT;