-- =============================================================================
-- MenuGreen Seed Data - Table: allergies
-- Sequence Number: 19
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS allergies CASCADE;

CREATE TABLE allergies (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "Name" text NOT NULL,
    "Notes" text NULL,
    "IsActive" boolean NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_allergies" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_allergies_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO allergies ("Id", "UserId", "Name", "Notes", "IsActive", "CreatedAt", "UpdatedAt")
VALUES
('f738b00b-67f6-4ba9-9edf-23d4107d09d3', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Dị ứng hải sản', 'Ghi chú dị ứng thức ăn nhẹ', true, now(), now()),
('704d45b7-f17a-4634-845e-a2521674ddd3', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Dị ứng trứng', 'Ghi chú dị ứng thức ăn nhẹ', true, now(), now()),
('f3f478e9-810f-4be2-bf95-d445bcafa07a', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Dị ứng sữa lactose', 'Ghi chú dị ứng thức ăn nhẹ', true, now(), now()),
('e48374bc-f7c7-4a1d-a522-8528e856b676', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Dị ứng đậu phộng', 'Ghi chú dị ứng thức ăn nhẹ', true, now(), now()),
('b308cdfd-7922-4c7e-81b5-5847f28d47dc', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Dị ứng Gluten', 'Ghi chú dị ứng thức ăn nhẹ', true, now(), now())
ON CONFLICT DO NOTHING;

COMMIT;