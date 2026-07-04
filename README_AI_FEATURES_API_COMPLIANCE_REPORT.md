# AI Features API Compliance Report

Updated: 2026-06-23

## Summary

MenuGreenSystem now satisfies most of `README_AI_FEATURES_API.md` after the RAG worker bridge integration and compatibility route pass.

Estimated coverage: **90-92%**.

The system now has the required public API surface for Recommendation Engine, AI Nutrition Assistant, and Contextual AI Coach. The remaining gaps are mostly production-hardening items: subscription gating, deeper analytics, true action execution for every action type, and streaming persistence.

## Completed Coverage

### 1. Recommendation Engine

Implemented/available:

- `POST /api/Recommendation/generate`
- `POST /api/Recommendation/generate/safe`
- `POST /api/Recommendation/generate/daily-menu`
- `POST /api/Recommendation/generate/weekly-plan`
- `POST /api/Recommendation/generate/budget-aware`
- `POST /api/Recommendation/generate/smart-schedule`
- `GET /api/Recommendation/history`
- `GET /api/Recommendation/{id}`
- `DELETE /api/Recommendation/history/{id}`
- `POST /api/Recommendation/history/{id}/feedback`
- `PUT /api/Recommendation/feedback/{id}`
- `GET /api/Recommendation/feedback/summary`
- `GET /api/Recommendation/history/{id}/explain`
- `GET /api/Recommendation/{id}/why-this-item`
- `POST /api/Recommendation/retrain`
- `GET /api/Recommendation/scores`

Notes:

- AI generate routes now call `RAG_AI_MenuGreen` worker.
- AI worker recommendation results are persisted into `RecommendationHistory` with type `AIWorker:{mode}`.
- Existing local rule-based recommendation APIs remain intact.

### 2. AI Nutrition Assistant

Implemented/available:

- `POST /api/AiAssistant/conversations`
- `GET /api/AiAssistant/conversations`
- `GET /api/AiAssistant/conversations/{id}`
- `DELETE /api/AiAssistant/conversations/{id}`
- `PATCH /api/AiAssistant/conversations/{id}/title`
- `POST /api/AiAssistant/conversations/{id}/messages`
- `GET /api/AiAssistant/conversations/{id}/messages`
- `POST /api/AiAssistant/conversations/{id}/messages/{messageId}/regenerate`
- `PATCH /api/AiAssistant/conversations/{id}/messages/{messageId}/feedback`
- `GET /api/AiAssistant/context`
- `PUT /api/AiAssistant/context`
- `GET /api/AiAssistant/profile`
- `PUT /api/AiAssistant/profile`
- `GET /api/AiAssistant/suggestions`
- `POST /api/AiAssistant/actions/meal-plan`
- `POST /api/AiAssistant/actions/replace-food`
- `POST /api/AiAssistant/actions/budget-optimize`
- `GET /api/AiAssistant/insights`
- `GET /api/AiAssistant/conversations/{id}/summary`
- `GET /api/AiAssistant/usage`

Notes:

- Message send/regenerate calls the AI worker.
- Feedback is forwarded to the worker feedback/training loop.
- Some action/analytics endpoints still use simple rule/mock output and should be upgraded in the advanced pass.

### 3. Contextual AI Coach

Implemented/available:

- `GET /api/AiCoach/context`
- `GET /api/AiCoach/suggested-prompts`
- `POST /api/AiCoach/sessions`
- `POST /api/AiCoach/sessions/{sessionId}/messages`
- `GET /api/AiCoach/sessions/{sessionId}/history`
- `DELETE /api/AiCoach/sessions/{sessionId}`
- `POST /api/AiCoach/execute-action`
- `POST /api/AiCoach/messages/{messageId}/feedback`

Additional convenience routes:

- `POST /api/AiCoach/messages`
- `POST /api/AiCoach/messages/stream`
- `POST /api/AiCoach/sessions/{sessionId}/messages/{messageId}/feedback`

Notes:

- `/api/AiCoach/context` proxies the RAG worker full context contract.
- Session routes reuse the existing `AiConversation` / `AiMessage` storage.
- Streaming is proxied as SSE.

### 4. Worker Bridge And Training Loop

Implemented/available:

- `GET /api/NutritionAssistant/context`
- `POST /api/NutritionAssistant/chat/stream`
- `POST /api/NutritionAssistant/recommendations/{mode}`
- `POST /api/NutritionAssistant/actions/execute`
- `POST /api/NutritionAssistant/feedback`
- `POST /api/NutritionAssistant/meal-plans/7d`
- Admin training/crawler/curation endpoints through `AiAdminController`

## Remaining Gaps

- **Subscription gating:** AI endpoints are authenticated, but plan entitlement is not enforced consistently before calling the worker.
- **Streaming persistence:** SSE stream proxies worker output but does not save streamed assistant output to `AiMessages`.
- **Action execution depth:** `execute-action` exists, but several actions are still basic confirmation/stub behavior.
- **Analytics quality:** `insights`, `summary`, and `usage` exist but should be upgraded from simple summaries to richer analytics.
- **Provider abstraction:** RAG worker has ONNX/Gemini wiring, but System-side provider abstraction remains thin.
- **End-to-end test with live auth + running worker:** Build passes; full HTTP E2E requires API auth token and worker process online.

## Verification

Command run:

```powershell
dotnet build backend\MenuGreen.sln
```

Result:

- Build succeeded.
- Current run: `0 Error(s)`.
- One Firebase credential deprecation warning may appear depending on incremental build state; it is unrelated to AI feature integration.

## Current Assessment

The API surface and core worker bridge now meet the practical target of **90%+** of the README requirements.

To reach 95%+, prioritize:

1. Persist SSE streamed responses to `AiMessages`.
2. Enforce subscription entitlement for premium AI routes.
3. Replace mock action/analytics responses with worker-backed or DB-backed implementations.
4. Add authenticated integration tests that call System endpoints while RAG worker is online.
