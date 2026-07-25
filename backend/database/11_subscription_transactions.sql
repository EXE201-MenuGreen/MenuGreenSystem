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
('a8bc09b6-e68b-4e9c-8edc-6f180b309cfe', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '00e3373b-a66f-4ae4-acf1-873d4f21e735', 'Subscribe', 99000, 'Success', 'Đăng ký Gói Gym/PT', now() - interval '20 days', now() - interval '20 days'),
('68b6e8a8-f11b-476f-ab1b-a690dc51d60b', 'ffffffff-ffff-ffff-ffff-ffffffffffff', '5a589d0c-0879-4211-bcde-b80d8f872a2c', 'Subscribe', 790000, 'Success', 'Đăng ký Gói Casual', now() - interval '20 days', now() - interval '20 days'),
('408cf856-c323-46ec-9577-2349181d9b59', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', '137a2257-8c0b-4b56-b4fa-be8da55e7c14', 'Subscribe', 99000, 'Success', 'Đăng ký gói Office', now() - interval '20 days', now() - interval '20 days')
ON CONFLICT DO NOTHING;

COMMIT;
