-- =============================================================================
-- MenuGreen Seed Data - Table: roles
-- Sequence Number: 01
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS roles CASCADE;

CREATE TABLE roles (
    "Id" uuid NOT NULL,
    "Name" character varying(50) NOT NULL,
    "Description" text NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_roles" PRIMARY KEY ("Id")
);

INSERT INTO roles ("Id", "Name", "Description", "CreatedAt", "UpdatedAt")
VALUES
('00000000-0000-0000-0000-000000000001', 'Free', 'Free tier user', now(), now()),
('00000000-0000-0000-0000-000000000004', 'Admin', 'System administrator', now(), now()),
('00000000-0000-0000-0000-000000000005', 'Casual', 'Diet undecided or casual user', now(), now()),
('00000000-0000-0000-0000-000000000006', 'Gymer', 'Fitness and gym enthusiast', now(), now()),
('00000000-0000-0000-0000-000000000007', 'Office', 'Office and desk worker', now(), now()),
('00000000-0000-0000-0000-000000000008', 'Coach', 'Personal trainer / Nutrition coach', now(), now())
ON CONFLICT DO NOTHING;

COMMIT;