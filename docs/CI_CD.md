# CI/CD Pipeline Guide - MenuGreen System

**Last updated:** 2026-07-05

---

## Overview

MenuGreen sử dụng GitHub Actions để tự động hóa CI/CD pipeline:
- Build & Test .NET
- Build Docker image
- Deploy lên AWS Lightsail

---

## Pipeline Flow

```
Git Push → GitHub Actions → Docker Hub → Server Deploy
                                              │
                                              ▼
                                    ┌─────────────────┐
                                    │ 1. SSH to Server│
                                    │ 2. Pull .env    │
                                    │    from Doppler │
                                    └────────┬────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ 3. Backup DB    │ ← pg_dump
                                    └────────┬────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ 4. Pull Image   │
                                    └────────┬────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ 5. EF Migration │
                                    └────────┬────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ 6. Health Check │
                                    └─────────────────┘
```

---

## GitHub Secrets

### Required

| Secret | Description | Example |
|--------|-------------|---------|
| `DOPPLER_TOKEN` | Doppler production config token | `dp.prd.xxx` |
| `LIGHTSAIL_HOST` | Server IP | `52.77.218.100` |
| `LIGHTSAIL_USER` | SSH user | `ubuntu` |
| `LIGHTSAIL_SSH_KEY` | SSH private key | `-----BEGIN...` |

### Optional

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | `anhtuan21112004` |
| `DOCKERHUB_TOKEN` | Docker Hub access token |

### Setup Guide

See: [GITHUB_SECRETS_SETUP.md](./GITHUB_SECRETS_SETUP.md)

---

## Server Information

| Property | Value |
|----------|-------|
| **SSH** | `ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100` |
| **App Location** | `~/apps/MenuGreenSystem` |
| **Docker Image** | `anhtuan21112004/menugreensystem:latest` |
| **API Port** | 5000 |
| **OS** | Ubuntu 22.04 LTS |

---

## Deployment Commands

```bash
# SSH to server
ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100

# Check container status
docker ps

# View API logs
docker logs menugreen_api --tail 50 -f

# Restart API
docker restart menugreen_api

# Pull latest image manually
docker pull anhtuan21112004/menugreensystem:latest
docker compose -f docker-compose.prod.yml up -d api

# Database backup
pg_dump -h menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com \
  -U postgres -d menugreendb -F p -f backup.sql

# Navigate to app
cd ~/apps/MenuGreenSystem
```

---

## Database Migration

### Automatic (via CI/CD)

CI/CD pipeline tự động chạy migration khi deploy:
1. Backup database với `pg_dump`
2. Run `dotnet ef database update`
3. Nếu fail → rollback, không start API

### Manual

```bash
# SSH vào server
ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100

# Backup trước
pg_dump -h menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com \
  -U postgres -d menugreendb -F p -f backup_$(date +%Y%m%d_%H%M%S).sql

# Run migration
docker exec menugreen_api dotnet ef database update \
  --project backend/MenuGreen.DataAccessLayer/MenuGreen.DataAccessLayer.csproj \
  --startup-project backend/MenuGreen.API/MenuGreen.API.csproj
```

---

## Health Check

### Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Full health check (DB + Redis) |
| `GET /health/ready` | Readiness check |
| `GET /health/live` | Liveness check |

### Test

```bash
curl https://api.menugreen.food/health
```

---

## Rollback Plan

### If Migration Fail

1. SSH vào server
2. Restore từ backup:
   ```bash
   psql -h menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com \
     -U postgres -d menugreendb < backup.sql
   ```
3. Pull image version cũ
4. Không start API cho đến khi fix xong

### If Deployment Fail

1. SSH vào server
2. Stop current: `docker compose -f docker-compose.prod.yml down`
3. Pull image cũ: `docker pull docker.io/anhtuan21112004/menugreensystem:<previous-tag>`
4. Start: `docker compose -f docker-compose.prod.yml up -d`
5. Verify health check

---

## Docker Compose Production

```bash
# Build & Start
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Stop
docker-compose -f docker-compose.prod.yml down
```

---

## Nginx Configuration

API được proxy qua Nginx với CORS headers:

```nginx
# /etc/nginx/sites-available/api.menugreen.food

# Preflight OPTIONS
if ($request_method = 'OPTIONS') {
    add_header 'Access-Control-Allow-Origin' 'https://www.menugreen.food' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, Accept, Origin, X-Requested-With' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    add_header 'Access-Control-Max-Age' 86400;
    add_header 'Content-Type' 'text/plain; charset=utf-8';
    add_header 'Content-Length' 0;
    return 204;
}

# Normal requests
add_header 'Access-Control-Allow-Origin' 'https://www.menugreen.food' always;
add_header 'Access-Control-Allow-Credentials' 'true' always;
```

### Reload Nginx

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## Troubleshooting

### Build Failures

```bash
# Check network connectivity
curl -s https://api.nuget.org/v3/index.json | head

# Clear NuGet cache
dotnet nuget locals all --clear
```

### Deployment Failures

```bash
# Check logs
docker logs menugreen_api

# Check environment variables
docker exec menugreen_api env | sort

# Check port availability
netstat -tlnp | grep 5000
```

### CORS Issues

```bash
# Test preflight
curl -I -X OPTIONS https://api.menugreen.food/api/Auth/login \
  -H "Origin: https://www.menugreen.food" \
  -H "Access-Control-Request-Method: POST"

# Verify CORS headers
curl -I https://api.menugreen.food/health
```

---

## Monitoring Stack (Future)

See: [monitoring/uptimerobot-setup.md](./monitoring/uptimerobot-setup.md)

Planned:
- Prometheus metrics: `/metrics`
- Grafana dashboards
- UptimeRobot alerts

---

## Related Documents

| Document | Description |
|----------|-------------|
| [GITHUB_SECRETS_SETUP.md](./GITHUB_SECRETS_SETUP.md) | GitHub secrets setup guide |
| [lightsail-setup.md](./lightsail-setup.md) | Server setup guide |
| [issues.md](./issues.md) | Issue tracker |

---

*Last updated: 2026-07-05*
