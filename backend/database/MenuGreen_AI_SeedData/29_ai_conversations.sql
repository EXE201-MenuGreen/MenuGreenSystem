-- =============================================================================
-- MenuGreen Seed Data - Table: ai_conversations
-- Sequence Number: 29
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS ai_conversations CASCADE;

CREATE TABLE ai_conversations (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "Title" text NULL,
    "CreatedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_ai_conversations" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_ai_conversations_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO ai_conversations ("Id", "UserId", "Title", "CreatedAt")
VALUES
('1dda1f54-2e1c-4b44-adaa-d71e55270f8c', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Tư vấn giảm cân', now() - interval '2 days'),
('4ab8fafe-c92c-452f-97ae-57f0b4729099', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('1a0854c9-fbf6-48d9-812c-49c7cce7ee06', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Tư vấn giảm cân', now() - interval '2 days'),
('f2fce726-40f7-49ba-a9ed-ecce006c1e61', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('71c3d48a-392f-46f6-af0b-c136f4faf1eb', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Tư vấn giảm cân', now() - interval '2 days'),
('087d1351-99fd-4644-b997-2a59c68d8521', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('cd6451d7-008e-4d66-a500-e213c35613ec', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Tư vấn giảm cân', now() - interval '2 days'),
('b48896d7-d728-45f9-b544-f951ac4d62a0', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('0521115f-b220-479a-93bd-16107fbceadc', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Tư vấn giảm cân', now() - interval '2 days'),
('9bf431b6-3a64-4017-ab1f-7a354ed503b8', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('5cf92fb1-e906-459f-9cb1-2b31ae9cbfd5', '885810e8-168f-4608-a72e-e23a20dfd258', 'Tư vấn giảm cân', now() - interval '2 days'),
('67e6d1e8-1a0a-4625-9333-3ffdc0981b74', '885810e8-168f-4608-a72e-e23a20dfd258', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('91f676bf-2d0e-4002-9e79-ff48ce390a29', '48069bd5-f29a-417d-bdeb-c00797968aca', 'Tư vấn giảm cân', now() - interval '2 days'),
('0148f946-b794-4ea4-b6e0-307a0ac6a70b', '48069bd5-f29a-417d-bdeb-c00797968aca', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('ffb7ad29-6e56-4fac-8deb-25ed12c90698', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'Tư vấn giảm cân', now() - interval '2 days'),
('3c1144cd-778e-4413-87fe-939805b3419e', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('a7d62c32-d5a7-421f-be2f-19ecd79d66a2', '081b4669-b97f-4e75-b089-4c8de0151653', 'Tư vấn giảm cân', now() - interval '2 days'),
('53d8c70b-a6c5-449c-8685-8b3e2df94e6d', '081b4669-b97f-4e75-b089-4c8de0151653', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('3a68eec3-0766-4152-b14d-163e359c5f54', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 'Tư vấn giảm cân', now() - interval '2 days'),
('89cbeb02-f385-453e-85c1-3713bdfd64bb', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('2e13f918-6c28-476c-ab18-58b3aecc8700', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 'Tư vấn giảm cân', now() - interval '2 days'),
('9f09129b-0854-403d-b2fd-a8b84d6eb029', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('f3519ca6-9581-4e0c-8f39-fbb591b021eb', '453681f7-f489-47ed-842c-bc3ffd220423', 'Tư vấn giảm cân', now() - interval '2 days'),
('a088a941-7975-4a45-8ddc-ed3f28210969', '453681f7-f489-47ed-842c-bc3ffd220423', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('2e97c0b5-7c0d-46ea-a36a-60e1e375f6bd', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 'Tư vấn giảm cân', now() - interval '2 days'),
('9a5a2c52-6d4c-494a-92a7-f194a564a1e3', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('9877c046-f1fc-460a-b5b8-cbc472248b5e', '5dc50160-db9e-447a-ba33-9026d8800ab5', 'Tư vấn giảm cân', now() - interval '2 days'),
('61907a0d-f782-4440-a0e3-ce70857f1dc1', '5dc50160-db9e-447a-ba33-9026d8800ab5', 'Thực đơn tập gym tăng cơ', now() - interval '2 days'),
('ea792b53-85d6-44d5-b266-ce649e298b2d', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 'Tư vấn giảm cân', now() - interval '2 days'),
('122f09d2-1081-4f20-88b9-bd4effe769de', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 'Thực đơn tập gym tăng cơ', now() - interval '2 days')
ON CONFLICT DO NOTHING;

COMMIT;