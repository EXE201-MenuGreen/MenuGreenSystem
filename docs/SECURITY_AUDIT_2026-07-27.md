# Security audit — 2026-07-27

## Scope and safety boundary

- Repository: `MenuGreenSystem`
- Branch inspected and modified: `free-user-workflow`
- Git reference audited for history: `HEAD` of the current branch only
- No checkout, merge, rebase, push, commit, or history rewrite was performed.
- `main`, `develop`, and the separate `RAG_AI_MenuGreen` repository were not modified.

This was a static source/configuration audit plus local build, package audit, and
test verification. It was not an external penetration test, cloud-account audit,
mobile-binary reverse engineering exercise, or live production database review.

## Remediation completed

### Secrets and sensitive configuration

- Removed hardcoded Redis and database passwords from tracked documentation and
  seed tooling.
- Removed the real local development settings file. Its values were migrated to
  Windows User Environment Variables so local execution remains possible without
  committing a secret-bearing file.
- Removed tracked Firebase Android/Dart client configuration. CI now materializes
  `google-services.json` from a GitHub secret, and a placeholder-only example is
  provided. The previous local Android configuration is preserved outside the
  repository in a Windows User Environment Variable.
- Removed the Goong key from the Flutter application. Reverse geocoding now goes
  through an authenticated backend endpoint and the provider key remains
  server-side.
- Added placeholder-only environment examples and a full-history Gitleaks CI job.
- Removed OTP values from console output when email delivery is not configured.
  Missing email credentials now fail closed.
- Suppressed URL-level `HttpClient` logging for the Goong client because its
  provider key must be sent in the upstream query string.
- Nginx no longer logs query strings and redacts PT share-token paths.

The current tracked/untracked working tree was scanned for high-confidence AWS,
Google, OpenAI-style, GitHub, Slack, private-key, and assigned-secret patterns.
The remaining matches were environment-variable references, test values,
documentation placeholders, or private-key delimiter checks—not live values.

### Input validation and request hardening

- Added a global MVC input security filter:
  - maximum string length: 16,384 characters;
  - maximum collection/object members: 500;
  - maximum object depth: 16;
  - maximum visited values: 10,000;
  - rejects disallowed control characters and common active-content markers;
  - trims and NFC-normalizes non-credential strings;
  - does not mutate passwords, tokens, signatures, secrets, authorization values,
    or OTPs.
- Enabled strict JSON parsing: maximum depth 32, no comments, no trailing commas,
  and rejection of unknown DTO properties.
- Added safe model-validation responses and field constraints to critical auth,
  OTP, token, messaging, FCM, and SePay payloads.
- Default request body limit is 1 MiB. Multipart CV requests are limited to
  11 MiB, with an actual image limit of 10 MiB.
- CV upload validation now checks extension, MIME type, safe filename, and binary
  signature for JPEG, PNG, and WebP.
- SePay webhook requests are limited to 256 KiB, require JSON, cap authentication
  header lengths, validate the authenticated payload, and use a dedicated rate
  limit.
- The full SePay provider payload is no longer retained after verified fields are
  extracted, reducing stored banking PII.

### Authentication and API exposure

- JWT signing keys must contain at least 32 UTF-8 bytes. Production requires
  issuer and audience; signed token, lifetime, expiry, and HS256 checks are
  explicit; clock skew is one minute.
- Added an authenticated fallback authorization policy. Public endpoints now
  require an explicit `AllowAnonymous` decision.
- Refresh tokens are stored as SHA-256 hashes. Legacy plaintext rows remain
  readable only for migration and are replaced when rotated.
- OTPs are stored as keyed HMAC values and compared in constant time. Legacy
  plaintext OTP rows remain readable only during their short expiry window.
- Password reset revokes all existing refresh sessions.
- Authentication, OTP, AI, webhook, and global rate limits run in all
  environments and partition authenticated traffic by user where applicable.
- Production CORS rejects wildcard, HTTP, localhost, and path-bearing origins.
- Swagger is disabled by default outside development. Production metrics require
  a separate constant-time-checked token. Production health output no longer
  includes component details.
- API, Nginx, and Next.js security headers were added. The Next.js framework
  banner is disabled.
- Kestrel no longer emits its server header. The production container port is
  bound to loopback so Nginx remains the public entry point.
- Android release tasks now fail closed when release signing is missing. Debug
  signing for a release artifact requires an explicit opt-in used only by the
  disposable LAN APK workflow.
- Database migration drift now stops startup. The application no longer deletes
  unknown `__EFMigrationsHistory` records automatically.

### Dependencies

- Next.js and `eslint-config-next` were upgraded to `16.2.11`.
- Vulnerable transitive `brace-expansion`, `js-yaml`, `postcss`, and `sharp`
  versions were overridden through the pnpm workspace configuration.
- `pnpm audit` reports no known vulnerabilities.
- `dotnet list package --vulnerable --include-transitive` reports no vulnerable
  NuGet packages for the API project and its referenced projects.

## Remaining findings

### Critical — historical credentials must be rotated and purged

The current branch history still contains previously committed secret material,
including a CV service credential, a Redis password, development database
credentials, and Firebase client configuration. Removing values from the current
tree does not remove them from old commits.

Required follow-up:

1. Rotate/revoke every exposed credential at its provider first.
2. Coordinate a repository history rewrite with all contributors.
3. Force-push only after explicit approval and a backup.
4. Re-clone or carefully rebase all active worktrees.
5. Run Gitleaks against the rewritten full history before restoring branch
   protection.

History was deliberately not rewritten during this audit because the scope was
limited to the current branch and a rewrite would affect other collaborators.
The new full-history CI secret scan is therefore expected to fail until this
follow-up is completed.

### High — controller exception messages can still disclose internals

There are 223 direct `ex.Message` response occurrences across 33 controllers.
The global exception handler is safe, but it cannot protect exceptions caught
and returned directly by those controllers. Database/provider details or
business-sensitive values can therefore still reach clients.

Recommended fix: replace broad controller `catch (Exception)` blocks with
central typed domain exceptions and safe public error codes/messages. Log the
original exception server-side with the request trace ID.

### High — browser and mobile token storage

- The web app stores access and refresh tokens in `localStorage`; any successful
  XSS can read them.
- The Flutter app stores auth tokens in `SharedPreferences`; rooted devices,
  backups, or local compromise can expose them.

Recommended fix: use a backend-for-frontend flow with `Secure`, `HttpOnly`,
`SameSite` cookies for browser refresh sessions, keep short-lived access tokens
in memory, and move mobile credentials to platform-backed secure storage. This
requires an auth-flow migration and was not safely interchangeable within this
audit.

### Medium — bearer links expose report access

PT review links carry a bearer token in the URL and the token is stored in
plaintext in the database. Nginx logging is now redacted, but URLs can still
appear in browser history, screenshots, upstream/CDN logs, and copied messages.

Recommended fix: store only a hash of the share token, make links single-purpose
and optionally single-use, add revocation, shorten expiry, and use a POST
exchange that issues a short-lived session cookie before displaying health data.

### Medium — field-specific business validation remains uneven

The new global limits protect every MVC action argument from oversized and
structurally abusive values. Some request models still rely on service-layer
checks or defaults instead of explicit field-level ranges/enums. This can permit
semantically invalid but structurally safe requests and inconsistent error
responses.

Recommended fix: define per-endpoint schemas for allowed enums, numeric ranges,
date windows, and cross-field invariants; add integration tests for boundary and
malformed cases. Output encoding must remain context-specific—input filtering is
not a substitute for HTML/URL/SQL encoding.

### Medium — retained banking data needs a lifecycle policy

The raw SePay payload is no longer stored, but the normalized bank account and
transfer memo remain in `SepayTransactions`. Confirm the legal/business need,
encrypt sensitive columns at rest, restrict administrative access, redact
support exports, and implement documented retention/deletion periods.

### Low — build warnings and incomplete image/container scanning

- The backend build currently has four nullable-reference warnings. They are
  availability/quality risks and should be resolved.
- Trivy is not installed locally, so Docker images and OS packages were not
  checked against a container vulnerability database. Add Trivy (or equivalent)
  to CI and scan both build and runtime images.
- Flutter has no first-party vulnerability audit equivalent in this workflow.
  Dependency updates and platform advisories still require ongoing monitoring.

## Verification performed

- `dotnet build backend/MenuGreen.API/MenuGreen.API.csproj --no-restore`:
  succeeded, 0 errors, 4 warnings.
- `dotnet list ... package --vulnerable --include-transitive`: no vulnerable
  packages.
- `pnpm install`: succeeded.
- `pnpm audit`: no known vulnerabilities.
- `pnpm build`: succeeded; all 15 Next.js routes generated.
- Local and production Docker Compose files passed non-interpolating
  configuration validation.
- Android Gradle configuration passed with the Flutter-configured JDK 21.
- Flutter dependency resolution succeeded.
- Flutter analysis still reports eight pre-existing lint issues.
- Flutter test suite: 55 passed and 5 pre-existing UI expectation/animation
  tests failed. The failures are unrelated to the security changes and should
  be repaired separately.
- `git diff --check`: no whitespace errors (only Windows line-ending notices).
