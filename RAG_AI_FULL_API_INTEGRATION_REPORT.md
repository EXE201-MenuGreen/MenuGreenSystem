# RAG AI MenuGreen Full API Integration Report

Date: 2026-06-23

## Scope

Reviewed and integrated these two projects:

- `D:\EXE\MenuGreenSystem`
- `D:\EXE\RAG_AI_MenuGreen`

Goal: keep `MenuGreenSystem` as the public/business backend and integrate the runnable API features from `RAG_AI_MenuGreen` through MenuGreen API endpoints. Clients should not call the RAG worker directly.

## Architecture Decision

Final flow:

```text
Mobile/Web/Admin
  -> MenuGreenSystem API
  -> MenuGreen BusinessLogicLayer bridge services
  -> RAG_AI_MenuGreen FastAPI worker
```

Reasoning:

- `MenuGreenSystem` already owns auth, roles, rate limit, EF Core state, users, profiles, allergies, meal logs, meal plans, AI conversations, and admin access.
- `RAG_AI_MenuGreen` is best used as an internal AI worker for chat, training feedback, curation, crawler ingestion, and 7-day AI meal-plan generation.
- This avoids exposing worker contracts, Gemini keys, runtime debug APIs, and worker database details to mobile/web clients.

## What Was Found

### MenuGreenSystem

- Existing `NutritionAssistantService` already had the correct high-level bridge direction for `/worker/chat`.
- Existing `AiAssistantService` was still using the old payload shape: `conversationId`, `userMessage`, `context`.
- Flutter mobile uses `/api/AiAssistant/...`.
- Temporary web AI Coach uses `/api/NutritionAssistant/...`.
- Admin web uses `/api/AiAdmin/...`.

### RAG_AI_MenuGreen Runtime API

Runtime endpoints found in `runtime/app/api/routes.py`:

- `GET /health`
- `GET /debug/db`
- `GET /debug/postgres`
- `POST /worker/chat`
- `POST /admin/crawler/normalize`
- `POST /admin/crawler/ingest`
- `POST /api/ai/feedback`
- `POST /api/ai/feedback/{feedbackId}/to-training-sample`
- `POST /api/ai/training-samples`
- `GET /api/ai/training-samples`
- `PATCH /api/ai/training-samples/{sampleId}/review`
- `POST /api/ai/curation/nightly`
- `POST /api/ai/meal-plans/7d`

## Changes Made

### Backend DTOs

Added typed DTOs:

- `backend/MenuGreen.BusinessLogicLayer/DTOs/Requests/NutritionAssistantWorkerRequests.cs`
- `backend/MenuGreen.BusinessLogicLayer/DTOs/Responses/NutritionAssistantWorkerResponses.cs`

These cover:

- AI feedback
- 7-day meal plan generation
- crawler normalize/ingest
- training sample create/list/review
- sample creation from feedback

### NutritionAssistant Bridge

Updated:

- `backend/MenuGreen.BusinessLogicLayer/Interfaces/INutritionAssistantService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/NutritionAssistantService.cs`

Added worker gateway methods for:

- worker debug DB checks
- worker debug PostgreSQL checks
- feedback creation
- 7-day meal-plan generation
- crawler normalize
- crawler ingest
- training sample create/list/review
- feedback-to-training-sample conversion
- nightly curation

Also changed worker serialization to `snake_case` so the .NET bridge matches the FastAPI/Pydantic contract.

### User API

Updated:

- `backend/MenuGreen.API/Controllers/NutritionAssistantController.cs`

Added:

- `POST /api/NutritionAssistant/feedback`
- `POST /api/NutritionAssistant/meal-plans/7d`

Existing chat/conversation APIs remain unchanged.

### Admin API

Updated:

- `backend/MenuGreen.API/Controllers/AiAdminController.cs`

Added:

- `GET /api/AiAdmin/debug/db`
- `GET /api/AiAdmin/debug/postgres`
- `POST /api/AiAdmin/crawler/normalize`
- `POST /api/AiAdmin/crawler/ingest`
- `POST /api/AiAdmin/training-samples`
- `GET /api/AiAdmin/training-samples`
- `PATCH /api/AiAdmin/training-samples/{sampleId}/review`
- `POST /api/AiAdmin/feedback/{feedbackId}/to-training-sample`
- `POST /api/AiAdmin/curation/nightly`

Existing:

- `GET /api/AiAdmin/overview`
- `GET /api/AiAdmin/health`

### Mobile AiAssistant Path

Updated:

- `backend/MenuGreen.BusinessLogicLayer/Services/AiAssistantService.cs`

Changed mobile chat/regenerate calls to send the current RAG worker contract:

- `message`
- `user_id`
- `thread_id`
- `request_id`
- `conversation_history`

Also changed message feedback from console-only logging to a real `POST /api/ai/feedback` worker call.

The `actions/meal-plan` path now calls worker `POST /api/ai/meal-plans/7d` instead of returning the old hardcoded sample.

## Endpoint Mapping

| RAG worker endpoint | MenuGreenSystem endpoint | Access |
|---|---|---|
| `GET /health` | `GET /api/AiAdmin/health` | Admin |
| `GET /debug/db` | `GET /api/AiAdmin/debug/db` | Admin |
| `GET /debug/postgres` | `GET /api/AiAdmin/debug/postgres` | Admin |
| `POST /worker/chat` | `POST /api/NutritionAssistant/chat` and `/api/AiAssistant/conversations/{id}/messages` | User |
| `POST /api/ai/feedback` | `POST /api/NutritionAssistant/feedback` and AiAssistant message feedback | User |
| `POST /api/ai/meal-plans/7d` | `POST /api/NutritionAssistant/meal-plans/7d` and AiAssistant meal-plan action | User |
| `POST /admin/crawler/normalize` | `POST /api/AiAdmin/crawler/normalize` | Admin |
| `POST /admin/crawler/ingest` | `POST /api/AiAdmin/crawler/ingest` | Admin |
| `POST /api/ai/training-samples` | `POST /api/AiAdmin/training-samples` | Admin |
| `GET /api/ai/training-samples` | `GET /api/AiAdmin/training-samples` | Admin |
| `PATCH /api/ai/training-samples/{sampleId}/review` | `PATCH /api/AiAdmin/training-samples/{sampleId}/review` | Admin |
| `POST /api/ai/feedback/{feedbackId}/to-training-sample` | `POST /api/AiAdmin/feedback/{feedbackId}/to-training-sample` | Admin |
| `POST /api/ai/curation/nightly` | `POST /api/AiAdmin/curation/nightly` | Admin |

## Validation

Ran:

```powershell
dotnet build backend\MenuGreen.sln
```

Result:

- Build succeeded.
- 0 errors.
- 1 existing warning remains in `Program.cs` about obsolete Firebase `GoogleCredential.FromFile`.

Runtime smoke check:

```powershell
Invoke-RestMethod -Uri http://127.0.0.1:8000/health -TimeoutSec 5
```

Result:

- Worker was not running locally on port 8000 during this pass.
- Live FastAPI smoke test was not possible yet.
- Once worker is started, use `GET /api/AiAdmin/health` from MenuGreenSystem to verify the bridge.

## Preserved Existing User Changes

These files were already dirty before the integration work and were not reverted:

- `backend/MenuGreen.API/appsettings.Development.json`
- `backend/docker-compose.yml`
- `frontend/pubspec.lock`

No database migration was added.
No frontend UI flow was changed.

## Notes And Caveats

- `NutritionAssistant:WorkerUrl` can be either the worker root URL or the full `/worker/chat` URL. The bridge normalizes it internally.
- Admin debug endpoints are intentionally under `AdminOnly`; they should not be exposed publicly without admin auth.
- Some legacy `AiAssistantService` features still have local fallback/mock behavior when RAG has no equivalent runtime endpoint, such as food replacement suggestions and simple topic insights.
- The old hardcoded meal-plan sample is excluded from compile with `#if false` because the file contains legacy encoded Vietnamese text that made a clean patch removal unreliable. It does not affect runtime or build.

## Next Recommended Checks

1. Start RAG worker:

```powershell
cd D:\EXE\RAG_AI_MenuGreen\runtime
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --reload --port 8000
```

2. Start MenuGreen backend and call:

```text
GET /api/AiAdmin/health
POST /api/NutritionAssistant/chat
POST /api/NutritionAssistant/meal-plans/7d
POST /api/NutritionAssistant/feedback
```

3. If the team wants admin UI controls for training samples/crawler/curation, add those to `frontend-web` on top of the new API endpoints.
