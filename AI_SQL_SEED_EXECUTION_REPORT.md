# AI SQL Seed Execution Report

Date: 2026-06-23

## Summary

- Reviewed the newly pulled SQL files under `backend/MenuGreen_AI_SeedData`.
- Did not run `backend/MenuGreen_AI_SeedData.sql` against the main `MenuGreen` database because it contains `DROP TABLE IF EXISTS ... CASCADE` for core tables and would reset existing dev data.
- Fixed invalid UUID literals in the combined SQL file so it can run cleanly on a disposable/probe database:
  - `p100...`, `p200...`, `p300...` -> `f100...`, `f200...`, `f300...`
  - `m100...`, `m200...` -> `e100...`, `e200...`
  - `r100...` -> `d100...`
- Tested the fixed combined script on a temporary PostgreSQL database. It completed and committed successfully.

## Main Database Action

Target database: local PostgreSQL database `MenuGreen`.

Before touching the database, created a backup dump:

```text
backend/db_backups/MenuGreen_before_ai_seed_20260623_140507.dump
```

The backup folder is ignored by git via `.gitignore`.

Instead of running the destructive combined script, only missing AI/advanced tables were created from split seed files:

- `41_campaigns.sql`
- `42_coach_profiles.sql`
- `43_coach_connections.sql`
- `44_coach_feedbacks.sql`
- `45_custom_user_portions.sql`
- `46_food_portion_mappings.sql`
- `47_meal_log_substitutions.sql`
- `48_meal_plan_item_substitutions.sql`
- `49_micro_learning_cards.sql`
- `50_user_card_interactions.sql`
- `51_premium_programs.sql`
- `52_user_premium_programs.sql`
- `53_user_program_milestones.sql`
- `54_user_substitution_preferences.sql`
- `55_PtReviewRequests.sql`

`47_meal_log_substitutions.sql` was executed with its demo `MealLogId` adjusted to an existing local `meal_logs` row, because the split seed referenced a meal log ID not present in the already-seeded main database.

## Verification

Post-run database verification:

- Public tables: `56`
- New seeded table counts:
  - `campaigns`: `2`
  - `coach_profiles`: `1`
  - `coach_connections`: `1`
  - `coach_feedbacks`: `1`
  - `custom_user_portions`: `2`
  - `food_portion_mappings`: `3`
  - `meal_log_substitutions`: `1`
  - `meal_plan_item_substitutions`: `1`
  - `micro_learning_cards`: `2`
  - `user_card_interactions`: `1`
  - `premium_programs`: `2`
  - `user_premium_programs`: `1`
  - `user_program_milestones`: `2`
  - `user_substitution_preferences`: `1`
  - `PtReviewRequests`: `1`

Existing data remained present after the incremental seed:

- `users`: `16`
- `meal_logs`: `225`
- `ai_conversations`: `31`
- `recommendation_history`: `15`

Build verification:

```powershell
dotnet build backend\MenuGreen.sln
```

Result: build passed with 3 existing warnings and 0 errors.

## Notes

- Running the combined SQL file on the main database is still destructive by design because it drops and recreates tables.
- For local refresh/reset, use the combined file only when a full demo-data reset is desired and after backing up the database.
- For normal development, prefer migrations or targeted split files for missing tables.
