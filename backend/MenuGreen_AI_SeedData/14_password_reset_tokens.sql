-- =============================================================================
-- MenuGreen Seed Data - Table: password_reset_tokens
-- Sequence Number: 14
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS password_reset_tokens CASCADE;

CREATE TABLE password_reset_tokens (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "Token" text NOT NULL,
    "ExpiresAt" timestamp with time zone NOT NULL,
    "UsedAt" timestamp with time zone NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_password_reset_tokens" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_password_reset_tokens_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO password_reset_tokens ("Id", "UserId", "Token", "ExpiresAt", "UsedAt", "CreatedAt")
VALUES
('88888888-9999-aaaa-bbbb-cccccccccccc', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'RESET_TOKEN_DEMO_XYZ', now() - interval '5 days' + interval '1 hour', now() - interval '5 days' + interval '15 minutes', now() - interval '5 days')
ON CONFLICT DO NOTHING;

COMMIT;