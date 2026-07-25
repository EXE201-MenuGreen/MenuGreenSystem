-- =============================================================================
-- MenuGreen Seed Data - Table: user_substitution_preferences
-- Sequence Number: 54
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS user_substitution_preferences CASCADE;

CREATE TABLE user_substitution_preferences (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "OriginalIngredientId" uuid NOT NULL,
    "SubstituteIngredientId" uuid NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_user_substitution_preferences" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_user_substitution_preferences_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_user_sub_pref_original_ingredient" FOREIGN KEY ("OriginalIngredientId") REFERENCES ingredients ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_user_sub_pref_substitute_ingredient" FOREIGN KEY ("SubstituteIngredientId") REFERENCES ingredients ("Id") ON DELETE CASCADE
);

-- Seed Data for user_substitution_preferences
INSERT INTO user_substitution_preferences ("Id", "UserId", "OriginalIngredientId", "SubstituteIngredientId", "CreatedAt")
VALUES
('11000000-0000-0000-0000-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '73cb3e0a-5abc-5c6c-a7a2-7a9ac350f4cd', '01619128-a551-5bcb-84a9-5f7ddf562db4', now())
ON CONFLICT DO NOTHING;

COMMIT;
