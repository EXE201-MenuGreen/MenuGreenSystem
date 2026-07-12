-- =============================================================================
-- MenuGreen Seed Data - Table: meal_template_items
-- Sequence Number: 38
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS meal_template_items CASCADE;

CREATE TABLE meal_template_items (
    "Id" uuid NOT NULL,
    "MealTemplateId" uuid NOT NULL,
    "FoodId" uuid NULL,
    "RecipeId" uuid NULL,
    "QuantityG" numeric(18,2) NOT NULL,
    "Notes" character varying(1000) NULL,
    "SortOrder" integer NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_meal_template_items" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_meal_template_items_meal_templates_MealTemplateId" FOREIGN KEY ("MealTemplateId") REFERENCES meal_templates ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_meal_template_items_foods_FoodId" FOREIGN KEY ("FoodId") REFERENCES foods ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_meal_template_items_recipes_RecipeId" FOREIGN KEY ("RecipeId") REFERENCES recipes ("Id") ON DELETE CASCADE
);

CREATE INDEX "IX_meal_template_items_MealTemplateId" ON meal_template_items ("MealTemplateId");

-- Seed Data for meal_template_items
INSERT INTO meal_template_items ("Id", "MealTemplateId", "FoodId", "RecipeId", "QuantityG", "Notes", "SortOrder", "CreatedAt")
VALUES
('bbbbbbbb-1111-1111-1111-bbbbbbbbbb01', '99999999-9999-9999-9999-999999999901', 'fd000004-0000-0000-0000-000000000004', NULL, 150.00, 'Ăn nguội hoặc quay nóng lại', 1, now() - interval '5 days'),
('bbbbbbbb-2222-2222-2222-bbbbbbbbbb02', '99999999-9999-9999-9999-999999999902', 'fd000001-0000-0000-0000-000000000001', NULL, 180.00, 'Ức gà nạc không da', 1, now() - interval '3 days'),
('bbbbbbbb-2222-2222-2222-bbbbbbbbbb03', '99999999-9999-9999-9999-999999999902', 'fd000002-0000-0000-0000-000000000002', NULL, 150.00, 'Gạo lứt đỏ', 2, now() - interval '3 days')
ON CONFLICT DO NOTHING;

COMMIT;