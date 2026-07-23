#!/usr/bin/env bash
# deploy-server.sh
# -----------------------------------------------------------------------------
# Server-side deploy script. Invoked by .github/workflows/backend-cd.yml via
# appleboy/ssh-action. Lives outside the workflow file because GitHub Actions
# caps each ${{ }} expression at 21,000 characters — and an inline script: of
# this size blew past that limit on line 69 of backend-cd.yml.
#
# Invocation (from CI):
#   /tmp/nginx-deploy/backend/scripts/deploy-server.sh
# Required env vars:
#   IMAGE_NAME   e.g. docker.io/<user>/menugreensystem (provided by CI)
#   SHA          git SHA of the deploy commit         (provided by CI)
#   DOPPLER_TOKEN                                       (provided by CI)
#   APP_DIR       e.g. /home/ubuntu/apps/menugreen     (provided by CI)
# -----------------------------------------------------------------------------
set -e

IMAGE=$IMAGE_NAME
SHA=$SHA

# =================================================================
# BƯỚC 0a: Ensure self-signed cert exists (for catch-all HTTPS)
# - /etc/ssl/certs/ssl-cert-snakeoil.pem không có sẵn trên Ubuntu minimal
# - Generate on-the-fly nếu chưa có
# - Cert này dùng cho catch-all HTTPS server (reject unknown SNI)
# =================================================================
echo "=== [0a] Ensure self-signed cert exists ==="
if [ ! -f /etc/ssl/certs/menugreen-catchall.pem ] || [ ! -f /etc/ssl/private/menugreen-catchall.key ]; then
  sudo mkdir -p /etc/ssl/private
  sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/ssl/private/menugreen-catchall.key \
    -out /etc/ssl/certs/menugreen-catchall.pem \
    -subj "/CN=menugreen-catchall/O=MenuGreenSystem/C=VN" \
    2>/dev/null
  sudo chmod 600 /etc/ssl/private/menugreen-catchall.key
  sudo chmod 644 /etc/ssl/certs/menugreen-catchall.pem
  echo "  ✓ Generated self-signed cert"
else
  echo "  ⊘ Self-signed cert already exists"
fi

mkdir -p "$APP_DIR"

# =================================================================
# BƯỚC 0: Apply nginx config (TRƯỚC khi restart container)
# - SCP đã upload file lên /tmp/nginx-deploy/
# - appleboy/scp-action giữ cấu trúc thư mục theo source.
#   Nếu target là /tmp/nginx-deploy và source là backend/nginx/...,
#   thì file thực sự nằm ở /tmp/nginx-deploy/backend/nginx/nginx.conf
# - Tự rollback nếu nginx -t fail
# =================================================================
echo "=== [0/10] Apply nginx config from git ==="

# Tìm đường dẫn thực tế của file sau khi SCP (hỗ trợ cả 2 layout)
NGINX_CONF_DEPLOYED=""
CORS_MAP_DEPLOYED=""

for candidate in \
  "/tmp/nginx-deploy/nginx.conf" \
  "/tmp/nginx-deploy/backend/nginx/nginx.conf"; do
  if [ -f "$candidate" ]; then NGINX_CONF_DEPLOYED="$candidate"; break; fi
done

for candidate in \
  "/tmp/nginx-deploy/conf.d/cors-map.conf" \
  "/tmp/nginx-deploy/backend/nginx/conf.d/cors-map.conf"; do
  if [ -f "$candidate" ]; then CORS_MAP_DEPLOYED="$candidate"; break; fi
done

if [ -n "$NGINX_CONF_DEPLOYED" ] && [ -n "$CORS_MAP_DEPLOYED" ]; then
  NGINX_TS=$(date +"%Y%m%d_%H%M%S")
  echo "  Found nginx.conf at: $NGINX_CONF_DEPLOYED"
  echo "  Found cors-map.conf at: $CORS_MAP_DEPLOYED"

  # 1. Backup config hiện tại
  if [ -f /etc/nginx/conf.d/cors-map.conf ]; then
    sudo cp /etc/nginx/conf.d/cors-map.conf \
            /etc/nginx/conf.d/cors-map.conf.bak.$NGINX_TS
  fi
  if [ -f /etc/nginx/nginx.conf ] && [ ! -f /etc/nginx/nginx.conf.original.backup ]; then
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original.backup
  fi
  if [ -f /etc/nginx/nginx.conf ]; then
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak.$NGINX_TS
  fi

  # 2. Copy file mới
  sudo cp "$NGINX_CONF_DEPLOYED" /etc/nginx/nginx.conf
  sudo mkdir -p /etc/nginx/conf.d
  sudo cp "$CORS_MAP_DEPLOYED" /etc/nginx/conf.d/cors-map.conf

  # 3. Test syntax - FAIL thì rollback NGAY, không restart container
  if sudo nginx -t 2>&1; then
    # 4. Reload nginx (zero downtime)
    sudo systemctl reload nginx
    echo "  ✓ Nginx config applied and reloaded"
  else
    echo ">>> FATAL: nginx -t failed, rolling back nginx config..."
    if [ -f /etc/nginx/conf.d/cors-map.conf.bak.$NGINX_TS ]; then
      sudo cp /etc/nginx/conf.d/cors-map.conf.bak.$NGINX_TS \
              /etc/nginx/conf.d/cors-map.conf
    fi
    if [ -f /etc/nginx/nginx.conf.bak.$NGINX_TS ]; then
      sudo cp /etc/nginx/nginx.conf.bak.$NGINX_TS \
              /etc/nginx/nginx.conf
    fi
    echo ">>> ABORTING: Nginx config rolled back, deployment stopped"
    exit 1
  fi
fi

echo "=== Cleanup disk space - Before ==="
sudo docker system prune -af --volumes || true
echo "=== Disk space after cleanup ==="
df -h

# =================================================================
# Docker compose config — SCP'd from git by the CD workflow
# (source list in .github/workflows/backend-cd.yml).
# appleboy/scp-action keeps the source path under `target`, so the file
# ends up at either /tmp/nginx-deploy/docker-compose.prod.yml (when the
# CD list uses the root path) or /tmp/nginx-deploy/backend/docker-compose.prod.yml
# (when the CD list prefixes with `backend/`). Search both layouts.
# =================================================================
echo "=== Locate SCP'd docker-compose.prod.yml ==="
COMPOSE_DEPLOYED=""
for candidate in \
  "/tmp/nginx-deploy/docker-compose.prod.yml" \
  "/tmp/nginx-deploy/backend/docker-compose.prod.yml"; do
  if [ -f "$candidate" ]; then COMPOSE_DEPLOYED="$candidate"; break; fi
done

if [ -z "$COMPOSE_DEPLOYED" ]; then
  echo ">>> FATAL: docker-compose.prod.yml not found under /tmp/nginx-deploy/"
  echo ">>> Check the `source:` list in .github/workflows/backend-cd.yml"
  exit 1
fi
echo "  Found docker-compose.prod.yml at: $COMPOSE_DEPLOYED"
cp "$COMPOSE_DEPLOYED" "$APP_DIR/docker-compose.prod.yml"
echo "=== docker-compose.prod.yml installed ==="

# Create Docker network if not exists
docker network create menugreen-net 2>/dev/null || true

echo "=== Install Doppler CLI ==="
if ! command -v doppler &> /dev/null; then
  mkdir -p ~/.local/bin
  DOPPLER_VERSION="$(curl -fsSL https://api.github.com/repos/DopplerHQ/cli/releases/latest | jq -r .tag_name)"
  curl -fsSL "https://github.com/DopplerHQ/cli/releases/download/${DOPPLER_VERSION}/doppler_${DOPPLER_VERSION#v}_linux_amd64.tar.gz" -o /tmp/doppler.tar.gz
  tar -xzf /tmp/doppler.tar.gz -C ~/.local/bin doppler
  chmod +x ~/.local/bin/doppler
  rm -f /tmp/doppler.tar.gz
  export PATH="$HOME/.local/bin:$PATH"
else
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "=== Download secrets from Doppler ==="
doppler secrets download --token "$DOPPLER_TOKEN" --no-file --project menugreen --config prd --format env > /tmp/doppler_raw.env

# Build .env file
# TEMP: SHOW_DETAILED_ERRORS=true để debug 500 errors trong production
# TODO: Remove sau khi fix xong lỗi
printf 'ASPNETCORE_ENVIRONMENT=Production\nASPNETCORE_URLS=http://+:5000\nSHOW_DETAILED_ERRORS=true\n' > "$APP_DIR/.env"

# =================================================================
# Materialize Firebase Admin SDK credentials JSON on disk.
#
# The JSON file holds a private_key, so we MUST NOT commit it to git.
# Instead, we keep the full JSON body as a single multi-line Doppler
# secret named FIREBASE_CREDENTIALS_JSON. On each deploy we read it
# back and write it to $APP_DIR/firebase-adminsdk.json with mode 600,
# then docker-compose.prod.yml mounts that path read-only into the
# API container at /etc/secrets/firebase-adminsdk.json (the same path
# FIREBASE_CREDENTIAL_PATH below points at).
#
# Why materialize as a file instead of letting FirebaseAdmin read from
# an env var? Because the .NET SDK only accepts a file path
# (GoogleCredential.FromFile). Streaming the JSON via env would require
# changing C# code, which we want to avoid.
#
# Failure mode: if the Doppler secret is missing, the script aborts
# before pulling a new image. The previous container is still running,
# so traffic is unaffected. The next deploy attempt can fix the secret
# without manual rollback.
# =================================================================
echo "=== Materialize Firebase credentials JSON ==="
# Use `doppler secrets get ... --plain` instead of extracting from the
# bulk `--format env` download. Multi-line secrets (like our Firebase JSON)
# are fragile in --format env because Doppler wraps the value in "..." with
# embedded " escaped as \" and newline handling depends on the format
# version — even one missed un-escape leaves the PEM body on a single
# line and GoogleCredential.FromFile() crashes with:
#   System.ArgumentException: PKCS8 data must be contained within
#   '-----BEGIN PRIVATE KEY-----' and '-----END PRIVATE KEY-----'.
#
# `secrets get --plain` prints the raw secret value byte-for-byte (per
# Doppler docs: "Prints the value of a single secret to STDOUT"). The
# output is exactly the original JSON file content, no quote-wrapping,
# no \" or \\n escapes. We capture it, sanity-check it, and write to disk.
#
# Tradeoff: this triggers one extra Doppler CLI call (vs. parsing the
# bulk download). Cost is negligible (~100ms over LAN); clarity is worth it.
FIREBASE_JSON=""
if command -v doppler > /dev/null 2>&1; then
  FIREBASE_JSON="$(doppler secrets get FIREBASE_CREDENTIALS_JSON \
    --token "$DOPPLER_TOKEN" \
    --project menugreen \
    --config prd \
    --plain 2>/dev/null)"
fi
if [ -z "$FIREBASE_JSON" ]; then
  echo ">>> FATAL: FIREBASE_CREDENTIALS_JSON secret missing from Doppler (project=menugreen, config=prd)."
  echo ">>> Add it via: doppler secrets set FIREBASE_CREDENTIALS_JSON=\$(cat firebase-adminsdk.json) --project menugreen --config prd"
  echo ">>> (Use the JSON dump, NOT a file path.) Aborting deploy before pulling new image."
  exit 1
fi
echo "$FIREBASE_JSON" | sudo tee "$APP_DIR/firebase-adminsdk.json" > /dev/null
sudo chown root:root "$APP_DIR/firebase-adminsdk.json"
sudo chmod 600 "$APP_DIR/firebase-adminsdk.json"
# Sanity-check + re-serialize: even though `doppler secrets get --plain`
# returns the raw JSON byte-for-byte (no escaping), we still run a final
# verification before trusting the file. GoogleCredential.FromFile() uses
# BCL's RSA crypto which expects REAL newlines between the BEGIN/END
# markers in the PKCS8 PEM block. If those newlines are missing or are
# the literal two-char sequence `\n`, the runtime throws:
#   System.ArgumentException: PKCS8 data must be contained within
#   '-----BEGIN PRIVATE KEY-----' and '-----END PRIVATE KEY-----'.
# So: (1) json.load the file to parse it; (2) verify private_key actually
# has the expected markers around a newline; (3) write it back with
# json.dump(indent=2) so the on-disk JSON is canonical and the PEM is
# always human-readable. ANY failure aborts the deploy — much better
# than having the container crash-loop into 30 health-check failures.
#
# IMPORTANT: We use a file-based python script (not `python3 -` or heredoc)
# because (a) heredoc contents can collide with prior shell variables in
# this same script, and (b) `sudo python3 -` is unreliable across sudo
# versions. Writing to /tmp and running it directly is bulletproof.
#
# The heredoc tag is UNQUOTED (bare PYSCRIPT, no single quotes). Quoting
# it with 'PYSCRIPT' would prevent bash from expanding $APP_DIR and
# leave a literal "$APP_DIR" string in the Python script.
sudo tee /tmp/firebase_pem_check.py > /dev/null <<PYSCRIPT
import json, sys
path = "$APP_DIR/firebase-adminsdk.json"
try:
    with open(path) as f:
        data = json.load(f)
except Exception as e:
    sys.stderr.write("failed to parse JSON: %s\n" % e)
    sys.exit(2)
pk = data.get("private_key", "")
if "-----BEGIN" not in pk or "-----END" not in pk:
    sys.stderr.write("FATAL: private_key is missing BEGIN/END markers\n")
    sys.exit(3)
if "-----BEGIN PRIVATE KEY-----" not in pk:
    sys.stderr.write("FATAL: private_key does not contain '-----BEGIN PRIVATE KEY-----'\n")
    sys.exit(4)
# Verify real newlines sit between the BEGIN/END markers — otherwise
# GoogleCredential will crash with the exact same ArgumentException.
begin_idx = pk.index("-----BEGIN PRIVATE KEY-----")
end_idx   = pk.index("-----END PRIVATE KEY-----")
if begin_idx >= end_idx:
    sys.stderr.write("FATAL: BEGIN marker must appear before END marker in private_key\n")
    sys.exit(5)
body = pk[begin_idx:end_idx]
if "\n" not in body:
    sys.stderr.write(
        "FATAL: private_key PEM has no real newlines between BEGIN and END - "
        "GoogleCredential needs real \\n in the PEM body, not literal \\\\n.\n"
    )
    sys.exit(6)
# Re-serialize canonically so on-disk JSON is consistent and PEM is human-readable.
with open(path, "w") as f:
    json.dump(data, f, indent=2)
PYSCRIPT
if ! sudo python3 /tmp/firebase_pem_check.py; then
  echo ">>> FATAL: $APP_DIR/firebase-adminsdk.json failed sanity check (exit $?)"
  echo ">>> Aborting deploy before pulling new image."
  exit 1
fi
sudo rm -f /tmp/firebase_pem_check.py
echo "  ✓ Firebase credentials materialized (root:root, mode 600, valid JSON, real-PEM private_key)"

# Parse and add secrets - NOTE: Không skip DB_* keys để backup có thể đọc được
while IFS='=' read -r key raw_value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  [[ "$key" =~ [/[:space:]+] ]] && continue
  # FIX: Không skip DB_* và REDIS_* keys - chúng cần cho backup và kết nối
  [[ "$key" =~ ^(LIGHTSAIL_SSH_KEY=) ]] && continue
  # Skip the multi-line Firebase Admin SDK JSON. It's materialized to disk
  # via the FIREBASE_CREDENTIALS_JSON handler above (echo ... > json file),
  # NOT injected as an env var.
  #
  # Doppler --format env wraps a multi-line value in double quotes that
  # span several lines, e.g.:
  #   FIREBASE_CREDENTIALS_JSON="{
  #     \"type\": \"service_account\",
  #     ...
  #   }"
  # If we let those continuation lines fall through to the .env loop, each
  # one (e.g. the closing `}"` or `  \"private_key\": \"...\"`) gets echoed
  # verbatim into $APP_DIR/.env, which docker compose then refuses to parse
  # with:
  #   line N: unexpected character "}" in variable name "}="="
  # The previous fix only matched the header line, so the continuation
  # lines still leaked through. Now we require the key to look like a
  # real ALL-CAPS env identifier: any line that doesn't start with
  # [A-Z_][A-Z0-9_]*= (i.e. continuation of a quoted multi-line value,
  # blank lines, comments) is dropped.
  [[ ! "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] && continue
  # Strip ALL layers of leading/trailing double- or single-quotes. Doppler sometimes
  # emits values with nested quoting (e.g. ""5432"" on numeric secrets), which broke
  # the previous 4-line "%X / #X" dance that only removed one layer and caused
  # `pg_dump -p "$DB_PORT"` to choke on "5432". The `g` flag with `:s/["']//g` after
  # anchoring `^["']*` / `["']*$` makes this robust to 0, 1, or many quote layers.
  value="$(printf '%s' "$raw_value" | sed -E "s/^[\"']+//; s/[\"']+\$//")"
  net_key="${key//:/__}"
  echo "${net_key}=${value}" >> "$APP_DIR/.env"
done < /tmp/doppler_raw.env

# Add DB connection
DB_CONN="$(grep '^CONNECTIONSTRINGS__DEFAULTCONNECTION=' /tmp/doppler_raw.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
if [ -n "$DB_CONN" ]; then
  echo "ConnectionStrings__DefaultConnection=$DB_CONN" >> "$APP_DIR/.env"
fi

# Add JWT settings
JWT_SECRET="$(grep '^JWT_SECRET=' /tmp/doppler_raw.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
if [ -n "$JWT_SECRET" ]; then
  echo "JwtSettings__SecretKey=$JWT_SECRET" >> "$APP_DIR/.env"
else
  JWT_FALLBACK="$(grep '^JwtSettings__SecretKey=' /tmp/doppler_raw.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
  if [ -n "$JWT_FALLBACK" ]; then
    echo "JwtSettings__SecretKey=$JWT_FALLBACK" >> "$APP_DIR/.env"
  fi
fi

JWT_ISSUER="$(grep '^JWT_ISSUER=' /tmp/doppler_raw.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
[ -n "$JWT_ISSUER" ] && echo "JwtSettings__Issuer=$JWT_ISSUER" >> "$APP_DIR/.env"

JWT_AUDIENCE="$(grep '^JWT_AUDIENCE=' /tmp/doppler_raw.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
[ -n "$JWT_AUDIENCE" ] && echo "JwtSettings__Audience=$JWT_AUDIENCE" >> "$APP_DIR/.env"

# FIX: Thêm Redis connection string (Program.cs đọc REDIS_URL)
REDIS_HOST_VAL="$(grep '^REDIS_HOST=' /tmp/doppler_raw.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
REDIS_PORT_VAL="$(grep '^REDIS_PORT=' /tmp/doppler_raw.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/' | head -1)"
REDIS_PASSWORD_VAL="$(grep '^REDIS_PASSWORD=' /tmp/doppler_raw.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"

if [ -n "$REDIS_HOST_VAL" ]; then
  if [ -n "$REDIS_PASSWORD_VAL" ]; then
    echo "REDIS_URL=${REDIS_HOST_VAL}:${REDIS_PORT_VAL:-6379},password=${REDIS_PASSWORD_VAL}" >> "$APP_DIR/.env"
  else
    echo "REDIS_URL=${REDIS_HOST_VAL}:${REDIS_PORT_VAL:-6379}" >> "$APP_DIR/.env"
  fi
fi

# Lưu backup credentials vào file tạm để rollback dùng
echo "DB_HOST=$DB_HOST" > /tmp/rollback_db.env
echo "DB_PORT=$DB_PORT" >> /tmp/rollback_db.env
echo "DB_USER=$DB_USER" >> /tmp/rollback_db.env
echo "DB_PASSWORD=$DB_PASSWORD" >> /tmp/rollback_db.env
echo "DB_NAME=$DB_NAME" >> /tmp/rollback_db.env

rm -f /tmp/doppler_raw.env

echo "=== .env file created ==="

# Extract DB connection for backup
DB_HOST=$(grep '^DB_HOST=' "$APP_DIR/.env" | cut -d= -f2-)
DB_PORT=$(grep '^DB_PORT=' "$APP_DIR/.env" | cut -d= -f2-)
DB_USER=$(grep '^DB_USER=' "$APP_DIR/.env" | cut -d= -f2-)
DB_PASSWORD=$(grep '^DB_PASSWORD=' "$APP_DIR/.env" | cut -d= -f2-)
DB_NAME=$(grep '^DB_NAME=' "$APP_DIR/.env" | cut -d= -f2-)

# FIX: Backup database before deployment - FAIL = STOP DEPLOY
if [ -n "$DB_HOST" ] && [ -n "$DB_NAME" ]; then
  BACKUP_FILE="/tmp/menugreen_backup_$(date +%Y%m%d_%H%M%S).sql"
  echo "=== Starting database backup ==="
  PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USER" -d "$DB_NAME" -F p -f "$BACKUP_FILE" 2>&1
  BACKUP_EXIT_CODE=$?

  if [ $BACKUP_EXIT_CODE -ne 0 ]; then
    echo "FATAL: Backup failed with exit code $BACKUP_EXIT_CODE"
    echo "ABORTING DEPLOYMENT - Cannot rollback without valid backup!"
    echo "Please fix database connectivity and retry."
    exit 1
  fi

  echo "Backup saved to: $BACKUP_FILE"
  # Giữ lại 5 backup gần nhất
  ls -t /tmp/menugreen_backup_*.sql 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
else
  echo "WARNING: DB credentials not found in .env, skipping backup"
  echo "WARNING: Continuing deployment without backup capability!"
fi

# =================================================================
# CRITICAL PHASE BOUNDARY
# After this point, the old container can be torn down. If anything
# fails between here and the end of the script, the rollback trap
# (set further down) MUST bring the service back up — otherwise the
# old image is still tagged locally and we can recover without manual
# intervention.
# =================================================================
DEPLOY_PHASE_STARTED=1

# =================================================================
# FAIL-SAFE ROLLBACK TRAP
# If the script exits non-zero from any point after the old container
# has been (or is about to be) taken down — `set -e` would normally
# just bail out and leave the service DOWN — this trap intercepts the
# exit, runs the same three-tier rollback that the health-check path
# uses, and then re-exits with the original status.
#
# Why not just rely on the health-check `if [ "$HEALTH_PASSED" = false ]`
# block? Because that path only triggers when the new container is
# RUNNING but its /health/ready keeps returning non-2xx. If the new
# container crashes immediately (port collision, missing env, OOM,
# bad image manifest, etc.), the loop at line ~281 may never observe
# it as "running", and `set -e` propagates the failure out of the
# script BEFORE we ever reach the health check — leaving no service.
#
# The EXIT trap catches ANY exit (success or failure) between
# DEPLOY_PHASE_STARTED=1 and the end of the script. The body only
# runs rollback if exit code is non-zero AND the trap hasn't already
# run (ROLLBACK_DONE guards against double execution).
# =================================================================
ROLLBACK_TRIGGERED_BY_TRAP=0
deploy_rollback_trap() {
  local exit_code=$?
  # Only act on failures after we've entered the deploy phase.
  if [ "$exit_code" -eq 0 ] || [ "${DEPLOY_PHASE_STARTED:-0}" -ne 1 ]; then
    return
  fi
  # If the health-check rollback path already ran, don't double-rollback.
  if [ "${ROLLBACK_DONE:-0}" -eq 1 ]; then
    return
  fi
  echo "=========================================="
  echo ">>> FAIL-SAFE TRAP: deploy phase exited with code $exit_code"
  echo ">>> Attempting automatic rollback to previous image..."
  echo "=========================================="
  if declare -F perform_rollback > /dev/null; then
    perform_rollback
    local rb=$?
    if [ $rb -ne 0 ]; then
      echo ">>> FAIL-SAFE TRAP: rollback itself failed (code $rb)"
    fi
  else
    echo ">>> perform_rollback not yet defined — rollback skipped"
  fi
  # Re-exit with the ORIGINAL failure code so the GH Action still shows
  # failed and an operator is paged — even though the service may be back.
  exit $exit_code
}
trap deploy_rollback_trap EXIT

# Save previous running image locally for rollback BEFORE pulling new one
# - Uses local tag only (no Docker Hub round-trip, no push required,
#   no rate-limit risk, no scope concern).
# - We tag from `menugreen_api` (the in-use tag pointing at the
#   running image) rather than `$IMAGE:main` because after a previous
#   rollback the local `$IMAGE:main` may equal the just-rolled-back
#   image. `menugreen_api` is the source of truth for what's running.
# - If no container is currently using `menugreen_api` (cold deploy),
#   we skip the tag (nothing to roll back to).
# =================================================================
echo "=== Save previous image locally for rollback ==="
if docker inspect menugreen_api > /dev/null 2>&1; then
  ROLLBACK_LOCAL_TAG="menugreen_api:rollback-local-$(date +%s)"
  sudo docker tag menugreen_api "$ROLLBACK_LOCAL_TAG" || echo "  ! Could not tag previous image (non-fatal)"
  echo "  ✓ Saved rollback image as $ROLLBACK_LOCAL_TAG"
else
  echo "  ⊘ No existing menugreen_api image found, skipping rollback save (cold deploy)"
fi

echo "=== Pull latest image ==="
# Retry loop: even on a "fresh" deploy host, the first `docker pull` after
# `docker image prune` (step 6) sometimes fails with a containerd attestation
# commit error:
#   failed commit on ref "attestation-sha256:...": rename .../data .../blobs/...
#   no such file or directory
# That's because Buildx v6 pushes provenance + SBOM attestations by default
# (see backend-ci.yml where we now disable them), and the containerd ingest
# dir is briefly inconsistent during prune. Retry up to 3 times; if that
# still fails, also restart containerd to force a clean state and try once
# more. We do NOT swallow the final failure — if the pull never succeeds,
# the deploy must abort so CD can roll back via the previous image.
PULL_OK=0
for attempt in 1 2 3; do
  if sudo docker pull "$IMAGE:main" 2>&1 | tail -5; then
    PULL_OK=1
    break
  fi
  echo "  ! Pull attempt $attempt failed, retrying in 5s..."
  sleep 5
done
if [ "$PULL_OK" = "0" ]; then
  echo "  ! Pull still failing after 3 attempts — restarting containerd and trying once more"
  sudo systemctl restart containerd 2>/dev/null || sudo systemctl restart docker 2>/dev/null || true
  sleep 5
  sudo docker pull "$IMAGE:main" || { echo "Failed to pull image $IMAGE:main"; exit 1; }
fi

echo "=== Tag image for local use ==="
sudo docker tag $IMAGE:main menugreen_api

echo "=== Reset EF Migration History (fix model mismatch) ==="
DB_CONN_PRECHECK=$(grep '^ConnectionStrings__DefaultConnection=' "$APP_DIR/.env" | cut -d= -f2-)
if [ -n "$DB_CONN_PRECHECK" ]; then
  PGPASSWORD_PRECHECK=$(echo "$DB_CONN_PRECHECK" | grep -oP 'Password=\K[^;]+' || true)
  DB_HOST_PRECHECK=$(echo "$DB_CONN_PRECHECK" | grep -oP 'Host=\K[^;]+' || true)
  DB_USER_PRECHECK=$(echo "$DB_CONN_PRECHECK" | grep -oP 'Username=\K[^;]+' || echo "$DB_CONN_PRECHECK" | grep -oP 'User Id=\K[^;]+' || true)
  DB_NAME_PRECHECK=$(echo "$DB_CONN_PRECHECK" | grep -oP 'Database=\K[^;]+' || true)
  
  if [ -n "$DB_HOST_PRECHECK" ] && [ -n "$DB_NAME_PRECHECK" ]; then
    MIGRATION_COUNT=$(PGPASSWORD="$PGPASSWORD_PRECHECK" psql -h "$DB_HOST_PRECHECK" -U "$DB_USER_PRECHECK" -d "$DB_NAME_PRECHECK" -tAc "SELECT COUNT(*) FROM \"__EFMigrationsHistory\";" 2>/dev/null || echo "0")
    MIGRATION_COUNT=$(echo "$MIGRATION_COUNT" | tr -d '[:space:]')
    
    if [ "$MIGRATION_COUNT" -gt "0" ]; then
      echo "  Found $MIGRATION_COUNT migration(s) in history, clearing for fresh migration..."
      PGPASSWORD="$PGPASSWORD_PRECHECK" psql -h "$DB_HOST_PRECHECK" -U "$DB_USER_PRECHECK" -d "$DB_NAME_PRECHECK" -c "DELETE FROM \"__EFMigrationsHistory\";" 2>/dev/null || true
      echo "  ✓ Migration history cleared"
    else
      echo "  ⊘ No existing migrations in history"
    fi
  fi
fi

echo "=== Stop and remove all existing containers ==="
docker compose -f "$APP_DIR/docker-compose.prod.yml" down --remove-orphans 2>/dev/null || true
docker stop menugreen_api 2>/dev/null || true
docker rm menugreen_api 2>/dev/null || true

# NOTE: We intentionally do NOT remove the local $IMAGE:main image
# or the rollback-local-* tag here. Keeping them cached lets the
# rollback path fall back to a local tag if Docker Hub is
# unreachable during a deploy-time incident. Docker's layer cache
# is shared across tags, so this costs no extra disk per tag.

echo "=== Start API container ==="
# Wrap `up -d` so a failure here doesn't immediately kill the script
# (which would leave us with the old container already stopped and no
# new one running — i.e. service DOWN). With `|| UP_FAILED=1`, set -e
# doesn't exit, the script continues, health check will fail, and the
# EXIT trap will run perform_rollback() to bring the old image back.
docker compose -f "$APP_DIR/docker-compose.prod.yml" up -d || UP_FAILED=1

if [ "${UP_FAILED:-0}" -eq 1 ]; then
  echo ">>> docker compose up failed — skipping readiness loop, will go to health check"
else
  echo "=== Waiting for container to be ready ==="
  for i in $(seq 1 15); do
    if docker ps --filter "name=menugreen_api" --filter "status=running" | grep -q menugreen_api; then
      echo "Container is running!"
      break
    fi
    echo "Waiting for container... ($i/15)"
    sleep 2
  done
fi

# Wait for app to start and auto-migrate (migration is now handled by the app on startup)
echo "=== Waiting for app startup and auto-migration (max 45 seconds) ==="
sleep 15
echo "App should have auto-migrated on startup."

# Verify tables exist
echo "Checking database tables..."
DB_CONN=$(grep '^ConnectionStrings__DefaultConnection=' "$APP_DIR/.env" | cut -d= -f2-)
if [ -n "$DB_CONN" ]; then
  PGPASSWORD=$(echo "$DB_CONN" | grep -oP 'Password=\K[^;]+' || true)
  DB_HOST=$(echo "$DB_CONN" | grep -oP 'Host=\K[^;]+' || true)
  DB_USER=$(echo "$DB_CONN" | grep -oP 'Username=\K[^;]+' || echo "$DB_CONN" | grep -oP 'User Id=\K[^;]+' || true)
  DB_NAME=$(echo "$DB_CONN" | grep -oP 'Database=\K[^;]+' || true)

  if [ -n "$DB_HOST" ] && [ -n "$DB_NAME" ]; then
    TABLE_COUNT=$(PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" 2>/dev/null || echo "0")
    echo "Found $TABLE_COUNT tables in database '$DB_NAME'"

    # NOTE: Previously this branch called `exit 1` on TABLE_COUNT=0, which
    # bypassed the health-check loop and rollback path entirely. Now we
    # just log the situation and let the health check be the gatekeeper:
    # if migration truly failed, /health/ready will return non-2xx and the
    # rollback (or fail-safe EXIT trap) will fire. If the DB just hasn't
    # fully migrated yet but the app can still serve traffic, we let it
    # run rather than tearing down a working service.
    if [ "$TABLE_COUNT" -eq "0" ]; then
      echo ">>> WARNING: No tables found yet. Will let health check decide."
    fi
  fi
fi

echo "=== Waiting for health check (max 30 attempts) ==="
HEALTH_PASSED=false
for i in $(seq 1 30); do
  if curl -sf "http://localhost:5000/health/ready" > /dev/null 2>&1; then
    echo "Health check passed!"
    HEALTH_PASSED=true
    break
  fi
  echo "Waiting for health check... ($i/30)"
  sleep 2
done

# Disable the EXIT-trap rollback while we run the health-check path
# ourselves — we don't want the trap to also run rollback after we exit 1.
trap - EXIT

# =================================================================
# ROLLBACK MECHANISM (wrapped as a function so the EXIT trap can
# invoke the same logic on unexpected failures).
#
# Priority order:
#   1. Local rollback-local-* tag (fastest, no network)
#   2. Docker Hub :previous tag (legacy fallback, may not exist
#      after Fix 1 deployment but kept for backward compat)
#   3. Pull from Hub by SHA tag (e.g. main-<oldsha>) - last resort
#
# `ROLLBACK_DONE` guards against double-execution when both the
# health-check path and the EXIT trap want to rollback.
# =================================================================
perform_rollback() {
  if [ "${ROLLBACK_DONE:-0}" -eq 1 ]; then
    echo ">>> Rollback already in progress or completed, skipping"
    return
  fi
  ROLLBACK_DONE=1

  echo ">>> Initiating rollback..."

  echo ">>> Logging failed container..."
  docker compose -f "$APP_DIR/docker-compose.prod.yml" logs --tail=50 2>/dev/null || true

  echo ">>> Stopping current containers..."
  docker compose -f "$APP_DIR/docker-compose.prod.yml" down 2>/dev/null || true

  # ----- Pick rollback image -----
  ROLLBACK_IMAGE_TAG=""
  ROLLBACK_SOURCE=""

  # 1. Try local rollback-local-* (preferred)
  ROLLBACK_IMAGE_TAG=$(sudo docker images --format "{{.Repository}}:{{.Tag}}" \
    | grep "^menugreen_api:rollback-local-" \
    | sort -r | head -1 || true)
  if [ -n "$ROLLBACK_IMAGE_TAG" ]; then
    ROLLBACK_SOURCE="local-rollback-tag"
    echo ">>> Found local rollback image: $ROLLBACK_IMAGE_TAG"
  fi

  # 2. Try legacy :previous tag on Hub (may not exist anymore)
  if [ -z "$ROLLBACK_IMAGE_TAG" ]; then
    echo ">>> No local rollback tag found, trying $IMAGE:previous..."
    if sudo docker pull "$IMAGE:previous" 2>/dev/null; then
      ROLLBACK_IMAGE_TAG="$IMAGE:previous"
      ROLLBACK_SOURCE="hub-previous"
      echo ">>> Pulled $IMAGE:previous"
    fi
  fi

  # 3. Last resort: pull from Hub by SHA tag
  if [ -z "$ROLLBACK_IMAGE_TAG" ]; then
    echo ">>> No $IMAGE:previous, trying $IMAGE:main-<oldsha> from Hub..."
    FALLBACK_SHA=$(sudo docker images --format "{{.Tag}}" \
      | grep -E "^main-[0-9a-f]{7}$" \
      | sort -r | head -1 || true)
    if [ -n "$FALLBACK_SHA" ] && sudo docker pull "$IMAGE:$FALLBACK_SHA" 2>/dev/null; then
      ROLLBACK_IMAGE_TAG="$IMAGE:$FALLBACK_SHA"
      ROLLBACK_SOURCE="hub-sha-fallback"
      echo ">>> Pulled $IMAGE:$FALLBACK_SHA as fallback"
    fi
  fi

  if [ -z "$ROLLBACK_IMAGE_TAG" ]; then
    echo ">>> FATAL: No rollback image available (local, :previous, or :main-<sha>)"
    echo ">>> Manual recovery required. Service is DOWN."
    echo ">>> Container state preserved for debugging."
    return 1
  fi

  echo ">>> Re-fetching Doppler secrets for rollback..."
  doppler secrets download --token "$DOPPLER_TOKEN" --no-file --project menugreen --config prd --format env > /tmp/doppler_rollback.env

  printf 'ASPNETCORE_ENVIRONMENT=Production\nASPNETCORE_URLS=http://+:5000\n' > "$APP_DIR/.env"

  # Re-materialize Firebase JSON from Doppler (in case it changed since the
  # failed deploy). Same validation as the main path so rollback doesn't
  # come back up with a broken Firebase app. Mirror the same line-based
  # quoted-value extractor as the main path (see comment block there).
  FIREBASE_JSON_ROLLBACK="$(python3 -c '
import re, sys
path = "/tmp/doppler_rollback.env"
with open(path) as f:
    lines = f.read().split("\n")
for i, line in enumerate(lines):
    if line.startswith("FIREBASE_CREDENTIALS_JSON="):
        collected = [line[len("FIREBASE_CREDENTIALS_JSON="):]]
        j = i + 1
        while j < len(lines):
            collected.append(lines[j])
            joined = "\n".join(collected)
            if lines[j].endswith(chr(34)) or lines[j] == chr(34) or lines[j].endswith(chr(125) + chr(34)):
                stripped = joined.replace(chr(92) + chr(34), "")
                if stripped.count(chr(34)) % 2 == 0:
                    break
            j += 1
        joined = "\n".join(collected)
        if joined.startswith(chr(34)) and joined.endswith(chr(34)):
            joined = joined[1:-1]
        sys.stdout.write(joined.replace(chr(92) + chr(34), chr(34)))
        break
')"
  if [ -n "$FIREBASE_JSON_ROLLBACK" ]; then
    echo "$FIREBASE_JSON_ROLLBACK" | sudo tee "$APP_DIR/firebase-adminsdk.json" > /dev/null
    sudo chown root:root "$APP_DIR/firebase-adminsdk.json"
    sudo chmod 600 "$APP_DIR/firebase-adminsdk.json"
    echo ">>> Firebase credentials re-materialized for rollback"
  else
    echo ">>> WARNING: FIREBASE_CREDENTIALS_JSON missing — rollback container will run without Firebase (Google sign-in / FCM disabled)"
  fi

  while IFS='=' read -r key raw_value; do
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    [[ "$key" =~ [/[:space:]+] ]] && continue
    [[ "$key" =~ ^(LIGHTSAIL_SSH_KEY=) ]] && continue
  # Skip the multi-line Firebase Admin SDK JSON. It's materialized to disk
  # via the FIREBASE_CREDENTIALS_JSON handler above (echo ... > json file),
  # NOT injected as an env var. Same whitelist logic as the main path:
  # any line whose "key" doesn't look like a real ALL-CAPS env identifier
  # (i.e. continuation of a quoted multi-line value, blank line, comment)
  # is dropped — otherwise the closing `}"` of the JSON leaks into the
  # .env file and docker compose fails to parse it.
  [[ ! "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] && continue
    value="$(printf '%s' "$raw_value" | sed -E "s/^[\"']+//; s/[\"']+\$//")"
    net_key="${key//:/__}"
    echo "${net_key}=${value}" >> "$APP_DIR/.env"
  done < /tmp/doppler_rollback.env

  DB_CONN_ROLLBACK="$(grep '^CONNECTIONSTRINGS__DEFAULTCONNECTION=' /tmp/doppler_rollback.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
  [ -n "$DB_CONN_ROLLBACK" ] && echo "ConnectionStrings__DefaultConnection=$DB_CONN_ROLLBACK" >> "$APP_DIR/.env"

  JWT_SECRET_ROLLBACK="$(grep '^JWT_SECRET=' /tmp/doppler_rollback.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
  [ -n "$JWT_SECRET_ROLLBACK" ] && echo "JwtSettings__SecretKey=$JWT_SECRET_ROLLBACK" >> "$APP_DIR/.env"

  JWT_ISSUER_ROLLBACK="$(grep '^JWT_ISSUER=' /tmp/doppler_rollback.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
  [ -n "$JWT_ISSUER_ROLLBACK" ] && echo "JwtSettings__Issuer=$JWT_ISSUER_ROLLBACK" >> "$APP_DIR/.env"

  JWT_AUDIENCE_ROLLBACK="$(grep '^JWT_AUDIENCE=' /tmp/doppler_rollback.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
  [ -n "$JWT_AUDIENCE_ROLLBACK" ] && echo "JwtSettings__Audience=$JWT_AUDIENCE_ROLLBACK" >> "$APP_DIR/.env"

  REDIS_HOST_ROLLBACK="$(grep '^REDIS_HOST=' /tmp/doppler_rollback.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
  REDIS_PORT_ROLLBACK="$(grep '^REDIS_PORT=' /tmp/doppler_rollback.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/' | head -1)"
  REDIS_PASSWORD_ROLLBACK="$(grep '^REDIS_PASSWORD=' /tmp/doppler_rollback.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"

  if [ -n "$REDIS_HOST_ROLLBACK" ]; then
    if [ -n "$REDIS_PASSWORD_ROLLBACK" ]; then
      echo "REDIS_URL=${REDIS_HOST_ROLLBACK}:${REDIS_PORT_ROLLBACK:-6379},password=${REDIS_PASSWORD_ROLLBACK}" >> "$APP_DIR/.env"
    else
      echo "REDIS_URL=${REDIS_HOST_ROLLBACK}:${REDIS_PORT_ROLLBACK:-6379}" >> "$APP_DIR/.env"
    fi
  fi

  rm -f /tmp/doppler_rollback.env
  echo ">>> .env restored for rollback"

  sudo docker tag "$ROLLBACK_IMAGE_TAG" menugreen_api
  echo ">>> Tagged $ROLLBACK_IMAGE_TAG as menugreen_api for rollback (source: $ROLLBACK_SOURCE)"

  echo ">>> Starting previous container with docker compose..."
  if ! docker compose -f "$APP_DIR/docker-compose.prod.yml" up -d 2>&1; then
    echo ">>> Failed to start previous container with compose, trying docker run..."
    if ! sudo docker run -d \
      --name menugreen_api \
      -p 5000:5000 \
      --env-file "$APP_DIR/.env" \
      --network menugreen-net \
      menugreen_api 2>&1; then
      echo ">>> FATAL: Failed to start previous container"
      echo ">>> Service is DOWN. Manual recovery required."
      return 1
    fi
  fi

  echo ">>> Waiting for rollback container to start..."
  sleep 10
  docker ps --filter "name=menugreen_api"

  echo ">>> Verifying rollback health check..."
  ROLLBACK_HEALTHY=false
  for i in $(seq 1 15); do
    if curl -sf "http://localhost:5000/health/live" > /dev/null 2>&1; then
      echo ">>> Rollback container is responding on /health/live"
      ROLLBACK_HEALTHY=true
      break
    fi
    echo ">>> Waiting for rollback health... ($i/15)"
    sleep 2
  done

  if [ "$ROLLBACK_HEALTHY" = false ]; then
    echo ">>> WARNING: Rollback container started but /health/live is not responding"
    echo ">>> Container state preserved for manual inspection"
    return 1
  fi

  echo ">>> Rollback verified healthy. Service restored."
  return 0
}

if [ "$HEALTH_PASSED" = false ]; then
  echo ">>> Health check failed after 30 attempts, initiating rollback..."
  perform_rollback || true
  # Always exit 1 so the GitHub Action is marked failed and an
  # operator is notified — but the service should be back up.
  exit 1
fi

echo "=== Verify containers ==="
docker compose -f "$APP_DIR/docker-compose.prod.yml" ps

# =================================================================
# PRUNE UNUSED IMAGES - Keep only:
#   - $IMAGE:main, $IMAGE:latest, $IMAGE:$SHA  (current)
#   - $IMAGE:previous                            (legacy hub tag, kept for backward compat)
#   - menugreen_api:rollback-local-*             (rollback safety net)
# =================================================================
echo "=== Pruning unused Docker images ==="
sudo docker images "$IMAGE" --format "{{.Repository}}:{{.Tag}}" \
  | grep -v -E "(:main|:latest|:previous|:$SHA|:main-[0-9a-f]{7}$)" \
  | xargs -r sudo docker rmi -f || true

# Also prune menugreen_api:* tags not in use, except rollback-local-*
sudo docker images "menugreen_api" --format "{{.Repository}}:{{.Tag}}" \
  | grep -v -E "(^menugreen_api:rollback-local-|^menugreen_api:latest$)" \
  | xargs -r sudo docker rmi -f || true

echo "=== Final disk space check ==="
df -h

echo "=== Deployment complete successfully! ==="
