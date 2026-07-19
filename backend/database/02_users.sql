-- =============================================================================
-- MenuGreen Seed Data - Table: users
-- Sequence Number: 02
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    "Id" uuid NOT NULL,
    "RoleId" uuid NOT NULL,
    "Email" text NOT NULL,
    "PasswordHash" text NOT NULL,
    "EmailConfirmed" boolean NOT NULL DEFAULT false,
    "IsActive" boolean NOT NULL DEFAULT true,
    "LastSignInAt" timestamp with time zone NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    "DeletedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_users" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_users_roles_RoleId" FOREIGN KEY ("RoleId") REFERENCES roles ("Id") ON DELETE RESTRICT
);

INSERT INTO users ("Id", "RoleId", "Email", "PasswordHash", "EmailConfirmed", "IsActive", "LastSignInAt", "CreatedAt", "UpdatedAt", "DeletedAt")
VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '00000000-0000-0000-0000-000000000004', 'admin@menugreen.app', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now(), now() - interval '30 days', now() - interval '30 days', NULL),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '00000000-0000-0000-0000-000000000001', 'demo@menugreen.app', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('cccccccc-cccc-cccc-cccc-cccccccccccc', '00000000-0000-0000-0000-000000000001', 'free@menugreen.app', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('dddddddd-dddd-dddd-dddd-dddddddddddd', '00000000-0000-0000-0000-000000000001', 'free_user@menugreen.app', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '00000000-0000-0000-0000-000000000005', 'casual@menugreen.app', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('ffffffff-ffff-ffff-ffff-ffffffffffff', '00000000-0000-0000-0000-000000000006', 'gymer@menugreen.app', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('885810e8-168f-4608-a72e-e23a20dfd258', '00000000-0000-0000-0000-000000000001', 'nguyễnvănbình@gmail.com', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('48069bd5-f29a-417d-bdeb-c00797968aca', '00000000-0000-0000-0000-000000000001', 'trầnthịhoa@gmail.com', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', '00000000-0000-0000-0000-000000000001', 'phạmminhtuấn@gmail.com', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('081b4669-b97f-4e75-b089-4c8de0151653', '00000000-0000-0000-0000-000000000001', 'lêthịmai@gmail.com', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('586209d0-d3c4-43a4-bba7-5d4c73b37bc1', '00000000-0000-0000-0000-000000000007', 'office@menugreen.app', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', '00000000-0000-0000-0000-000000000001', 'vũthuhà@gmail.com', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('453681f7-f489-47ed-842c-bc3ffd220423', '00000000-0000-0000-0000-000000000001', 'phanhuyhoàng@gmail.com', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('396f9dff-6c2a-422f-b0cc-8eb451168ed3', '00000000-0000-0000-0000-000000000001', 'đỗmỹlinh@gmail.com', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('5dc50160-db9e-447a-ba33-9026d8800ab5', '00000000-0000-0000-0000-000000000001', 'bùiquốcanh@gmail.com', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('212ea8ea-749e-44a1-92d2-636bd617cbc8', '00000000-0000-0000-0000-000000000001', 'ngôkhánhvy@gmail.com', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL),
('cccccccc-cccc-cccc-cccc-cccccccccc01', '00000000-0000-0000-0000-000000000008', 'coach@menugreen.app', '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey', true, true, now() - interval '1 day', now() - interval '30 days', now() - interval '30 days', NULL)
ON CONFLICT DO NOTHING;

COMMIT;