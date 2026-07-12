-- =============================================================================
-- MenuGreen Seed Data - Table: premium_programs
-- Sequence Number: 51
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS premium_programs CASCADE;

CREATE TABLE premium_programs (
    "Id" uuid NOT NULL,
    "Title" character varying(255) NOT NULL,
    "Description" text NOT NULL,
    "DurationWeeks" integer NOT NULL,
    "TargetCaloriesDaily" integer NOT NULL,
    "GoalType" character varying(100) NOT NULL,
    "PriceVnd" integer NOT NULL,
    "SampleMenu" text NULL,
    "IsActive" boolean NOT NULL DEFAULT true,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_premium_programs" PRIMARY KEY ("Id")
);

-- Seed Data for premium_programs
INSERT INTO premium_programs ("Id", "Title", "Description", "DurationWeeks", "TargetCaloriesDaily", "GoalType", "PriceVnd", "SampleMenu", "IsActive", "CreatedAt")
VALUES
('f1000000-0000-0000-0000-000000000001', 'Chương trình Siết Cơ Giảm Mỡ 8 Tuần', 'Chương trình luyện tập và dinh dưỡng cường độ cao dành cho người muốn giảm mỡ hiệu quả trong 8 tuần.', 8, 1600, 'LoseWeight', 299000, 'Ức gà áp chảo | Sinh tố bơ chuối | Gạo lứt thịt bò thăn', true, now()),
('f1000000-0000-0000-0000-000000000002', 'Ăn Sạch Sống Khỏe 12 Tuần', 'Học cách thiết lập thói quen ăn uống lành mạnh tự nhiên không áp lực.', 12, 1800, 'HealthyEating', 399000, 'Yến mạch ngâm sữa chua | Đậu hũ sốt cà chua | Cá hồi nướng súp lơ', true, now())
ON CONFLICT DO NOTHING;

COMMIT;