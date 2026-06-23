-- =============================================================================
-- MenuGreen Seed Data - Table: email_verifications
-- Sequence Number: 13
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS email_verifications CASCADE;

CREATE TABLE email_verifications (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "OtpCode" character varying(20) NOT NULL,
    "ExpiresAt" timestamp with time zone NOT NULL,
    "VerifiedAt" timestamp with time zone NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_email_verifications" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_email_verifications_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO email_verifications ("Id", "UserId", "OtpCode", "ExpiresAt", "VerifiedAt", "CreatedAt")
VALUES
('66666666-6666-6666-6666-666666666601', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '123456', now() - interval '30 days' + interval '10 minutes', now() - interval '30 days' + interval '2 minutes', now() - interval '30 days'),
('66666666-6666-6666-6666-666666666602', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '654321', now() - interval '30 days' + interval '10 minutes', now() - interval '30 days' + interval '2 minutes', now() - interval '30 days'),
('66666666-6666-6666-6666-666666666603', 'ffffffff-ffff-ffff-ffff-ffffffffffff', '987654', now() - interval '30 days' + interval '10 minutes', now() - interval '30 days' + interval '2 minutes', now() - interval '30 days')
ON CONFLICT DO NOTHING;

COMMIT;