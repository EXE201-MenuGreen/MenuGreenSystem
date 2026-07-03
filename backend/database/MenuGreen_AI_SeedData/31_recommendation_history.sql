-- =============================================================================
-- MenuGreen Seed Data - Table: recommendation_history
-- Sequence Number: 31
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS recommendation_history CASCADE;

CREATE TABLE recommendation_history (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "Type" text NULL,
    "Input" json NULL,
    "Output" json NULL,
    "Confidence" numeric NULL,
    "CreatedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_recommendation_history" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_recommendation_history_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO recommendation_history ("Id", "UserId", "Type", "Input", "Output", "Confidence", "CreatedAt")
VALUES
('140e2a62-2316-4185-a98b-f5b5b6287ca5', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('a8e10ff4-a461-4c2f-aeb3-1ca94cede19f', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('f2138dcd-8a30-4827-a0e3-7df069f05190', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('5c0b848c-95a3-4a92-8de8-8ccc6e400531', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('eea98ac7-8b45-481e-8ae6-5c549004e1eb', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('277d5e7a-7dcf-4395-93e7-357f7cbf8dcc', '885810e8-168f-4608-a72e-e23a20dfd258', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('e313742d-5776-4568-8c02-831cde456d23', '48069bd5-f29a-417d-bdeb-c00797968aca', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('5b4dbeef-0350-4be0-8ee5-659f9e86a9bd', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('fddb765c-9e8a-4781-a1f7-cee4c9b3fc2b', '081b4669-b97f-4e75-b089-4c8de0151653', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('4bd2dd83-48b4-46de-8ef0-066b3abb978c', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('ae83de28-51fa-405b-bd68-c86375f7b7b1', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('9770f4e1-b730-4a87-ab8b-4c5c3e2bfaea', '453681f7-f489-47ed-842c-bc3ffd220423', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('7ac9afe9-6031-4e98-8d93-b98131187e59', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('cd2ee33c-d1d6-4877-9522-21f36c0b363a', '5dc50160-db9e-447a-ba33-9026d8800ab5', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day'),
('02d7b550-4ee9-474c-aedd-19eb5f834bef', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 'MealPlan', '{"calories": 1800, "goal": "lose weight", "preferred": "Vietnamese"}', '{"breakfast": "Cháo yến mạch", "lunch": "Salad ức gà", "dinner": "Cá hồi áp chảo"}', 0.95, now() - interval '1 day')
ON CONFLICT DO NOTHING;

COMMIT;