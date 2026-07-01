-- =============================================================================
-- MenuGreen Seed Data - Table: favorite_foods
-- Sequence Number: 20
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS favorite_foods CASCADE;

CREATE TABLE favorite_foods (
    "UserId" uuid NOT NULL,
    "FoodId" uuid NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_favorite_foods" PRIMARY KEY ("UserId", "FoodId"),
    CONSTRAINT "FK_favorite_foods_foods_FoodId" FOREIGN KEY ("FoodId") REFERENCES foods ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_favorite_foods_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO favorite_foods ("UserId", "FoodId", "CreatedAt")
VALUES
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'fd000009-0000-0000-0000-000000000009', now()),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'fd000002-0000-0000-0000-000000000002', now()),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'fd000010-0000-0000-0000-000000000010', now()),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'fd000007-0000-0000-0000-000000000007', now()),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'fd000001-0000-0000-0000-000000000001', now()),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'fd000010-0000-0000-0000-000000000010', now()),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'fd000002-0000-0000-0000-000000000002', now()),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'fd000004-0000-0000-0000-000000000004', now()),
('ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd000004-0000-0000-0000-000000000004', now()),
('ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd000009-0000-0000-0000-000000000009', now()),
('885810e8-168f-4608-a72e-e23a20dfd258', 'fd000010-0000-0000-0000-000000000010', now()),
('885810e8-168f-4608-a72e-e23a20dfd258', 'fd000001-0000-0000-0000-000000000001', now()),
('48069bd5-f29a-417d-bdeb-c00797968aca', 'fd000009-0000-0000-0000-000000000009', now()),
('48069bd5-f29a-417d-bdeb-c00797968aca', 'fd000004-0000-0000-0000-000000000004', now()),
('9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'fd000009-0000-0000-0000-000000000009', now()),
('9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'fd000007-0000-0000-0000-000000000007', now()),
('081b4669-b97f-4e75-b089-4c8de0151653', 'fd000004-0000-0000-0000-000000000004', now()),
('081b4669-b97f-4e75-b089-4c8de0151653', 'fd000008-0000-0000-0000-000000000008', now()),
('586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 'fd000010-0000-0000-0000-000000000010', now()),
('586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 'fd000005-0000-0000-0000-000000000005', now()),
('b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 'fd000001-0000-0000-0000-000000000001', now()),
('b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 'fd000003-0000-0000-0000-000000000003', now()),
('453681f7-f489-47ed-842c-bc3ffd220423', 'fd000007-0000-0000-0000-000000000007', now()),
('453681f7-f489-47ed-842c-bc3ffd220423', 'fd000006-0000-0000-0000-000000000006', now()),
('396f9dff-6c2a-422f-b0cc-8eb451168ed3', 'fd000005-0000-0000-0000-000000000005', now()),
('396f9dff-6c2a-422f-b0cc-8eb451168ed3', 'fd000003-0000-0000-0000-000000000003', now()),
('5dc50160-db9e-447a-ba33-9026d8800ab5', 'fd000004-0000-0000-0000-000000000004', now()),
('5dc50160-db9e-447a-ba33-9026d8800ab5', 'fd000006-0000-0000-0000-000000000006', now()),
('212ea8ea-749e-44a1-92d2-636bd617cbc8', 'fd000002-0000-0000-0000-000000000002', now()),
('212ea8ea-749e-44a1-92d2-636bd617cbc8', 'fd000010-0000-0000-0000-000000000010', now())
ON CONFLICT DO NOTHING;

COMMIT;