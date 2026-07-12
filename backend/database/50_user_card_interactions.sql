-- =============================================================================
-- MenuGreen Seed Data - Table: user_card_interactions
-- Sequence Number: 50
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS user_card_interactions CASCADE;

CREATE TABLE user_card_interactions (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "CardId" uuid NOT NULL,
    "IsSaved" boolean NOT NULL DEFAULT false,
    "IsDismissed" boolean NOT NULL DEFAULT false,
    "IsRead" boolean NOT NULL DEFAULT false,
    "IsQuizCompleted" boolean NOT NULL DEFAULT false,
    "SelectedQuizOption" integer NULL,
    "IsQuizCorrect" boolean NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_user_card_interactions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_user_card_interactions_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_user_card_interactions_micro_learning_cards_CardId" FOREIGN KEY ("CardId") REFERENCES micro_learning_cards ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "IX_user_card_interactions_UserId_CardId" ON user_card_interactions ("UserId", "CardId");

-- Seed Data for user_card_interactions
INSERT INTO user_card_interactions ("Id", "UserId", "CardId", "IsSaved", "IsDismissed", "IsRead", "IsQuizCompleted", "SelectedQuizOption", "IsQuizCorrect", "UpdatedAt")
VALUES
('e2000000-0000-0000-0000-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'e1000000-0000-0000-0000-000000000001', true, false, true, true, 1, true, now())
ON CONFLICT DO NOTHING;

COMMIT;