-- =============================================================================
-- MenuGreen Seed Data - Table: user_allergies
-- Sequence Number: 21
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS user_allergies CASCADE;

CREATE TABLE user_allergies (
    "UserId" uuid NOT NULL,
    "AllergyId" uuid NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_user_allergies" PRIMARY KEY ("UserId", "AllergyId"),
    CONSTRAINT "FK_user_allergies_allergies_AllergyId" FOREIGN KEY ("AllergyId") REFERENCES allergies ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_user_allergies_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO user_allergies ("UserId", "AllergyId", "CreatedAt")
VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'f738b00b-67f6-4ba9-9edf-23d4107d09d3', now()),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '704d45b7-f17a-4634-845e-a2521674ddd3', now()),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'f3f478e9-810f-4be2-bf95-d445bcafa07a', now()),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'e48374bc-f7c7-4a1d-a522-8528e856b676', now()),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'b308cdfd-7922-4c7e-81b5-5847f28d47dc', now()),
('ffffffff-ffff-ffff-ffff-ffffffffffff', 'f738b00b-67f6-4ba9-9edf-23d4107d09d3', now())
ON CONFLICT DO NOTHING;

COMMIT;