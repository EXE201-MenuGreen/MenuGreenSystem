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
('00000000-0000-0000-0000-000000000001', 'Free', 'Gói người dùng miễn phí', now(), now()),
('00000000-0000-0000-0000-000000000002', 'Pro', 'Gói Pro / Premium quyền lợi cao nhất', now(), now()),
('00000000-0000-0000-0000-000000000003', 'User', 'Standard system user role', now(), now()),
('00000000-0000-0000-0000-000000000004', 'Admin', 'Quản trị viên hệ thống', now(), now())
ON CONFLICT DO NOTHING;

COMMIT;