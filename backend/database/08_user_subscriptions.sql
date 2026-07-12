-- =============================================================================
-- MenuGreen Seed Data - Table: user_subscriptions
-- Sequence Number: 08
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS user_subscriptions CASCADE;

CREATE TABLE user_subscriptions (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "SubscriptionPlanId" uuid NOT NULL,
    "Status" character varying(50) NOT NULL,
    "StartDate" timestamp with time zone NOT NULL,
    "EndDate" timestamp with time zone NOT NULL,
    "CancelledAt" timestamp with time zone NULL,
    "RenewedAt" timestamp with time zone NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_user_subscriptions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_user_subscriptions_subscription_plans_SubscriptionPlanId" FOREIGN KEY ("SubscriptionPlanId") REFERENCES subscription_plans ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_user_subscriptions_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO user_subscriptions ("Id", "UserId", "SubscriptionPlanId", "Status", "StartDate", "EndDate", "CancelledAt", "RenewedAt", "CreatedAt", "UpdatedAt")
VALUES
('97f4a742-cc44-4ab0-b2f4-bc260c245cdf', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '10000000-0000-0000-0000-000000000003', 'Expired', now() - interval '375 days', now() - interval '10 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('5091b2d7-a9e8-41ca-ad18-407bcee846f5', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '10000000-0000-0000-0000-000000000002', 'Expired', now() - interval '40 days', now() - interval '10 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('5e31bbfb-1c4c-4dde-9682-41c8b22a9418', 'dddddddd-dddd-dddd-dddd-dddddddddddd', '10000000-0000-0000-0000-000000000003', 'Expired', now() - interval '375 days', now() - interval '10 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('00e3373b-a66f-4ae4-acf1-873d4f21e735', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '10000000-0000-0000-0000-000000000002', 'Active', now() - interval '15 days', now() + interval '15 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('5a589d0c-0879-4211-bcde-b80d8f872a2c', 'ffffffff-ffff-ffff-ffff-ffffffffffff', '10000000-0000-0000-0000-000000000003', 'Active', now() - interval '15 days', now() + interval '350 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('77332cff-478c-4926-9dc4-6fd86c688d88', '885810e8-168f-4608-a72e-e23a20dfd258', '10000000-0000-0000-0000-000000000002', 'Expired', now() - interval '40 days', now() - interval '10 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('4cb9db51-734f-4710-8500-9cd449938d3c', '48069bd5-f29a-417d-bdeb-c00797968aca', '10000000-0000-0000-0000-000000000003', 'Expired', now() - interval '375 days', now() - interval '10 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('ca5ba96d-0c13-457f-9833-439817647424', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', '10000000-0000-0000-0000-000000000002', 'Expired', now() - interval '40 days', now() - interval '10 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('7158db3e-9416-463a-9158-c5cbdf0aa202', '081b4669-b97f-4e75-b089-4c8de0151653', '10000000-0000-0000-0000-000000000003', 'Expired', now() - interval '375 days', now() - interval '10 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('137a2257-8c0b-4b56-b4fa-be8da55e7c14', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', '10000000-0000-0000-0000-000000000002', 'Active', now() - interval '15 days', now() + interval '15 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('4833465b-1140-4a40-b7cd-114acaabae31', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', '10000000-0000-0000-0000-000000000003', 'Expired', now() - interval '375 days', now() - interval '10 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('41837cb8-7232-444c-be01-417e376de8c0', '453681f7-f489-47ed-842c-bc3ffd220423', '10000000-0000-0000-0000-000000000002', 'Expired', now() - interval '40 days', now() - interval '10 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('26a8241f-a665-45c8-a083-aba9bfa8c008', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', '10000000-0000-0000-0000-000000000003', 'Expired', now() - interval '375 days', now() - interval '10 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('6a54cb24-29ae-49ce-b950-628c76f85fb3', '5dc50160-db9e-447a-ba33-9026d8800ab5', '10000000-0000-0000-0000-000000000002', 'Expired', now() - interval '40 days', now() - interval '10 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days'),
('acbfd092-bc85-4b14-b509-d2da7f969903', '212ea8ea-749e-44a1-92d2-636bd617cbc8', '10000000-0000-0000-0000-000000000003', 'Expired', now() - interval '375 days', now() - interval '10 days', NULL, NULL, now() - interval '20 days', now() - interval '20 days')
ON CONFLICT DO NOTHING;

COMMIT;