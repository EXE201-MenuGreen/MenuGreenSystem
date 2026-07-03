-- =============================================================================
-- MenuGreen Seed Data - Table: payments
-- Sequence Number: 09
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS payments CASCADE;

CREATE TABLE payments (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "UserSubscriptionId" uuid NULL,
    "UserPremiumProgramId" uuid NULL,
    "AmountVnd" integer NOT NULL,
    "Status" character varying(32) NOT NULL,
    "PaymentMethod" character varying(32) NOT NULL,
    "Provider" character varying(32) NOT NULL,
    "ProviderOrderCode" character varying(128) NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NULL,
    "ExpiredAt" timestamp with time zone NULL,
    "PaidAt" timestamp with time zone NULL,
    CONSTRAINT "PK_payments" PRIMARY KEY ("Id"),
    CONSTRAINT "CK_payments_status" CHECK ("Status" IN ('PENDING','PAID','FAILED','EXPIRED','REFUNDED')),
    CONSTRAINT "FK_payments_user_subscriptions_UserSubscriptionId" FOREIGN KEY ("UserSubscriptionId") REFERENCES user_subscriptions ("Id") ON DELETE SET NULL
);

CREATE INDEX "IX_payments_UserPremiumProgramId" ON payments ("UserPremiumProgramId");

INSERT INTO payments ("Id", "UserId", "UserSubscriptionId", "AmountVnd", "Status", "PaymentMethod", "Provider", "ProviderOrderCode", "CreatedAt", "UpdatedAt", "ExpiredAt", "PaidAt")
VALUES
('76378876-43df-47db-88d1-1bee4c82077d', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '97f4a742-cc44-4ab0-b2f4-bc260c245cdf', 790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_76378876', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('17605d97-f2f4-422b-90cc-4999a5f1fec0', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '5091b2d7-a9e8-41ca-ad18-407bcee846f5', 99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_17605d97', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('0e6db154-5c4f-435a-95e3-937ef4092015', 'dddddddd-dddd-dddd-dddd-dddddddddddd', '5e31bbfb-1c4c-4dde-9682-41c8b22a9418', 790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_0e6db154', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('856a1f59-b430-4386-b3c9-ba5bd1ddbdd3', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '00e3373b-a66f-4ae4-acf1-873d4f21e735', 99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_856a1f59', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('f30d1b92-6926-433f-b4c8-d2cbfd559dc6', 'ffffffff-ffff-ffff-ffff-ffffffffffff', '5a589d0c-0879-4211-bcde-b80d8f872a2c', 790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_f30d1b92', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('ca3479ca-26f1-44db-a245-80371e7e2ce1', '885810e8-168f-4608-a72e-e23a20dfd258', '77332cff-478c-4926-9dc4-6fd86c688d88', 99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_ca3479ca', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('b771fc44-c0d1-4175-af76-49e5ff5d64fb', '48069bd5-f29a-417d-bdeb-c00797968aca', '4cb9db51-734f-4710-8500-9cd449938d3c', 790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_b771fc44', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('e2ae9d11-6e00-4f88-9b37-a5f5d3c0d5df', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'ca5ba96d-0c13-457f-9833-439817647424', 99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_e2ae9d11', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('9236bd02-6f32-44b1-80a6-df311178ea2b', '081b4669-b97f-4e75-b089-4c8de0151653', '7158db3e-9416-463a-9158-c5cbdf0aa202', 790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_9236bd02', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('cca940d2-f4ad-432b-b6b2-99c504fb71f5', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', '137a2257-8c0b-4b56-b4fa-be8da55e7c14', 99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_cca940d2', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('ee658c09-f558-4414-a659-c113b55f4125', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', '4833465b-1140-4a40-b7cd-114acaabae31', 790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_ee658c09', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('aeb230f1-5560-4e4d-b462-4c704843cdb7', '453681f7-f489-47ed-842c-bc3ffd220423', '41837cb8-7232-444c-be01-417e376de8c0', 99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_aeb230f1', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('5cf0a99a-134f-45a1-9fae-55dee3227308', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', '26a8241f-a665-45c8-a083-aba9bfa8c008', 790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_5cf0a99a', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('482b0243-65d5-4eae-adf6-5b5b04452fd7', '5dc50160-db9e-447a-ba33-9026d8800ab5', '6a54cb24-29ae-49ce-b950-628c76f85fb3', 99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_482b0243', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('a8bccf2c-d4cb-4a4b-b6d2-7713d38ca525', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 'acbfd092-bc85-4b14-b509-d2da7f969903', 790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_a8bccf2c', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days')
ON CONFLICT DO NOTHING;

COMMIT;