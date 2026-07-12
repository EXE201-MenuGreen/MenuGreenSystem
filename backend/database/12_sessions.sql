-- =============================================================================
-- MenuGreen Seed Data - Table: sessions
-- Sequence Number: 12
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS sessions CASCADE;

CREATE TABLE sessions (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "RefreshToken" text NOT NULL,
    "UserAgent" text NULL,
    "IpAddress" inet NULL,
    "ExpiresAt" timestamp with time zone NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_sessions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_sessions_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO sessions ("Id", "UserId", "RefreshToken", "UserAgent", "IpAddress", "ExpiresAt", "CreatedAt")
VALUES
('55555555-5555-5555-5555-555555555501', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'REFRESH_TOKEN_DEMO_123456', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', '127.0.0.1', now() + interval '7 days', now()),
('55555555-5555-5555-5555-555555555502', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'REFRESH_TOKEN_PRO_123456', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X)', '192.168.1.5', now() + interval '7 days', now()),
('55555555-5555-5555-5555-555555555503', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'REFRESH_TOKEN_PREMIUM_123456', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', '172.16.0.2', now() + interval '7 days', now())
ON CONFLICT DO NOTHING;

COMMIT;