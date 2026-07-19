-- =============================================================================
-- MenuGreen Seed Data - Table: profiles
-- Sequence Number: 03
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS profiles CASCADE;

CREATE TABLE profiles (
    "UserId" uuid NOT NULL,
    "FullName" character varying(255) NULL,
    "AvatarUrl" text NULL,
    "DateOfBirth" date NULL,
    "Gender" character varying(20) NULL,
    "PreferredCuisine" character varying(100) NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_profiles" PRIMARY KEY ("UserId"),
    CONSTRAINT "FK_profiles_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO profiles ("UserId", "FullName", "AvatarUrl", "DateOfBirth", "Gender", "PreferredCuisine", "CreatedAt", "UpdatedAt")
VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Admin MenuGreen', 'https://i.pravatar.cc/150?u=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '1995-04-12', 'Male', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Nguyễn Văn Demo', 'https://i.pravatar.cc/150?u=bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '1995-04-12', 'Male', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Trần Thị Free', 'https://i.pravatar.cc/150?u=cccccccc-cccc-cccc-cccc-cccccccccccc', '1997-09-22', 'Female', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Lê Văn Free', 'https://i.pravatar.cc/150?u=dddddddd-dddd-dddd-dddd-dddddddddddd', '1995-04-12', 'Male', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Phạm Hoàng Casual', 'https://i.pravatar.cc/150?u=eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '1995-04-12', 'Male', 'Tây Âu', now() - interval '30 days', now() - interval '30 days'),
('ffffffff-ffff-ffff-ffff-ffffffffffff', 'Hoàng Thị Gymer', 'https://i.pravatar.cc/150?u=ffffffff-ffff-ffff-ffff-ffffffffffff', '1997-09-22', 'Female', 'Nhật Bản', now() - interval '30 days', now() - interval '30 days'),
('885810e8-168f-4608-a72e-e23a20dfd258', 'Nguyễn Văn Bình', 'https://i.pravatar.cc/150?u=885810e8-168f-4608-a72e-e23a20dfd258', '1995-04-12', 'Male', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('48069bd5-f29a-417d-bdeb-c00797968aca', 'Trần Thị Hoa', 'https://i.pravatar.cc/150?u=48069bd5-f29a-417d-bdeb-c00797968aca', '1997-09-22', 'Female', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'Phạm Minh Tuấn', 'https://i.pravatar.cc/150?u=9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', '1995-04-12', 'Male', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('081b4669-b97f-4e75-b089-4c8de0151653', 'Lê Thị Mai', 'https://i.pravatar.cc/150?u=081b4669-b97f-4e75-b089-4c8de0151653', '1997-09-22', 'Female', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 'Hoàng Anh Office', 'https://i.pravatar.cc/150?u=586209d0-d3c4-43a4-bba7-5d4c73b37bc1', '1995-04-12', 'Male', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 'Vũ Thu Hà', 'https://i.pravatar.cc/150?u=b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', '1997-09-22', 'Female', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('453681f7-f489-47ed-842c-bc3ffd220423', 'Phan Huy Hoàng', 'https://i.pravatar.cc/150?u=453681f7-f489-47ed-842c-bc3ffd220423', '1995-04-12', 'Male', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('396f9dff-6c2a-422f-b0cc-8eb451168ed3', 'Đỗ Mỹ Linh', 'https://i.pravatar.cc/150?u=396f9dff-6c2a-422f-b0cc-8eb451168ed3', '1997-09-22', 'Female', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('5dc50160-db9e-447a-ba33-9026d8800ab5', 'Bùi Quốc Anh', 'https://i.pravatar.cc/150?u=5dc50160-db9e-447a-ba33-9026d8800ab5', '1995-04-12', 'Male', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('212ea8ea-749e-44a1-92d2-636bd617cbc8', 'Ngô Khánh Vy', 'https://i.pravatar.cc/150?u=212ea8ea-749e-44a1-92d2-636bd617cbc8', '1997-09-22', 'Female', 'Việt Nam', now() - interval '30 days', now() - interval '30 days'),
('cccccccc-cccc-cccc-cccc-cccccccccc01', 'Nguyễn Văn Coach', 'https://i.pravatar.cc/150?u=cccccccc-cccc-cccc-cccc-cccccccccc01', '1990-01-15', 'Male', 'Việt Nam', now() - interval '30 days', now() - interval '30 days')
ON CONFLICT DO NOTHING;

COMMIT;