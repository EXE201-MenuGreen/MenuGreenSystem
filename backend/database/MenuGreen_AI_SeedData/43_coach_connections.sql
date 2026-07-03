-- =============================================================================
-- MenuGreen Seed Data - Table: coach_connections
-- Sequence Number: 43
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS coach_connections CASCADE;

CREATE TABLE coach_connections (
    "Id" uuid NOT NULL,
    "ClientId" uuid NOT NULL,
    "CoachId" uuid NOT NULL,
    "Status" character varying(50) NOT NULL DEFAULT 'Pending',
    "IsAccessGranted" boolean NOT NULL DEFAULT false,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_coach_connections" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_coach_connections_users_ClientId" FOREIGN KEY ("ClientId") REFERENCES users ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_coach_connections_users_CoachId" FOREIGN KEY ("CoachId") REFERENCES users ("Id") ON DELETE CASCADE
);

-- Seed Data for coach_connections
INSERT INTO coach_connections ("Id", "ClientId", "CoachId", "Status", "IsAccessGranted", "CreatedAt", "UpdatedAt")
VALUES
('80000000-0000-0000-0000-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Connected', true, now() - interval '10 days', now() - interval '10 days')
ON CONFLICT DO NOTHING;

COMMIT;