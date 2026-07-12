-- =============================================================================
-- MenuGreen Seed Data - Table: meal_plan_headers
-- Sequence Number: 24
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS meal_plan_headers CASCADE;

CREATE TABLE meal_plan_headers (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "Title" character varying(255) NULL,
    "PlanType" character varying(50) NULL,
    "StartDate" date NULL,
    "EndDate" date NULL,
    "TargetCalories" integer NULL,
    "GeneratedBy" character varying(50) NULL,
    "IsActive" boolean NOT NULL DEFAULT true,
    "CreatedAt" timestamp with time zone NULL,
    "UpdatedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_meal_plan_headers" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_meal_plan_headers_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO meal_plan_headers ("Id", "UserId", "Title", "PlanType", "StartDate", "EndDate", "TargetCalories", "GeneratedBy", "IsActive", "CreatedAt", "UpdatedAt")
VALUES
('f22fed1c-b548-4fc7-a4db-9dc571e61d74', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('d677be5c-3bf9-45a0-838e-be2013c93934', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('dacdeef2-185a-49e1-8d10-aae4d507cb22', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('e95a2ac3-cbb8-427b-b433-3de2ea447729', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('ee8bb747-45d4-41bf-a522-2384ef74e18c', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('43bd57bf-06ff-4391-a8f1-202e9248e7ed', '885810e8-168f-4608-a72e-e23a20dfd258', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('128cae5c-6edc-4ea3-b8ac-af67c4952f6e', '48069bd5-f29a-417d-bdeb-c00797968aca', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('44c0c107-5c01-4dc9-8cfc-e69a50ec83d7', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('c1b905f7-c948-4506-87b3-cb1f359e9cbc', '081b4669-b97f-4e75-b089-4c8de0151653', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('07fbdd58-1b92-441b-ad7d-1f01c9cf1e63', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('457cbba7-31e6-4e56-8073-5e8067640cdc', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('d67fd2c9-bb6b-4216-a5eb-c62b189285d0', '453681f7-f489-47ed-842c-bc3ffd220423', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('471293e8-4b51-413c-a739-9aabc9cdfbc9', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('ed136f5e-f381-4e17-8aa7-5db67bd34146', '5dc50160-db9e-447a-ba33-9026d8800ab5', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now()),
('401f123d-9dc9-40dd-ad44-11dea7dfbe3a', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 'Kế hoạch dinh dưỡng tuần mới', 'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7, 1800, 'AI', true, now(), now())
ON CONFLICT DO NOTHING;

COMMIT;