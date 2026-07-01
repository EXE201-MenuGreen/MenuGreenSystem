-- =============================================================================
-- MenuGreen Seed Data - Table: recommendation_feedbacks
-- Sequence Number: 32
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS recommendation_feedbacks CASCADE;

CREATE TABLE recommendation_feedbacks (
    "Id" uuid NOT NULL,
    "RecommendationId" uuid NOT NULL,
    "Rating" integer NULL,
    "Feedback" text NULL,
    "CreatedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_recommendation_feedbacks" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_recommendation_history_RecommendationId" FOREIGN KEY ("RecommendationId") REFERENCES recommendation_history ("Id") ON DELETE CASCADE
);

INSERT INTO recommendation_feedbacks ("Id", "RecommendationId", "Rating", "Feedback", "CreatedAt")
VALUES
('d7af81fb-f3d3-4ac5-9ae6-2a3b06638c22', '140e2a62-2316-4185-a98b-f5b5b6287ca5', 4, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('d4abff69-db29-423a-b5b4-1f62180d7703', 'a8e10ff4-a461-4c2f-aeb3-1ca94cede19f', 4, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('6d37395d-4641-4a09-ba8d-520a3eef52ff', 'f2138dcd-8a30-4827-a0e3-7df069f05190', 4, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('46b8b2b1-20b8-446e-9110-c758d4adec9d', '5c0b848c-95a3-4a92-8de8-8ccc6e400531', 5, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('1fa9347a-6a7d-49aa-bb4e-d1fcf200727d', 'eea98ac7-8b45-481e-8ae6-5c549004e1eb', 4, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('2874c206-d07b-4075-8beb-c33eb6cf2db0', '277d5e7a-7dcf-4395-93e7-357f7cbf8dcc', 5, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('01257e42-6e83-4271-babd-29d2f677dfa5', 'e313742d-5776-4568-8c02-831cde456d23', 5, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('3b06095c-0851-4a19-82a2-a5fcf4aa64cd', '5b4dbeef-0350-4be0-8ee5-659f9e86a9bd', 5, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('91c636bd-0db1-4301-b3c7-a999c4bdda67', 'fddb765c-9e8a-4781-a1f7-cee4c9b3fc2b', 4, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('3035f852-cca9-4e4b-a0dd-11c6922e0597', '4bd2dd83-48b4-46de-8ef0-066b3abb978c', 4, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('6824c371-0f79-4c8d-89cf-be9193af6ee4', 'ae83de28-51fa-405b-bd68-c86375f7b7b1', 4, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('90b3c35f-4e54-4090-8025-a39f86ac6e0f', '9770f4e1-b730-4a87-ab8b-4c5c3e2bfaea', 5, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('8809745c-b5b0-451f-8bbb-63a5e3449582', '7ac9afe9-6031-4e98-8d93-b98131187e59', 5, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('78aadd79-57af-41dd-9d5f-003749d0a459', 'cd2ee33c-d1d6-4877-9522-21f36c0b363a', 5, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day'),
('7c542d46-75f9-4e26-9dcb-d278619754bc', '02d7b550-4ee9-474c-aedd-19eb5f834bef', 5, 'Đề xuất thực đơn rất ngon và phù hợp với khẩu vị của tôi', now() - interval '1 day')
ON CONFLICT DO NOTHING;

COMMIT;