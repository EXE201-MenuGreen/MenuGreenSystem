-- =============================================================================
-- MenuGreen Seed Data - Table: nutrition_snapshots
-- Sequence Number: 28
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS nutrition_snapshots CASCADE;

CREATE TABLE nutrition_snapshots (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "SnapshotDate" date NULL,
    "TotalCalories" numeric NULL,
    "TotalProteinG" numeric NULL,
    "TotalCarbsG" numeric NULL,
    "TotalFatG" numeric NULL,
    "GoalCompletionPercent" numeric NULL,
    CONSTRAINT "PK_nutrition_snapshots" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_nutrition_snapshots_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO nutrition_snapshots ("Id", "UserId", "SnapshotDate", "TotalCalories", "TotalProteinG", "TotalCarbsG", "TotalFatG", "GoalCompletionPercent")
VALUES
('6389e5be-6ec0-4445-a5d0-a12d3e5d42aa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', CURRENT_DATE - 0, 2123, 133, 254, 53, 100.52),
('9cdf2333-6c6d-4265-a861-08038bdb962c', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', CURRENT_DATE - 1, 1743, 119, 215, 51, 89.77),
('1ebc0bd2-ad27-496b-85e8-58aa9d236bb8', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', CURRENT_DATE - 2, 2154, 150, 279, 64, 86.26),
('720bba68-900f-409e-b56a-e544b3993301', 'cccccccc-cccc-cccc-cccc-cccccccccccc', CURRENT_DATE - 0, 2011, 138, 268, 50, 97.64),
('8d8d01b9-ef37-4784-9ddd-4969030043ae', 'cccccccc-cccc-cccc-cccc-cccccccccccc', CURRENT_DATE - 1, 2088, 115, 291, 54, 90.83),
('2a27c8e8-5221-485a-82d7-78497ee487db', 'cccccccc-cccc-cccc-cccc-cccccccccccc', CURRENT_DATE - 2, 1501, 139, 245, 57, 96.41),
('6ec866c4-236c-4086-876d-392a3af6f586', 'dddddddd-dddd-dddd-dddd-dddddddddddd', CURRENT_DATE - 0, 1691, 142, 285, 52, 95.47),
('1b1c9fd4-8c5e-4896-9b47-652f8c58c208', 'dddddddd-dddd-dddd-dddd-dddddddddddd', CURRENT_DATE - 1, 1869, 104, 267, 67, 95.15),
('fae149ee-0e1b-4591-b1a5-f091aa316100', 'dddddddd-dddd-dddd-dddd-dddddddddddd', CURRENT_DATE - 2, 2019, 135, 202, 62, 102.47),
('41af12d6-330a-4ced-ad3c-15d4abda4f95', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', CURRENT_DATE - 0, 1544, 140, 249, 61, 90.07),
('cd3c05bd-7d20-4822-bd45-b15f06e8edf0', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', CURRENT_DATE - 1, 1516, 122, 300, 52, 91.90),
('e90a4e3a-63ed-4fe9-b9dc-5779277fe745', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', CURRENT_DATE - 2, 2172, 140, 213, 74, 96.64),
('bcb8b2df-475a-4863-8b90-eb5e9446721e', 'ffffffff-ffff-ffff-ffff-ffffffffffff', CURRENT_DATE - 0, 1840, 108, 205, 61, 95.92),
('d290a83e-f5d0-4169-8720-03074eaee004', 'ffffffff-ffff-ffff-ffff-ffffffffffff', CURRENT_DATE - 1, 2158, 111, 299, 71, 94.29),
('11f901e4-3f12-4dcf-acd1-7de1bb04e6fb', 'ffffffff-ffff-ffff-ffff-ffffffffffff', CURRENT_DATE - 2, 1990, 140, 223, 75, 87.70),
('74cb58f0-6512-41f4-8af3-4feb0db7485e', '885810e8-168f-4608-a72e-e23a20dfd258', CURRENT_DATE - 0, 1968, 102, 237, 56, 85.88),
('47ab7579-fe5d-4a6b-a9f3-1e824f19b049', '885810e8-168f-4608-a72e-e23a20dfd258', CURRENT_DATE - 1, 1704, 102, 240, 79, 91.20),
('dabbc0c9-2e6d-4819-ba5a-11d717b305bb', '885810e8-168f-4608-a72e-e23a20dfd258', CURRENT_DATE - 2, 1907, 134, 260, 58, 85.73),
('0e3b8f4d-1db6-4bfd-adf4-654143480c4d', '48069bd5-f29a-417d-bdeb-c00797968aca', CURRENT_DATE - 0, 2162, 112, 236, 61, 102.24),
('dfc87f96-b2f5-435c-b3df-f92ebf724d21', '48069bd5-f29a-417d-bdeb-c00797968aca', CURRENT_DATE - 1, 1548, 141, 242, 58, 87.49),
('4d445772-22a1-4e94-8de4-00bcad0de704', '48069bd5-f29a-417d-bdeb-c00797968aca', CURRENT_DATE - 2, 1876, 127, 251, 73, 93.79),
('e29cbeff-76b3-45b5-b762-570cf71155c3', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', CURRENT_DATE - 0, 1895, 121, 223, 65, 98.84),
('48735f0f-5e56-4a50-81fe-a93e9cf44a5d', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', CURRENT_DATE - 1, 1876, 133, 234, 75, 86.65),
('8b64cc37-428a-493f-8a6a-b6090d831ac5', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', CURRENT_DATE - 2, 1934, 105, 255, 69, 104.90),
('7299293e-1228-4a96-8af6-e6c400337e4f', '081b4669-b97f-4e75-b089-4c8de0151653', CURRENT_DATE - 0, 1684, 134, 237, 60, 87.05),
('e5a229d9-3e0c-4986-a94d-782e50595576', '081b4669-b97f-4e75-b089-4c8de0151653', CURRENT_DATE - 1, 1835, 142, 237, 59, 93.92),
('d160a11a-d415-4894-a0ea-b3b761e40f57', '081b4669-b97f-4e75-b089-4c8de0151653', CURRENT_DATE - 2, 1936, 110, 288, 64, 92.03),
('4471bf9a-3c9f-430f-82b3-77ed89cf2179', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', CURRENT_DATE - 0, 1543, 146, 245, 69, 104.96),
('6e0c393b-3a04-4f97-bc26-8605a28e32c4', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', CURRENT_DATE - 1, 1781, 140, 207, 52, 98.42),
('422ea35b-e930-472a-a186-b26f37e7b708', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', CURRENT_DATE - 2, 1915, 123, 265, 75, 100.00),
('914d284b-eadf-4eb0-a87b-a5aeeffa2402', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', CURRENT_DATE - 0, 1663, 101, 218, 77, 97.15),
('1dcecdcb-4ff6-4305-8d07-0fbb812d2f8e', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', CURRENT_DATE - 1, 1948, 102, 216, 52, 89.72),
('0171048c-c5a7-4780-9500-50e5c1e8b3ad', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', CURRENT_DATE - 2, 2160, 123, 246, 62, 103.99),
('536d3d21-5fae-49f1-b162-8c57cd5d1950', '453681f7-f489-47ed-842c-bc3ffd220423', CURRENT_DATE - 0, 1533, 138, 219, 71, 94.00),
('11336e27-0eaa-4d35-a4a1-e4fd311db712', '453681f7-f489-47ed-842c-bc3ffd220423', CURRENT_DATE - 1, 1879, 123, 256, 74, 86.54),
('71939293-f910-4399-905d-0b71c5db929c', '453681f7-f489-47ed-842c-bc3ffd220423', CURRENT_DATE - 2, 1640, 133, 246, 62, 91.29),
('50160f0e-1630-4e0b-84a2-918d88ebdc49', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', CURRENT_DATE - 0, 1785, 115, 214, 50, 99.71),
('0c726677-9854-4454-9c01-ce675ce48a44', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', CURRENT_DATE - 1, 2011, 133, 249, 79, 96.23),
('0fd2ff57-26ec-45c4-b8d9-eff9c3a12759', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', CURRENT_DATE - 2, 1768, 149, 233, 72, 93.93),
('6b5ee94d-2091-4b97-b5b4-992ebdc99c6e', '5dc50160-db9e-447a-ba33-9026d8800ab5', CURRENT_DATE - 0, 2126, 118, 288, 79, 104.97),
('b4b7167b-49ca-4621-a55c-8f5266eaecb3', '5dc50160-db9e-447a-ba33-9026d8800ab5', CURRENT_DATE - 1, 1704, 107, 217, 77, 86.48),
('0bbf0dda-c594-48ed-a230-318582a8546a', '5dc50160-db9e-447a-ba33-9026d8800ab5', CURRENT_DATE - 2, 1676, 145, 256, 52, 101.21),
('0e1170a7-7f80-45cf-932a-3e202d4a44b7', '212ea8ea-749e-44a1-92d2-636bd617cbc8', CURRENT_DATE - 0, 1827, 142, 244, 72, 86.30),
('5a740f18-7472-4598-875e-88b8f3927bee', '212ea8ea-749e-44a1-92d2-636bd617cbc8', CURRENT_DATE - 1, 2055, 118, 238, 77, 88.15),
('f9088778-2705-4cf8-8e6d-71d4d3382a44', '212ea8ea-749e-44a1-92d2-636bd617cbc8', CURRENT_DATE - 2, 2153, 111, 246, 66, 89.48)
ON CONFLICT DO NOTHING;

COMMIT;