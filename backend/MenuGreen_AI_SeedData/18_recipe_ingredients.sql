-- =============================================================================
-- MenuGreen Seed Data - Table: recipe_ingredients
-- Sequence Number: 18
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS recipe_ingredients CASCADE;

CREATE TABLE recipe_ingredients (
    "Id" uuid NOT NULL,
    "RecipeId" uuid NOT NULL,
    "IngredientId" uuid NOT NULL,
    "Quantity" numeric NULL,
    "Unit" text NULL,
    "Notes" text NULL,
    CONSTRAINT "PK_recipe_ingredients" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_recipe_ingredients_ingredients_IngredientId" FOREIGN KEY ("IngredientId") REFERENCES ingredients ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_recipe_ingredients_recipes_RecipeId" FOREIGN KEY ("RecipeId") REFERENCES recipes ("Id") ON DELETE CASCADE
);

INSERT INTO recipe_ingredients ("Id", "RecipeId", "IngredientId", "Quantity", "Unit", "Notes")
VALUES
('76fb457a-4f5d-4a4f-94cc-b53919344857', 'ec000001-0000-0000-0000-000000000001', '73cb3e0a-5abc-5c6c-a7a2-7a9ac350f4cd', 150.0, 'g', 'Ức gà phi lê tươi'),
('50336712-b29d-4c48-b65c-1b7833d62c7a', 'ec000001-0000-0000-0000-000000000001', '1ddf13c6-e4f7-5042-a801-62cb588e2dbd', 5.0, 'ml', 'Dầu olive áp chảo'),
('3f9fdd0b-fc3a-4ee5-9367-1c7a397b7166', 'ec000001-0000-0000-0000-000000000001', '5824249f-4a90-5eb8-ab3e-fe00ffdbf0bb', 20.0, 'g', 'Chanh tươi lấy cốt'),
('1408624f-5756-48f2-b7b6-ed3e35ba413e', 'ec000002-0000-0000-0000-000000000002', '73cb3e0a-5abc-5c6c-a7a2-7a9ac350f4cd', 100.0, 'g', 'Ức gà xé nhỏ'),
('43491dab-8ac9-41c0-b1ca-53e7c7effc69', 'ec000002-0000-0000-0000-000000000002', '36d9374a-4dc9-5066-bf57-ded98b96a211', 80.0, 'g', 'Bơ sáp cắt miếng'),
('c158cda6-c97b-4efb-9216-9de49c8f63e5', 'ec000002-0000-0000-0000-000000000002', '81d8c5d5-4bc9-5c71-86a5-70672e7764b4', 50.0, 'g', 'Rau xà lách tươi'),
('b5289b5d-29b1-4962-887a-625458d015d9', 'ec000003-0000-0000-0000-000000000003', 'ea000002-1111-2222-3333-444444444444', 150.0, 'g', 'Cá hồi Nauy fillet'),
('53d97887-6858-46bd-aa72-e242af01be0f', 'ec000003-0000-0000-0000-000000000003', '1ddf13c6-e4f7-5042-a801-62cb588e2dbd', 5.0, 'ml', 'Dầu olive'),
('2de24e2b-e006-4d7b-a29e-6fe44bfecce2', 'ec000004-0000-0000-0000-000000000004', 'ea000003-1111-2222-3333-444444444444', 50.0, 'g', 'Yến mạch cán vỡ'),
('6753a2ff-eefa-44b1-961a-b2609eb14445', 'ec000004-0000-0000-0000-000000000004', 'ea000004-1111-2222-3333-444444444444', 1.0, 'quả', 'Trứng gà tươi')
ON CONFLICT DO NOTHING;

COMMIT;