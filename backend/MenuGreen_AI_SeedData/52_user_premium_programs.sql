-- =============================================================================
-- MenuGreen Seed Data - Table: user_premium_programs
-- Sequence Number: 52
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS user_premium_programs CASCADE;

CREATE TABLE user_premium_programs (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "ProgramId" uuid NOT NULL,
    "StartDate" date NULL,
    "Status" character varying(50) NOT NULL DEFAULT 'PendingPayment',
    "CurrentWeek" integer NOT NULL DEFAULT 1,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_user_premium_programs" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_user_premium_programs_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_user_premium_programs_premium_programs_ProgramId" FOREIGN KEY ("ProgramId") REFERENCES premium_programs ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "IX_user_premium_programs_UserId_ProgramId" ON user_premium_programs ("UserId", "ProgramId");

-- Seed Data for user_premium_programs
INSERT INTO user_premium_programs ("Id", "UserId", "ProgramId", "StartDate", "Status", "CurrentWeek", "CreatedAt", "UpdatedAt")
VALUES
('f2000000-0000-0000-0000-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'f1000000-0000-0000-0000-000000000001', CURRENT_DATE - 10, 'Active', 2, now(), now())
ON CONFLICT DO NOTHING;

COMMIT;