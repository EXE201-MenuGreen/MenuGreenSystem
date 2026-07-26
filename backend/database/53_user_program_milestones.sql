-- =============================================================================
-- MenuGreen Seed Data - Table: user_program_milestones
-- Sequence Number: 53
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS user_program_milestones CASCADE;

CREATE TABLE user_program_milestones (
    "Id" uuid NOT NULL,
    "UserProgramId" uuid NOT NULL,
    "WeekNumber" integer NOT NULL,
    "IsUnlocked" boolean NOT NULL DEFAULT false,
    "IsCheckedIn" boolean NOT NULL DEFAULT false,
    "WeightKg" numeric(18,2) NULL,
    "BodyFatPercent" numeric(18,2) NULL,
    "ChestCm" numeric(18,2) NULL,
    "WaistCm" numeric(18,2) NULL,
    "HipCm" numeric(18,2) NULL,
    "RewardPoints" integer NOT NULL DEFAULT 0,
    "BadgeName" character varying(100) NULL,
    "CheckInDate" timestamp with time zone NULL,
    "UnlockedAt" timestamp with time zone NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_user_program_milestones" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_user_program_milestones_user_premium_programs_UserProgramId" FOREIGN KEY ("UserProgramId") REFERENCES user_premium_programs ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "IX_user_program_milestones_UserProgramId_WeekNumber" ON user_program_milestones ("UserProgramId", "WeekNumber");

-- No seed milestones: user_premium_programs intentionally has no seed
-- enrollments, and milestones are created after a real enrollment exists.

COMMIT;
