-- =============================================================================
-- MenuGreen Seed Data - Table: subscription_transactions
-- Sequence Number: 11
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS subscription_transactions CASCADE;

CREATE TABLE subscription_transactions (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "UserSubscriptionId" uuid NOT NULL,
    "TransactionType" character varying(50) NOT NULL,
    "Amount" integer NOT NULL,
    "Status" character varying(50) NOT NULL,
    "Note" text NULL,
    "TransactionDate" timestamp with time zone NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_subscription_transactions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_sub_txn_user_sub" FOREIGN KEY ("UserSubscriptionId") REFERENCES user_subscriptions ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_subscription_transactions_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO subscription_transactions ("Id", "UserId", "UserSubscriptionId", "TransactionType", "Amount", "Status", "Note", "TransactionDate", "CreatedAt")
VALUES
('23291296-f6d4-431f-badf-71bdbff7a3bc', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '97f4a742-cc44-4ab0-b2f4-bc260c245cdf', 'Subscribe', 790000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('530d090a-5287-43f9-8c28-f41fcd2533d0', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '5091b2d7-a9e8-41ca-ad18-407bcee846f5', 'Subscribe', 99000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('743dce5d-4a76-4b8c-be53-f6e55e9695b8', 'dddddddd-dddd-dddd-dddd-dddddddddddd', '5e31bbfb-1c4c-4dde-9682-41c8b22a9418', 'Subscribe', 790000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('a8bc09b6-e68b-4e9c-8edc-6f180b309cfe', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '00e3373b-a66f-4ae4-acf1-873d4f21e735', 'Subscribe', 99000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('68b6e8a8-f11b-476f-ab1b-a690dc51d60b', 'ffffffff-ffff-ffff-ffff-ffffffffffff', '5a589d0c-0879-4211-bcde-b80d8f872a2c', 'Subscribe', 790000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('0e06b7fb-fe45-4a7b-8dec-22d814b89813', '885810e8-168f-4608-a72e-e23a20dfd258', '77332cff-478c-4926-9dc4-6fd86c688d88', 'Subscribe', 99000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('2a38dfc4-a650-4f06-9b5a-80b64a069b16', '48069bd5-f29a-417d-bdeb-c00797968aca', '4cb9db51-734f-4710-8500-9cd449938d3c', 'Subscribe', 790000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('685695b8-f04b-4d98-a58b-2eff5e1c115e', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'ca5ba96d-0c13-457f-9833-439817647424', 'Subscribe', 99000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('736e7b4f-642d-4b7a-a398-482d02f777c8', '081b4669-b97f-4e75-b089-4c8de0151653', '7158db3e-9416-463a-9158-c5cbdf0aa202', 'Subscribe', 790000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('408cf856-c323-46ec-9577-2349181d9b59', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', '137a2257-8c0b-4b56-b4fa-be8da55e7c14', 'Subscribe', 99000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('445a54b7-a6df-4f5d-bb47-4b222c8cab9f', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', '4833465b-1140-4a40-b7cd-114acaabae31', 'Subscribe', 790000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('814830ad-6df6-4b15-a5aa-a196cff97538', '453681f7-f489-47ed-842c-bc3ffd220423', '41837cb8-7232-444c-be01-417e376de8c0', 'Subscribe', 99000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('870646a4-f4e7-47ea-a524-1c16c74403c6', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', '26a8241f-a665-45c8-a083-aba9bfa8c008', 'Subscribe', 790000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('14a337a9-d36b-4e6e-a468-7a4bd43a872a', '5dc50160-db9e-447a-ba33-9026d8800ab5', '6a54cb24-29ae-49ce-b950-628c76f85fb3', 'Subscribe', 99000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days'),
('48120f28-e30a-4c75-b0e4-a3b075e7b0dc', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 'acbfd092-bc85-4b14-b509-d2da7f969903', 'Subscribe', 790000, 'Success', 'Đăng ký dịch vụ MenuGreen Pro', now() - interval '20 days', now() - interval '20 days')
ON CONFLICT DO NOTHING;

COMMIT;