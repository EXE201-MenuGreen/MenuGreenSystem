-- =============================================================================
-- MenuGreen Seed Data - Table: reminder_profiles
-- Sequence Number: 40
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS reminder_profiles CASCADE;

CREATE TABLE reminder_profiles (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "OptimalBreakfastTime" time without time zone NOT NULL,
    "OptimalLunchTime" time without time zone NOT NULL,
    "OptimalDinnerTime" time without time zone NOT NULL,
    "LastRecalculatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_reminder_profiles" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_reminder_profiles_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

CREATE INDEX "IX_reminder_profiles_UserId" ON reminder_profiles ("UserId");

-- Seed Data for reminder_profiles
INSERT INTO reminder_profiles ("Id", "UserId", "OptimalBreakfastTime", "OptimalLunchTime", "OptimalDinnerTime", "LastRecalculatedAt")
VALUES
('77777777-7777-7777-7777-777777777701', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '08:00:00', '12:30:00', '19:15:00', now()),
('77777777-7777-7777-7777-777777777702', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '07:30:00', '12:00:00', '18:45:00', now()),
('77777777-7777-7777-7777-777777777703', 'ffffffff-ffff-ffff-ffff-ffffffffffff', '08:30:00', '13:00:00', '20:00:00', now())
ON CONFLICT DO NOTHING;

COMMIT;
