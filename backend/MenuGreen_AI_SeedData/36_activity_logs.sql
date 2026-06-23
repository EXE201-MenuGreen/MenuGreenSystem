-- =============================================================================
-- MenuGreen Seed Data - Table: activity_logs
-- Sequence Number: 36
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS activity_logs CASCADE;

CREATE TABLE activity_logs (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "Action" text NULL,
    "EntityType" text NULL,
    "EntityId" uuid NULL,
    "Metadata" json NULL,
    "CreatedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_activity_logs" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_activity_logs_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO activity_logs ("Id", "UserId", "Action", "EntityType", "EntityId", "Metadata", "CreatedAt")
VALUES
('18e33332-e911-4278-9787-52142237fa61', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'LogMeal', 'Meal', '463bf7db-2969-40a5-b260-71f45597718e', '{"action": "logmeal", "status": "completed"}', now()),
('9481ae88-b18a-4f11-92bc-6b239b6d19e2', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'UpdateWeight', 'UpdateWeight', '4bd1352f-e9b1-4c72-b235-e9ecf5c0eb03', '{"action": "updateweight", "status": "completed"}', now()),
('ba598eaf-c510-4e8f-8ee8-0db1be28280b', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'GenerateMenu', 'GenerateMenu', '115ee720-3c3d-4211-b505-c1ec83144c91', '{"action": "generatemenu", "status": "completed"}', now()),
('b2de76de-d544-4232-ae4d-7252d0c88c0b', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'LogMeal', 'Meal', 'f0dc792c-81a5-40d8-94de-d9ec174b5028', '{"action": "logmeal", "status": "completed"}', now()),
('825e70fe-a4b5-48a6-a4c9-c56c1130a779', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'UpdateWeight', 'UpdateWeight', 'a48d6e62-b796-4636-b044-100029f4f116', '{"action": "updateweight", "status": "completed"}', now()),
('87996d51-dda2-438d-b5e3-449b4cf956a1', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'GenerateMenu', 'GenerateMenu', '556d60d9-62e0-4d64-a146-208462f64a53', '{"action": "generatemenu", "status": "completed"}', now()),
('eeea0976-9b5e-47f0-ad63-9101cf6a2024', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'LogMeal', 'Meal', '68ebeaf5-6098-4335-9c1c-1d05ffabf553', '{"action": "logmeal", "status": "completed"}', now()),
('b4de3d82-12bc-4141-9e09-3b0326c5f7f2', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'UpdateWeight', 'UpdateWeight', '4077a8c7-d0f8-4ae7-88ae-bfa634d49354', '{"action": "updateweight", "status": "completed"}', now()),
('784f2081-98f9-45eb-9d79-ce771e3ed9c3', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'GenerateMenu', 'GenerateMenu', 'e6e2002a-bd3b-4b41-9ba1-e9ea7e32f399', '{"action": "generatemenu", "status": "completed"}', now()),
('11b04250-d71b-4cc4-8dbf-58cb7b5f54e3', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'LogMeal', 'Meal', '37e47a60-ba94-4c2c-9f72-c159eb90cfe0', '{"action": "logmeal", "status": "completed"}', now()),
('f7629037-2ded-4780-b6f9-3e8354091e17', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'UpdateWeight', 'UpdateWeight', '7f0ae97a-893b-4176-8f47-7cbeb764d24a', '{"action": "updateweight", "status": "completed"}', now()),
('ff565c2d-2d71-4925-8c3d-8a77aaa9ae2f', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'GenerateMenu', 'GenerateMenu', '31f660d6-1c32-4278-9ba3-fb5eb0094793', '{"action": "generatemenu", "status": "completed"}', now()),
('26351991-b495-4e48-893b-2640a05ceb41', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'LogMeal', 'Meal', 'ccfe56d9-18ef-4665-9cdb-1e187eef273d', '{"action": "logmeal", "status": "completed"}', now()),
('d335ae8d-fb93-452d-bf91-6559f07431bd', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'UpdateWeight', 'UpdateWeight', '555968c9-4208-47d2-8f38-c7997ce35e35', '{"action": "updateweight", "status": "completed"}', now()),
('8a7ed5ef-f558-40e8-8972-186863eb1645', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'GenerateMenu', 'GenerateMenu', 'f2290cd6-b56c-480e-85dc-93a1379f1b33', '{"action": "generatemenu", "status": "completed"}', now()),
('7f3e8a93-654f-47be-97de-48d8913474f1', '885810e8-168f-4608-a72e-e23a20dfd258', 'LogMeal', 'Meal', '5562ea50-17bd-434f-b52a-fd013296b0a6', '{"action": "logmeal", "status": "completed"}', now()),
('5275b495-f698-4cf7-9b94-b08ddcd5179d', '885810e8-168f-4608-a72e-e23a20dfd258', 'UpdateWeight', 'UpdateWeight', 'b2c00e49-676b-44b4-a128-33e163ade53d', '{"action": "updateweight", "status": "completed"}', now()),
('ca0207dd-ded1-4f8b-aee2-df7d74c6573f', '885810e8-168f-4608-a72e-e23a20dfd258', 'GenerateMenu', 'GenerateMenu', '1e5fda65-73d9-46a7-8140-a628d71f1212', '{"action": "generatemenu", "status": "completed"}', now()),
('30250d36-e5ad-46ac-b474-422489fff6f5', '48069bd5-f29a-417d-bdeb-c00797968aca', 'LogMeal', 'Meal', 'd09cf3d0-b11e-40f0-84e0-706493516aa3', '{"action": "logmeal", "status": "completed"}', now()),
('3fcdc3d9-2cdc-4028-af45-a35ab44128a2', '48069bd5-f29a-417d-bdeb-c00797968aca', 'UpdateWeight', 'UpdateWeight', 'c2d7d052-f966-4d0b-a71b-fdd7ca921a92', '{"action": "updateweight", "status": "completed"}', now()),
('ae7922bf-ef14-432c-9363-05212438747e', '48069bd5-f29a-417d-bdeb-c00797968aca', 'GenerateMenu', 'GenerateMenu', '854a2207-9d3e-4f61-929a-56d55d51de42', '{"action": "generatemenu", "status": "completed"}', now()),
('cd8c2d94-4c89-4dd8-bcd8-d1069bc85867', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'LogMeal', 'Meal', '88be103a-9402-48c1-97a7-ecd937731519', '{"action": "logmeal", "status": "completed"}', now()),
('27d30de2-832e-4dc2-a6b1-85be5ba17fc2', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'UpdateWeight', 'UpdateWeight', '41345e37-452d-44e8-a644-3142ba46c4d1', '{"action": "updateweight", "status": "completed"}', now()),
('5d8f3a75-6cf8-41df-9508-52f956d385c3', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'GenerateMenu', 'GenerateMenu', '9949cf3f-cd57-4b0d-a314-c913cf48b412', '{"action": "generatemenu", "status": "completed"}', now()),
('fd09b0e5-9ba1-4e3f-acfe-368f26d9683b', '081b4669-b97f-4e75-b089-4c8de0151653', 'LogMeal', 'Meal', 'b9b5bfb7-05e9-4887-bc62-f875c1a98c04', '{"action": "logmeal", "status": "completed"}', now()),
('21669d47-6356-42db-b669-447bf695b647', '081b4669-b97f-4e75-b089-4c8de0151653', 'UpdateWeight', 'UpdateWeight', '6a45ecdb-3234-4958-b108-425e8a7f66f0', '{"action": "updateweight", "status": "completed"}', now()),
('ec5dd194-3e23-491b-a3d6-5b824dfb40de', '081b4669-b97f-4e75-b089-4c8de0151653', 'GenerateMenu', 'GenerateMenu', '73d0ff28-fbff-409d-ac15-1817c5828565', '{"action": "generatemenu", "status": "completed"}', now()),
('c7713320-7e17-4717-869f-3a609f1050b1', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 'LogMeal', 'Meal', 'c44786e4-3c24-444d-a17e-7bbf6c299560', '{"action": "logmeal", "status": "completed"}', now()),
('9c1647b8-1617-4b34-a9cd-a000323a2e54', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 'UpdateWeight', 'UpdateWeight', 'ca0f68f2-0808-494e-8add-13a375564e9b', '{"action": "updateweight", "status": "completed"}', now()),
('224049c4-cd82-4f6c-9e0d-bf23fcb93c7c', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 'GenerateMenu', 'GenerateMenu', '125945b3-66c5-4cae-9cce-4aafdc864a19', '{"action": "generatemenu", "status": "completed"}', now()),
('f58fdcba-8585-489b-aff4-64756e757db0', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 'LogMeal', 'Meal', 'c978de22-72e2-4beb-9259-e21353595b07', '{"action": "logmeal", "status": "completed"}', now()),
('51f3fc15-a4a2-46af-bd9c-76d4fb77f24a', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 'UpdateWeight', 'UpdateWeight', '62716105-fda9-4685-8eb1-38445720c932', '{"action": "updateweight", "status": "completed"}', now()),
('b68aab7e-9b4d-4c0d-9821-5d6d1646eea5', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 'GenerateMenu', 'GenerateMenu', '03178b72-9d27-44bc-93c9-bd1dbdfae1d3', '{"action": "generatemenu", "status": "completed"}', now()),
('db1ab812-e0f2-4648-9443-bdf5bed47ae7', '453681f7-f489-47ed-842c-bc3ffd220423', 'LogMeal', 'Meal', '354d0ab8-44bc-4584-9d8b-4af03b84f7e3', '{"action": "logmeal", "status": "completed"}', now()),
('87ee463a-3c23-4f29-9046-2b373f9c88db', '453681f7-f489-47ed-842c-bc3ffd220423', 'UpdateWeight', 'UpdateWeight', 'de5025a8-647a-40d6-b7b4-194e4d284097', '{"action": "updateweight", "status": "completed"}', now()),
('f6c913a5-af14-4413-ab23-683056b7399d', '453681f7-f489-47ed-842c-bc3ffd220423', 'GenerateMenu', 'GenerateMenu', 'd8d449a6-9469-456a-afe8-0c517469deac', '{"action": "generatemenu", "status": "completed"}', now()),
('d47baecd-4666-4a41-a30d-d6372596d141', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 'LogMeal', 'Meal', 'b823a687-3245-4098-8f6e-f0d248c62bb8', '{"action": "logmeal", "status": "completed"}', now()),
('b8410c77-d6b5-4b83-add1-1611d67c8b8d', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 'UpdateWeight', 'UpdateWeight', '5cf3ed87-8ab6-41a1-a3bd-f3381544e03b', '{"action": "updateweight", "status": "completed"}', now()),
('c8aada2f-314c-4dc7-901e-00a4b562e58f', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 'GenerateMenu', 'GenerateMenu', 'a1ff4b70-b028-425c-8ca3-aba4b5ace4f5', '{"action": "generatemenu", "status": "completed"}', now()),
('e30b77fb-59cb-4623-a93d-593694912793', '5dc50160-db9e-447a-ba33-9026d8800ab5', 'LogMeal', 'Meal', '25c7ff77-ebe9-4983-91ad-6cd4fd463226', '{"action": "logmeal", "status": "completed"}', now()),
('4d7e653e-9701-4154-a796-5bec66ccfa59', '5dc50160-db9e-447a-ba33-9026d8800ab5', 'UpdateWeight', 'UpdateWeight', 'e9a478cd-f789-40c8-801c-0772590fa52d', '{"action": "updateweight", "status": "completed"}', now()),
('37fc8a36-429d-4de2-8ad2-820039150b06', '5dc50160-db9e-447a-ba33-9026d8800ab5', 'GenerateMenu', 'GenerateMenu', 'dd53de3d-a5d1-496b-973f-668cb3da2c2c', '{"action": "generatemenu", "status": "completed"}', now()),
('6a7f2eb2-e86e-492c-8d57-b2b5c4e2bf9e', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 'LogMeal', 'Meal', '4f7dd928-b2ff-4dc9-9d4a-f295db710c19', '{"action": "logmeal", "status": "completed"}', now()),
('abc7ecf1-420d-4f5f-acb9-40cb7f58756b', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 'UpdateWeight', 'UpdateWeight', 'c1a47938-29c2-4f26-8caa-edff28002a92', '{"action": "updateweight", "status": "completed"}', now()),
('7c095881-3ca4-4b09-8e26-cecf1bdd6281', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 'GenerateMenu', 'GenerateMenu', '1c870950-f843-45ee-be3a-ab94d5e677f3', '{"action": "generatemenu", "status": "completed"}', now())
ON CONFLICT DO NOTHING;

COMMIT;