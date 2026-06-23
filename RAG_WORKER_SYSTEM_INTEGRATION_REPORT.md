# RAG Worker System Integration Report

Updated: 2026-06-23

## Summary

MenuGreenSystem now bridges the new `RAG_AI_MenuGreen` worker contracts through backend APIs while keeping MenuGreenSystem as the public API/auth/session owner.

This integration does not move auth/session/business ownership into the worker. The worker remains an internal runtime.

## Integrated worker features

### NutritionAssistant bridge

Added public/backend bridge routes:

- `POST /api/NutritionAssistant/chat/stream`
- `GET /api/NutritionAssistant/context?date=YYYY-MM-DD`
- `POST /api/NutritionAssistant/recommendations/{mode}`
- `POST /api/NutritionAssistant/actions/execute`

Supported recommendation modes:

- `generate`
- `safe`
- `daily-menu`
- `weekly-plan`
- `budget-aware`
- `smart-schedule`

These route to the RAG worker:

- `/worker/chat/stream`
- `/worker/context`
- `/api/ai/recommendations/*`
- `/api/ai/actions/execute`

### AiCoach public bridge

Added `AiCoachController`:

- `GET /api/AiCoach/context`
- `POST /api/AiCoach/messages`
- `POST /api/AiCoach/messages/stream`
- `POST /api/AiCoach/execute-action`

The controller reuses `INutritionAssistantService` so worker wiring stays in one bridge service.

### Recommendation API bridge

Mapped AI generate routes to the worker:

- `POST /api/Recommendation/generate`
- `POST /api/Recommendation/generate/safe`
- `POST /api/Recommendation/generate/daily-menu`
- `POST /api/Recommendation/generate/weekly-plan`
- `POST /api/Recommendation/generate/budget-aware`
- `POST /api/Recommendation/generate/smart-schedule`

Existing local recommendation routes such as history, explain, feedback, scores, `GET /daily-menu`, and `POST /smart-schedule` were left intact.

### Worker internal key

`NutritionAssistantService` now sends `X-AI-Runtime-Key` to worker requests when either config key is set:

- `NutritionAssistant:WorkerInternalKey`
- `AI_RUNTIME_INTERNAL_KEY`

This matches the optional worker auth added in `RAG_AI_MenuGreen`.

## Notes

- Streaming is proxied as `text/event-stream`.
- System-side chat persistence remains on the non-streaming chat route.
- Streaming currently proxies worker SSE and does not persist assistant stream output into `AiMessages`.
- Worker recommendation/action/context responses are returned as `JsonElement` to keep the system bridge compatible while the worker contract evolves.

## Verification

Command run:

```powershell
dotnet build backend\MenuGreen.sln
```

Result:

- Build succeeded.
- Warnings were pre-existing/non-blocking:
  - migration class name `init`
  - obsolete Firebase credential API warning

## Next step

After confirming the API surface from frontend/mobile, wire UI calls to:

- `/api/AiCoach/context`
- `/api/AiCoach/messages/stream`
- `/api/Recommendation/generate/*`

Then run end-to-end with the RAG worker process online.
