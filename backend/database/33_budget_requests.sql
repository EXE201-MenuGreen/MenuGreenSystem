-- =============================================================================
-- MenuGreen Seed Data - Table: budget_requests
-- Sequence Number: 33
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS budget_requests CASCADE;

CREATE TABLE budget_requests (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "BudgetVnd" integer NULL,
    "TimeLimitMin" integer NULL,
    "Result" json NULL,
    "CreatedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_budget_requests" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_budget_requests_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO budget_requests ("Id", "UserId", "BudgetVnd", "TimeLimitMin", "Result", "CreatedAt")
VALUES
('0160fb8e-51cf-4bbe-a263-bf4d98430f89', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('e91f53ce-36da-4ea6-90c8-0cf15b310c62', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('cc3e1f16-2760-4e1c-ab8b-f14860bfbc02', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('5080dc5e-170a-4aab-ad82-05d2bdb6d1c5', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('4ed09661-4d04-43c7-a696-d653152f8b47', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('998bb36f-306c-42f0-b643-a7ff76fa4d3b', '885810e8-168f-4608-a72e-e23a20dfd258', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('6710a97b-55c1-4edd-bbb5-deba8205635b', '48069bd5-f29a-417d-bdeb-c00797968aca', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('10683c83-6861-4fd9-a317-258e2d952811', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('cdcf3b60-e5d2-47eb-b1a0-d9b75cd44021', '081b4669-b97f-4e75-b089-4c8de0151653', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('1a24704f-d494-4feb-a0f3-f9f95a90e7cc', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('2fd2e3a0-de5e-4be8-bedd-c97f00597835', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('176b1981-0a1d-485d-976e-a4fe0094f0a5', '453681f7-f489-47ed-842c-bc3ffd220423', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('dea2301f-0b62-422c-b502-c7613510bb75', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('5613c5d4-404e-4a82-99b3-c64c754df45e', '5dc50160-db9e-447a-ba33-9026d8800ab5', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day'),
('77687b5f-0881-445a-bca9-addffd534305', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 150000, 30, '{"status": "success", "suggested_meals": [{"name": "Ức gà áp chảo", "price": 35000}, {"name": "Cơm gạo lứt", "price": 10000}]}', now() - interval '1 day')
ON CONFLICT DO NOTHING;

COMMIT;