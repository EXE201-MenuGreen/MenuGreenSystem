# Test: Admin Migration API

Manual test cho 3 endpoints mới ở `AdminMigrationController`. Chạy sau khi merge code + image mới được deploy.

## Prerequisites

- API base URL (vd: `https://api.menugreen.food`)
- JWT admin token (lấy từ admin login endpoint)
- `curl`, `jq`

## Test plan

### 1. Auth check (expect 401 without token)

```bash
BASE=https://api.menugreen.food
curl -i "$BASE/api/admin/migrations/status"
```

Expect: `HTTP/1.1 401 Unauthorized`

### 2. Auth check with non-admin token (expect 403)

```bash
USER_TOKEN="<login as regular user>"
curl -i -H "Authorization: Bearer $USER_TOKEN" "$BASE/api/admin/migrations/status"
```

Expect: `HTTP/1.1 403 Forbidden`

### 3. Status (expect 200 + applied/pending list)

```bash
ADMIN_TOKEN="<login as admin>"
curl -sS -H "Authorization: Bearer $ADMIN_TOKEN" "$BASE/api/admin/migrations/status" | jq .
```

Expect:

```json
{
  "gitSha": "<7+ char>",
  "dataAccessLayerVersion": "<n.n.n.n>",
  "applied": ["...", "..."],
  "pending": [],
  "drift": []
}
```

### 4. History (expect 200 + raw __EFMigrationsHistory rows)

```bash
curl -sS -H "Authorization: Bearer $ADMIN_TOKEN" "$BASE/api/admin/migrations/history" | jq .
```

Expect:

```json
{
  "count": 3,
  "rows": [
    { "migrationId": "20260617054403_init", "productVersion": "9.0.0" },
    ...
  ]
}
```

### 5. Apply (idempotent — expect 200, newlyApplied=[])

```bash
curl -i -X POST -H "Authorization: Bearer $ADMIN_TOKEN" "$BASE/api/admin/migrations/apply"
```

Expect:

```json
{
  "gitSha": "...",
  "appliedBefore": ["..."],
  "appliedAfter": ["..."],
  "newlyApplied": [],
  "message": "Database is already up to date."
}
```

### 6. Apply on pending (expect 200 + newlyApplied non-empty)

Sau khi deploy image mới nhưng DB chưa được restart container:

```bash
curl -sS -X POST -H "Authorization: Bearer $ADMIN_TOKEN" "$BASE/api/admin/migrations/apply" | jq .
```

Expect: `newlyApplied` chứa danh sách migrations mới apply được.

### 7. Apply on broken schema (expect 500 + error message)

Nếu DB đang có drift (vd: __EFMigrationsHistory có row mà DLL không biết):

```bash
curl -i -X POST -H "Authorization: Bearer $ADMIN_TOKEN" "$BASE/api/admin/migrations/apply"
```

Expect: `HTTP/1.1 500 Internal Server Error` với body chứa `error` field.

QUAN TRỌNG: container vẫn sống, admin có thể retry sau khi fix DB thủ công.

## Log verification

```bash
docker logs --since 5m menugreen_api 2>&1 | grep "MIGRATION-API"
```

Expect các dòng:

```
[MIGRATION-API] Apply triggered by <user>. Applied before (n): [...]
[MIGRATION-API] Applied m new migration(s): [...]
```

Hoặc nếu lỗi:

```
[MIGRATION-API] FATAL: Apply failed for GitSHA=<sha>.
```

## Cross-check

Sau test pass, chạy `backend/diagnose-migrations.sh` (đã có ở session trước) để verify DB state khớp với DLL inventory.

## Rollback

Nếu controller gây crash app:

1. Comment out route `api/admin/migrations` trong `Program.cs`:
   ```csharp
   // app.MapControllers(); // temporarily disable all controllers
   ```
   KHÔNG khuyến khích cách này — sẽ tắt cả API.
2. Better: revert commit của controller, redeploy.
3. Auto-apply ở startup KHÔNG bị ảnh hưởng — vẫn chạy bình thường khi container restart.
