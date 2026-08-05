-- =============================================================================
-- MenuGreen Seed Data - Table: coach_feedbacks
-- Sequence Number: 44
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS coach_feedbacks CASCADE;

CREATE TABLE coach_feedbacks (
    "Id" uuid NOT NULL,
    "ClientId" uuid NOT NULL,
    "CoachId" uuid NOT NULL,
    "FeedbackType" character varying(50) NOT NULL DEFAULT 'General',
    "TargetId" uuid NULL,
    "MealType" character varying(50) NULL,
    "LogDate" date NULL,
    "Content" text NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_coach_feedbacks" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_coach_feedbacks_users_ClientId" FOREIGN KEY ("ClientId") REFERENCES users ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_coach_feedbacks_users_CoachId" FOREIGN KEY ("CoachId") REFERENCES users ("Id") ON DELETE CASCADE
);

-- Seed Data for coach_feedbacks
INSERT INTO coach_feedbacks ("Id", "ClientId", "CoachId", "FeedbackType", "TargetId", "MealType", "LogDate", "Content", "CreatedAt")
VALUES
('70000000-0000-0000-0000-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '77777777-7777-7777-7777-777777777777', 'General', NULL, NULL, NULL, 'Bạn đang thực hiện rất tốt việc thâm hụt calo tuần này. Cố gắng duy trì lượng nước uống và tập luyện đều đặn nhé!', now() - interval '1 day')
ON CONFLICT DO NOTHING;

COMMIT;
