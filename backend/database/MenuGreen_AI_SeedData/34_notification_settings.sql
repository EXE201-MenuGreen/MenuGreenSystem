-- =============================================================================
-- MenuGreen Seed Data - Table: notification_settings
-- Sequence Number: 34
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS notification_settings CASCADE;

CREATE TABLE notification_settings (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "MealReminderEnabled" boolean NOT NULL DEFAULT true,
    "MealReminderOffsetMinutes" integer NOT NULL DEFAULT 30,
    "PrepReminderEnabled" boolean NOT NULL DEFAULT true,
    "PrepReminderOffsetMinutes" integer NOT NULL DEFAULT 20,
    "InAppEnabled" boolean NOT NULL DEFAULT true,
    "PushEnabled" boolean NOT NULL DEFAULT false,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_notification_settings" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_notification_settings_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO notification_settings ("Id", "UserId", "MealReminderEnabled", "MealReminderOffsetMinutes", "PrepReminderEnabled", "PrepReminderOffsetMinutes", "InAppEnabled", "PushEnabled", "CreatedAt", "UpdatedAt")
VALUES
('9cfd98b1-345a-495e-9b88-818957d1d4d7', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', true, 30, true, 20, true, true, now(), now()),
('45456983-3d83-4b3c-bb18-c16943b88c6c', 'cccccccc-cccc-cccc-cccc-cccccccccccc', true, 30, true, 20, true, true, now(), now()),
('925c4319-7aaa-47f3-ac63-fbe69c8ec8a6', 'dddddddd-dddd-dddd-dddd-dddddddddddd', true, 30, true, 20, true, true, now(), now()),
('0ad58745-4382-40fc-952c-6c5533af072e', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', true, 30, true, 20, true, true, now(), now()),
('42824d36-8062-4974-ad23-bd639987b249', 'ffffffff-ffff-ffff-ffff-ffffffffffff', true, 30, true, 20, true, true, now(), now()),
('c2a4a5c4-5d46-4479-97d5-568a31856220', '885810e8-168f-4608-a72e-e23a20dfd258', true, 30, true, 20, true, true, now(), now()),
('7dafb9de-2c68-4168-bf05-6c21676a6c7a', '48069bd5-f29a-417d-bdeb-c00797968aca', true, 30, true, 20, true, true, now(), now()),
('b9183c29-0125-47a7-a2e8-bfc140686ff2', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', true, 30, true, 20, true, true, now(), now()),
('63d15ccc-6ba0-4c3c-98dd-787d75352155', '081b4669-b97f-4e75-b089-4c8de0151653', true, 30, true, 20, true, true, now(), now()),
('43f82d5c-bd79-4646-81b7-ccf3282a7829', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', true, 30, true, 20, true, true, now(), now()),
('8f813477-425d-4758-89dc-63f5e10b6b44', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', true, 30, true, 20, true, true, now(), now()),
('3b64a3c3-4da5-449a-8b44-cc8c03d0f2e6', '453681f7-f489-47ed-842c-bc3ffd220423', true, 30, true, 20, true, true, now(), now()),
('675434c6-f437-4535-b7bc-cbed45cfafa2', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', true, 30, true, 20, true, true, now(), now()),
('f47f9094-d6db-42ba-ab9b-f8908e4a3efa', '5dc50160-db9e-447a-ba33-9026d8800ab5', true, 30, true, 20, true, true, now(), now()),
('2b50ba2d-4f52-422b-827c-d460412636ec', '212ea8ea-749e-44a1-92d2-636bd617cbc8', true, 30, true, 20, true, true, now(), now())
ON CONFLICT DO NOTHING;

COMMIT;