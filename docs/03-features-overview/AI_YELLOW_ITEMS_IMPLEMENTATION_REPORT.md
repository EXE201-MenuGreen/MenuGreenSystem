# AI Yellow Items Implementation Report

Updated: 2026-07-03

## Scope

Completed every item previously marked `⚠️` in `README_AI_FEATURES_API.md` without adding a database migration.

## Implemented

### Recommendation recalibration

- `POST /api/Recommendation/retrain` now reads only the authenticated user's histories and feedback.
- Supports `dryRun`, `minimumFeedbackCount`, and `lookbackDays`.
- Calculates per-mode weights and preferred/avoided recommendation items.
- Persists tuning under `UserAiProfile.Preferences.recommendationTuning` and writes an `ActivityLog` audit entry.
- RAG recommendation ranking consumes these signals through `personalization_fit`.

### AI Assistant actions

- Meal-plan action uses the user's stored calorie target, latest budget, cooking-time preference, and the RAG 7-day planner.
- Replace-food validates the original food and requests allergy-safe alternatives while excluding that food.
- Budget optimization uses the user's profile/preference/budget instead of fixed mock values.
- Completed actions write audit metadata.

### Insights and analytics

- Insights aggregate topics from actual user messages.
- Conversation summary uses actual message count, dominant topics, and key user questions.
- Usage returns real totals, user/assistant counts, active days, current week/month counts, last-used time, and a seven-day series.

### Function calling

- `POST /api/AiCoach/execute-action` supports all declared action types.
- Mutating or recommendation-generating actions require `confirmed=true`.
- `schedule_meal` appends to an existing daily plan instead of replacing its items.
- `log_meal` validates quantity before writing through `NutritionTrackingService`.
- RAG smart-schedule actions now include the selected entity ID, date, time, meal type, and calories.

## Verification

- `dotnet build backend/MenuGreen.sln --no-restore`: passed, 0 errors.
- `python -m compileall runtime/app`: passed.
- `.venv/Scripts/python.exe -m pytest tests -q`: 22 passed.

The System solution currently has no .NET test project, so System verification is compile-time plus the RAG contract suite. Live authenticated API smoke testing still requires the local PostgreSQL and both services running with matching configuration.

No database migration was created. Existing unrelated worktree changes were left untouched.
