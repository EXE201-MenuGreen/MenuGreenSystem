-- =============================================================================
-- MenuGreen Seed Data - Table: meal_templates
-- Sequence Number: 37
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS meal_templates CASCADE;

CREATE TABLE meal_templates (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "Title" character varying(255) NOT NULL,
    "Description" character varying(1000) NULL,
    "MealType" character varying(50) NULL,
    "UsageCount" integer NOT NULL DEFAULT 0,
    "IsActive" boolean NOT NULL DEFAULT true,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_meal_templates" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_meal_templates_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

CREATE INDEX "IX_meal_templates_UserId" ON meal_templates ("UserId");

CREATE INDEX "IX_meal_templates_MealType" ON meal_templates ("MealType");

-- Seed Data for meal_templates
INSERT INTO meal_templates ("Id", "UserId", "Title", "Description", "MealType", "UsageCount", "IsActive", "CreatedAt", "UpdatedAt")
VALUES
('99999999-9999-9999-9999-999999999901', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Bữa sáng Eat Clean nhanh', 'Yến mạch ngâm sữa chua và chuối chín', 'Breakfast', 0, true, now() - interval '5 days', now() - interval '5 days'),
('99999999-9999-9999-9999-999999999902', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Bữa trưa siết mỡ PT', 'Ức gà luộc, khoai lang và súp lơ xanh', 'Lunch', 0, true, now() - interval '3 days', now() - interval '3 days')
ON CONFLICT DO NOTHING;

COMMIT;