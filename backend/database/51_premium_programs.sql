-- =============================================================================
-- MenuGreen Seed Data - Table: premium_programs
-- Sequence Number: 51
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS premium_programs CASCADE;

CREATE TABLE premium_programs (
    "Id" uuid NOT NULL,
    "Title" character varying(255) NOT NULL,
    "Description" text NOT NULL,
    "DurationWeeks" integer NOT NULL,
    "TargetCaloriesDaily" integer NOT NULL,
    "GoalType" character varying(100) NOT NULL,
    "PriceVnd" integer NOT NULL,
    "SampleMenu" text NULL,
    "IsActive" boolean NOT NULL DEFAULT true,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_premium_programs" PRIMARY KEY ("Id")
);

-- Seed Data for premium_programs
-- (No seed data: programs are managed via admin UI / coach creation flow.)

COMMIT;