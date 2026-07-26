-- =============================================================================
-- MenuGreen Seed Data - Table: user_ai_profile
-- Sequence Number: 04
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS user_ai_profile CASCADE;

CREATE TABLE user_ai_profile (
    "UserId" uuid NOT NULL,
    "Preferences" jsonb NULL,
    "DislikedFoods" jsonb NULL,
    "EatingPattern" jsonb NULL,
    "UpdatedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_user_ai_profile" PRIMARY KEY ("UserId"),
    CONSTRAINT "FK_user_ai_profile_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO user_ai_profile ("UserId", "Preferences", "DislikedFoods", "EatingPattern", "UpdatedAt")
VALUES
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now()),
('cccccccc-cccc-cccc-cccc-cccccccccccc', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now()),
('dddddddd-dddd-dddd-dddd-dddddddddddd', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now()),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now()),
('ffffffff-ffff-ffff-ffff-ffffffffffff', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '"gym"', now()),
('885810e8-168f-4608-a72e-e23a20dfd258', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now()),
('48069bd5-f29a-417d-bdeb-c00797968aca', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now()),
('9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now()),
('081b4669-b97f-4e75-b089-4c8de0151653', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now()),
('586209d0-d3c4-43a4-bba7-5d4c73b37bc1', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now()),
('b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now()),
('453681f7-f489-47ed-842c-bc3ffd220423', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now()),
('396f9dff-6c2a-422f-b0cc-8eb451168ed3', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now()),
('5dc50160-db9e-447a-ba33-9026d8800ab5', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now()),
('212ea8ea-749e-44a1-92d2-636bd617cbc8', '{"likes": ["salad", "smoothie", "ức gà"], "goals": ["lose weight"]}', '["fried foods", "fast food", "mỡ động vật"]', '{"meals_per_day": 3, "eating_speed": "moderate"}', now())
ON CONFLICT DO NOTHING;

COMMIT;