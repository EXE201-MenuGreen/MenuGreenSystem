-- =============================================================================
-- MenuGreen Seed Data - Table: weight_logs
-- Sequence Number: 27
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS weight_logs CASCADE;

CREATE TABLE weight_logs (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "WeightKg" numeric NULL,
    "BodyFatPercent" numeric NULL,
    "RecordedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_weight_logs" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_weight_logs_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO weight_logs ("Id", "UserId", "WeightKg", "BodyFatPercent", "RecordedAt")
VALUES
('ac69c5dd-31e2-4d0c-a76f-fc374449e02e', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 82.06, 21.91, now() - interval '28 days'),
('b0244994-4276-4dac-914b-772d08196487', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 81.58, 21.90, now() - interval '21 days'),
('c2c35afc-b5c4-4926-bbf8-2d8610263b04', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 81.01, 21.62, now() - interval '14 days'),
('f2d547b3-189f-4f4d-8e3e-f2d8b0f130f2', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 80.45, 21.48, now() - interval '7 days'),
('253b3e45-ea59-4865-9d54-b230b6367bf1', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 73.96, 21.97, now() - interval '28 days'),
('6dfa31cf-267d-43ba-86a3-bf018d707fe6', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 73.54, 21.86, now() - interval '21 days'),
('96428698-01ab-4436-a230-cf48edd990fe', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 73.06, 21.51, now() - interval '14 days'),
('d49c2814-8e27-4be1-827a-7b97730fb456', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 72.34, 21.44, now() - interval '7 days'),
('2e85aca3-8e93-456b-ad03-6960c43d0fc9', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 67.90, 22.07, now() - interval '28 days'),
('985383e8-7e6e-4cb2-9b7b-7997cd48def8', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 67.69, 21.82, now() - interval '21 days'),
('3c3fac95-3022-4416-88ba-d7160de2d1c5', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 66.86, 21.52, now() - interval '14 days'),
('fff332ea-645a-4d1a-8c63-ea53112a8d5d', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 66.57, 21.48, now() - interval '7 days'),
('8ec32686-c349-4b8a-b389-1a0eab5bb076', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 69.19, 22.04, now() - interval '28 days'),
('eb987b73-df49-4259-b53e-dfaa3788e6f3', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 68.46, 21.82, now() - interval '21 days'),
('a6fe79e6-eebc-4f41-b7ca-efec24de96b4', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 68.18, 21.56, now() - interval '14 days'),
('3b76a290-3288-4ab6-95d5-ecd65f44d39b', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 67.45, 21.46, now() - interval '7 days'),
('4dbd4692-53f4-471a-8a73-5d483aca23ae', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 58.07, 22.07, now() - interval '28 days'),
('3d81f1db-94f3-4843-acbb-08e34486a291', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 57.60, 21.84, now() - interval '21 days'),
('4253d013-ba43-4442-96e8-2425ffb3ddde', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 57.01, 21.63, now() - interval '14 days'),
('10508f99-04f3-42bb-aedc-a3f8126ce156', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 56.47, 21.37, now() - interval '7 days'),
('0f832e5d-ded7-4803-851a-1cd74d1a6a91', '885810e8-168f-4608-a72e-e23a20dfd258', 72.92, 22.09, now() - interval '28 days'),
('07048139-11dd-446e-a2d3-c517461c692b', '885810e8-168f-4608-a72e-e23a20dfd258', 72.44, 21.85, now() - interval '21 days'),
('697f8ee1-7fb3-4dff-b20b-ca4707f4680c', '885810e8-168f-4608-a72e-e23a20dfd258', 71.88, 21.70, now() - interval '14 days'),
('de1fb61d-c19d-4a6a-9eed-5af631a560dd', '885810e8-168f-4608-a72e-e23a20dfd258', 71.36, 21.36, now() - interval '7 days'),
('e984f502-2780-407b-8d50-abf3efbc6b80', '48069bd5-f29a-417d-bdeb-c00797968aca', 56.00, 22.01, now() - interval '28 days'),
('fb0182ae-724a-4b8e-a1ea-86e334a650fa', '48069bd5-f29a-417d-bdeb-c00797968aca', 55.60, 21.81, now() - interval '21 days'),
('9b08bc9a-5143-44b4-93b9-64059ed904f4', '48069bd5-f29a-417d-bdeb-c00797968aca', 55.06, 21.68, now() - interval '14 days'),
('55d1d193-385b-4761-9e63-466f7bf9922e', '48069bd5-f29a-417d-bdeb-c00797968aca', 54.55, 21.42, now() - interval '7 days'),
('03c9397e-a0cd-441e-a55e-edc40fa79fa0', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 58.86, 22.07, now() - interval '28 days'),
('bfac2181-c829-47d6-9615-4c0739469bbd', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 58.61, 21.86, now() - interval '21 days'),
('58537744-cbb2-4da0-9e4f-adfbaaf23227', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 57.87, 21.59, now() - interval '14 days'),
('244b3d63-78ec-4506-90ff-5c0301a87d04', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 57.46, 21.44, now() - interval '7 days'),
('2b1e842b-e9bd-43f8-87bf-32f7a9c40386', '081b4669-b97f-4e75-b089-4c8de0151653', 65.19, 22.02, now() - interval '28 days'),
('826cf924-6ff3-40c1-9ca8-5c6866983a2d', '081b4669-b97f-4e75-b089-4c8de0151653', 64.60, 21.86, now() - interval '21 days'),
('9debbe2b-4c6a-415a-b267-139f42974f3d', '081b4669-b97f-4e75-b089-4c8de0151653', 63.89, 21.55, now() - interval '14 days'),
('b918a963-e3c1-4f53-bdff-4139de78c6ba', '081b4669-b97f-4e75-b089-4c8de0151653', 63.69, 21.46, now() - interval '7 days'),
('836e9352-23ee-463b-9448-a7e441fdb58b', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 61.95, 22.09, now() - interval '28 days'),
('7bd546a6-de9c-46f4-956a-5caed9fffad8', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 61.69, 21.79, now() - interval '21 days'),
('43a4cd13-2e9c-4a13-a1f0-89490cb25ecd', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 60.91, 21.58, now() - interval '14 days'),
('c2e75774-254c-4ade-88ee-3acb3a520a97', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 60.51, 21.49, now() - interval '7 days'),
('424d0dbc-930f-45b8-919f-b606ca47e582', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 62.12, 21.93, now() - interval '28 days'),
('8fa97ace-c2fb-4782-9713-9c00e2913958', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 61.40, 21.83, now() - interval '21 days'),
('be695f45-0a31-40c4-b8cc-80e682dcbce6', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 61.15, 21.61, now() - interval '14 days'),
('890578da-54b0-44ce-bb45-e67abe04f09b', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 60.34, 21.47, now() - interval '7 days'),
('d7c4af0d-2845-43c6-b565-cd8f6af2bca3', '453681f7-f489-47ed-842c-bc3ffd220423', 56.91, 22.05, now() - interval '28 days'),
('444915e8-9b7a-4ebd-bcfa-70e8cb01ef0c', '453681f7-f489-47ed-842c-bc3ffd220423', 56.41, 21.88, now() - interval '21 days'),
('0097a3fa-beec-4bd1-93a8-a9cb6a3f1184', '453681f7-f489-47ed-842c-bc3ffd220423', 55.86, 21.59, now() - interval '14 days'),
('41e7813b-2a51-44f5-823d-b089b2e9672a', '453681f7-f489-47ed-842c-bc3ffd220423', 55.68, 21.34, now() - interval '7 days'),
('e645657e-44bb-4fd4-95d2-7fd58d273af1', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 78.15, 22.09, now() - interval '28 days'),
('0016be3c-4f84-4555-a3af-40be9dd625a2', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 77.47, 21.78, now() - interval '21 days'),
('6b281699-8a40-420d-a4fe-cdcad92ab499', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 76.95, 21.58, now() - interval '14 days'),
('b5b098ff-1bb8-422d-ab01-f3b1b40ea1dd', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 76.33, 21.34, now() - interval '7 days'),
('41b9f7f6-cbd0-440d-84df-cbddcbd44469', '5dc50160-db9e-447a-ba33-9026d8800ab5', 70.17, 22.07, now() - interval '28 days'),
('7f2c73b0-f4dc-42fa-820b-e591a1011fa8', '5dc50160-db9e-447a-ba33-9026d8800ab5', 69.56, 21.86, now() - interval '21 days'),
('e1dadbb6-a2b1-4b69-95a6-965b898d3195', '5dc50160-db9e-447a-ba33-9026d8800ab5', 68.86, 21.56, now() - interval '14 days'),
('a599477e-73fe-4ff1-9aa5-317163e82c0b', '5dc50160-db9e-447a-ba33-9026d8800ab5', 68.63, 21.44, now() - interval '7 days'),
('5a62ec45-94b4-438f-8b33-ff0385a5e738', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 58.10, 21.99, now() - interval '28 days'),
('cb4aae16-eaa1-40fc-8402-b538d805b1d2', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 57.55, 21.88, now() - interval '21 days'),
('beef822b-e498-422d-a042-5e29c62431cb', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 56.81, 21.54, now() - interval '14 days'),
('c5f7d51d-3fdf-45f5-bdab-c5bf16f52e2e', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 56.36, 21.49, now() - interval '7 days')
ON CONFLICT DO NOTHING;

COMMIT;