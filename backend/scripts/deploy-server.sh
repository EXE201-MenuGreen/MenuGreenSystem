#!/usr/bin/env bash
# deploy-server.sh
# -----------------------------------------------------------------------------
# Server-side deploy script. Invoked by .github/workflows/backend-cd.yml via
# appleboy/ssh-action. Lives outside the workflow file because GitHub Actions
# caps each ${{ }} expression at 21,000 characters — and an inline script: of
# this size blew past that limit on line 69 of backend-cd.yml.
#
# Invocation (from CI):
#   sudo bash /tmp/nginx-deploy/deploy-server.sh
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

# Docker compose config (base64 encoded) - NO REDIS
COMPOSE_B64='c2VydmljZXM6DQogIGFwaToNCiAgICBpbWFnZTogZG9ja2VyLmlvL2FuaHR1YW4yMTExMjAwNC9tZW51Z3JlZW5zeXN0ZW06bGF0ZXN0DQogICAgY29udGFpbmVyX25hbWU6IG1lbnVncmVlbl9hcGkNCiAgICBwdWxsX3BvbGljeTogYWx3YXlzDQogICAgZW52X2ZpbGU6DQogICAgICAtIC5lbnYNCiAgICBlbnZpcm9ubWVudDoNCiAgICAgIC0gQVNQTkVUQ09SRV9FTlZJUk9OTUVOVD0ke0FTUE5FVENPUkVfRU5WSVJPTk1FTlR9DQogICAgICAtIEFTUE5FVENPUkVfVVJMUz1odHRwOi8vKzo1MDAwDQogICAgcG9ydHM6DQogICAgICAtICI1MDAwOjUwMDAiDQogICAgbmV0d29ya3M6DQogICAgICAtIG1lbnVncmVlbi1uZXQNCiAgICByZXN0YXJ0OiB1bmxlc3Mtc3RvcHBlZA0KICAgIGhlYWx0aGNoZWNrOg0KICAgICAgdGVzdDogWyJDTUQiLCAiY3VybCIsICItZiIsICJodHRwOi8vbG9jYWxob3N0OjUwMDAvaGVhbHRoL2xpdmUiXQ0KICAgICAgaW50ZXJ2YWw6IDMwcw0KICAgICAgdGltZW91dDogMTBzDQogICAgICByZXRyaWVzOiAzDQogICAgICBzdGFydF9wZXJpb2Q6IDQwcw0KICAgIGRlcGxveToNCiAgICAgIHJlc291cmNlczoNCiAgICAgICAgbGltaXRzOg0KICAgICAgICAgIG1lbW9yeTogODAwTQ0KICAgICAgICAgIGNwdXM6ICcxLjAnDQogICAgdm9sdW1lczogW10NCg0KbmV0d29ya3M6DQogIG1lbnVncmVlbi1uZXQ6DQogICAgZXh0ZXJuYWw6IHRydWUNCg=='

echo "$COMPOSE_B64" | base64 -d > "$APP_DIR/docker-compose.prod.yml"

echo "=== docker-compose.prod.yml uploaded (NO REDIS) ==="

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

# Parse and add secrets - NOTE: Không skip DB_* keys để backup có thể đọc được
while IFS='=' read -r key raw_value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  [[ "$key" =~ [/[:space:]+] ]] && continue
  # FIX: Không skip DB_* và REDIS_* keys - chúng cần cho backup và kết nối
  [[ "$key" =~ ^(LIGHTSAIL_SSH_KEY=) ]] && continue
  value="${raw_value%\"}"
  value="${value#\"}"
  value="${raw_value%\'}"
  value="${value#\'}"
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
sudo docker pull $IMAGE:main || { echo "Failed to pull image $IMAGE:main"; exit 1; }

echo "=== Tag image for local use ==="
sudo docker tag $IMAGE:main menugreen_api

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
docker compose -f "$APP_DIR/docker-compose.prod.yml" up -d

echo "=== Waiting for container to be ready ==="
for i in $(seq 1 15); do
  if docker ps --filter "name=menugreen_api" --filter "status=running" | grep -q menugreen_api; then
    echo "Container is running!"
    break
  fi
  echo "Waiting for container... ($i/15)"
  sleep 2
done

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

    if [ "$TABLE_COUNT" -eq "0" ]; then
      echo "FATAL: No tables found after migration!"
      exit 1
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

# =================================================================
# ROLLBACK MECHANISM - If health check fails
# Priority order:
#   1. Local rollback-local-* tag (fastest, no network)
#   2. Docker Hub :previous tag (legacy fallback, may not exist
#      after Fix 1 deployment but kept for backward compat)
#   3. Pull from Hub by SHA tag (e.g. main-<oldsha>) - last resort
# =================================================================
if [ "$HEALTH_PASSED" = false ]; then
  echo ">>> Health check failed after 30 attempts, initiating rollback..."

  echo ">>> Logging failed container..."
  docker compose -f "$APP_DIR/docker-compose.prod.yml" logs --tail=50

  echo ">>> Stopping current containers..."
  docker compose -f "$APP_DIR/docker-compose.prod.yml" down || true

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
    if sudo docker pull $IMAGE:previous 2>/dev/null; then
      ROLLBACK_IMAGE_TAG="$IMAGE:previous"
      ROLLBACK_SOURCE="hub-previous"
      echo ">>> Pulled $IMAGE:previous"
    fi
  fi

  # 3. Last resort: pull from Hub by SHA tag
  if [ -z "$ROLLBACK_IMAGE_TAG" ]; then
    echo ">>> No $IMAGE:previous, trying $IMAGE:main-<oldsha> from Hub..."
    # The :$SHA tag from CI is the build that just failed; we want
    # the SHA from the previous deploy. The previous :$SHA is one
    # we just pulled $IMAGE:main from, but if main also failed we
    # can't trust it. Fall back to any cached hub-<sha> image we have.
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
    exit 1
  fi

  echo ">>> Re-fetching Doppler secrets for rollback..."
  doppler secrets download --token "$DOPPLER_TOKEN" --no-file --project menugreen --config prd --format env > /tmp/doppler_rollback.env

  # FIX: Tạo .env rollback đúng format như deploy
  printf 'ASPNETCORE_ENVIRONMENT=Production\nASPNETCORE_URLS=http://+:5000\n' > "$APP_DIR/.env"

  while IFS='=' read -r key raw_value; do
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    [[ "$key" =~ [/[:space:]+] ]] && continue
    [[ "$key" =~ ^(LIGHTSAIL_SSH_KEY=) ]] && continue
    value="${raw_value%\"}"
    value="${value#\"}"
    value="${raw_value%\'}"
    value="${value#\'}"
    net_key="${key//:/__}"
    echo "${net_key}=${value}" >> "$APP_DIR/.env"
  done < /tmp/doppler_rollback.env

  # Add DB connection
  DB_CONN_ROLLBACK="$(grep '^CONNECTIONSTRINGS__DEFAULTCONNECTION=' /tmp/doppler_rollback.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
  [ -n "$DB_CONN_ROLLBACK" ] && echo "ConnectionStrings__DefaultConnection=$DB_CONN_ROLLBACK" >> "$APP_DIR/.env"

  # Add JWT settings
  JWT_SECRET_ROLLBACK="$(grep '^JWT_SECRET=' /tmp/doppler_rollback.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
  [ -n "$JWT_SECRET_ROLLBACK" ] && echo "JwtSettings__SecretKey=$JWT_SECRET_ROLLBACK" >> "$APP_DIR/.env"

  JWT_ISSUER_ROLLBACK="$(grep '^JWT_ISSUER=' /tmp/doppler_rollback.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
  [ -n "$JWT_ISSUER_ROLLBACK" ] && echo "JwtSettings__Issuer=$JWT_ISSUER_ROLLBACK" >> "$APP_DIR/.env"

  JWT_AUDIENCE_ROLLBACK="$(grep '^JWT_AUDIENCE=' /tmp/doppler_rollback.env | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/')"
  [ -n "$JWT_AUDIENCE_ROLLBACK" ] && echo "JwtSettings__Audience=$JWT_AUDIENCE_ROLLBACK" >> "$APP_DIR/.env"

  # Add Redis connection
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

  # Tag the chosen rollback image so compose / docker run can find it
  sudo docker tag "$ROLLBACK_IMAGE_TAG" menugreen_api
  echo ">>> Tagged $ROLLBACK_IMAGE_TAG as menugreen_api for rollback (source: $ROLLBACK_SOURCE)"

  echo ">>> Starting previous container with docker compose..."
  docker compose -f "$APP_DIR/docker-compose.prod.yml" up -d || {
    echo ">>> Failed to start previous container with compose, trying docker run..."
    sudo docker run -d \
      --name menugreen_api \
      -p 5000:5000 \
      --env-file "$APP_DIR/.env" \
      --network menugreen-net \
      menugreen_api || {
      echo ">>> FATAL: Failed to start previous container"
      echo ">>> Service is DOWN. Manual recovery required."
      exit 1
    }
  }

  echo ">>> Waiting for rollback container to start..."
  sleep 10
  docker ps --filter "name=menugreen_api"

  # Verify rollback container is actually healthy
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
  else
    echo ">>> Rollback verified healthy. Service restored."
  fi

  # Always exit 1 so the GitHub Action is marked failed and an
  # operator is notified — but the service is back up.
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
