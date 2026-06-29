# CI/CD Guide - MenuGreen System

Hướng dẫn setup và vận hành CI/CD pipeline cho MenuGreen System.

## Mục lục

- [Tổng quan](#tổng-quan)
- [Kiến trúc](#kiến-trúc)
- [GitHub Actions Workflow](#github-actions-workflow)
- [GitHub Secrets](#github-secrets)
- [Lightsail Server Setup](#lightsail-server-setup)
- [Monitoring Stack](#monitoring-stack)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)

---

## Tổng quan

### Pipeline Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│   Push/PR   │────▶│ Build & Test │────▶│Build Docker │────▶│   Deploy     │
│   to Git    │     │   (.NET)     │     │   Image     │     │  to Server   │
└─────────────┘     └──────────────┘     └─────────────┘     └──────────────┘
                                                                        │
                                                                        ▼
                                                        ┌──────────────────────────┐
                                                        │    Monitoring Stack      │
                                                        │  Prometheus + Grafana    │
                                                        └──────────────────────────┘
```

### Jobs trong CI/CD

| Job | Mô tả | Trigger |
|-----|-------|---------|
| `build-and-test` | Build .NET, chạy unit tests | Mọi push/PR |
| `build-docker` | Build và push Docker image lên GHCR | Push to main/Tuan |
| `deploy` | Deploy lên Lightsail, chạy migrations | Push to main/Tuan |
| `setup-monitoring` | Setup Prometheus/Grafana stack | Push to main/Tuan |

---

## Kiến trúc

### Infrastructure

```
                                    ┌──────────────────┐
                                    │   GitHub Repo    │
                                    └────────┬─────────┘
                                             │
                                    ┌────────▼─────────┐
                                    │  GitHub Actions  │
                                    │   (CI/CD)       │
                                    └────────┬─────────┘
                                             │
                                             │ SSH + Docker
                                    ┌────────▼─────────┐
                                    │   AWS Lightsail  │
                                    │   Ubuntu 22.04   │
                                    │                  │
                                    │  ┌────────────┐  │
                                    │  │ MenuGreen  │  │
                                    │  │    API     │  │
                                    │  └────────────┘  │
                                    │                  │
                                    │  ┌────────────┐  │
                                    │  │ Monitoring │  │
                                    │  │   Stack   │  │
                                    │  └────────────┘  │
                                    └──────────────────┘
```

### Docker Images

| Image | Mô tả | Registry |
|-------|-------|----------|
| `menugreen-api` | .NET 9 API | GHCR |
| `prom/prometheus` | Metrics collection | Docker Hub |
| `grafana/grafana` | Dashboards | Docker Hub |
| `prom/node-exporter` | Host metrics | Docker Hub |
| `gcr.io/cadvisor/cadvisor` | Container metrics | Google Container Registry |

---

## GitHub Actions Workflow

### File: `.github/workflows/ci-cd.yml`

Workflow được trigger khi:
- Push lên branch `main` hoặc `Tuan`
- Pull request vào branch `main`

### Environment Variables

```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository_owner }}/menugreen-api
  DOTNET_VERSION: '9.0'
```

### Docker Image Tagging

| Tag | Format | Ví dụ |
|-----|--------|-------|
| Branch | `type=ref,event=branch` | `main`, `Tuan` |
| SHA | `type=sha,prefix={{branch}}-` | `main-a1b2c3d` |
| Latest | `type=raw,value=latest` | `latest` |

---

## GitHub Secrets

### Bắt buộc (Required)

| Secret | Mô tả | Ví dụ |
|--------|--------|-------|
| `LIGHTSAIL_HOST` | IP/DNS của Lightsail | `REDACTED_EXAMPLE_IP` hoặc `ec2-xxx.compute.amazonaws.com` |
| `LIGHTSAIL_USER` | SSH user | `ubuntu` |
| `LIGHTSAIL_SSH_KEY` | Private key để SSH vào server | `-----BEGIN RSA PRIVATE KEY-----...` |
| `DB_HOST` | Database host | `xxx.postgres.database.azure.com` |
| `DB_PORT` | Database port | `5432` |
| `DB_NAME` | Database name | `menugreen` |
| `DB_USER` | Database user | `menugreen_admin` |
| `DB_PASSWORD` | Database password | `secure_password_here` |
| `JWT_SECRET` | JWT signing key (min 32 chars) | `your-super-secret-jwt-key-at-least-32-chars` |

### Tùy chọn (Optional)

| Secret | Mô tả |
|--------|-------|
| `REDIS_PASSWORD` | Redis password |
| `GF_SECURITY_ADMIN_PASSWORD` | Grafana admin password |
| `SLACK_WEBHOOK_URL` | Slack webhook cho alerts |
| `ALERT_EMAIL` | Email để gửi alerts |

### Cách thêm Secrets

1. Vào **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Thêm từng secret theo bảng trên

Xem chi tiết: [GITHUB_SECRETS_SETUP.md](./GITHUB_SECRETS_SETUP.md)

---

## Lightsail Server Setup

### Yêu cầu

- Ubuntu 22.04 LTS
- Minimum 2GB RAM
- Docker & Docker Compose đã install
- SSH access đã configure

### Initial Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo apt install docker-compose -y

# Create app directory
mkdir -p /home/ubuntu/apps/MenuGreenSystem
mkdir -p /home/ubuntu/logs
mkdir -p /home/ubuntu/backups

# Setup log rotation
sudo tee /etc/logrotate.d/menugreen <<EOF
/home/ubuntu/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0644 ubuntu ubuntu
}
EOF
```

### Firewall Setup

```bash
# UFW rules
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 5000/tcp  # API
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 9090/tcp  # Prometheus
sudo ufw enable
```

### SSL Certificate (Let's Encrypt)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Generate certificate
sudo certbot --nginx -d api.menugreen.com -d grafana.menugreen.com -d prometheus.menugreen.com
```

---

## Monitoring Stack

### Containers

| Container | Port | Mục đích |
|-----------|------|----------|
| `prometheus` | 9090 | Metrics collection & storage |
| `grafana` | 3000 | Dashboards & visualization |
| `node-exporter` | 9100 | Host system metrics |
| `cadvisor` | 8080 | Container metrics |
| `alertmanager` | 9093 | Alert routing |
| `redis-exporter` | 9121 | Redis metrics |
| `nginx` | 80, 443 | Reverse proxy |
| `redis` | 6379 | Caching layer |

### URLs

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Grafana | `http://<server>:3000` | admin / REDACTED_ADMIN_PASSWORD |
| Prometheus | `http://<server>:9090` | - |
| cAdvisor | `http://<server>:8080` | - |
| Node Exporter | `http://<server>:9100` | - |

### Metrics Endpoint

API exposed metrics tại: `http://<server>:5000/metrics`

Các metrics .NET có sẵn:
- `dotnet_*` - .NET runtime metrics
- `http_request_duration_seconds` - Request latency
- `http_requests_total` - Request count

### Dashboards

Import dashboards từ Grafana:

1. **Node Exporter Full** (ID: 1860)
   - System metrics: CPU, Memory, Disk, Network

2. **Docker and System Dashboard** (ID: 179)
   - Container metrics

3. **API Monitoring Dashboard** (tùy chỉnh)
   - Request rate, latency, error rate

---

## Deployment

### Manual Deployment

```bash
# SSH vào server
ssh -i ~/.ssh/your_key.pem ubuntu@<server-ip>

# Pull latest code
cd /home/ubuntu/apps/MenuGreenSystem
git pull origin main

# Run deploy script
chmod +x scripts/deploy.sh
./scripts/deploy.sh production
```

### Health Check

```bash
# Manual health check
./monitoring/scripts/health-check.sh

# Setup cron job (chạy mỗi 5 phút)
crontab -e
# Thêm dòng:
*/5 * * * * /home/ubuntu/apps/MenuGreenSystem/monitoring/scripts/health-check.sh >> /home/ubuntu/logs/health-check.log 2>&1
```

### Rollback

```bash
# List available images
docker images | grep menugreen-api

# Stop current container
docker stop menugreen-api

# Run specific version
docker run -d \
  --name menugreen-api \
  --restart unless-stopped \
  --env-file /home/ubuntu/apps/MenuGreenSystem/.env \
  -p 5000:5000 \
  ghcr.io/<owner>/menugreen-api:<tag>
```

---

## Troubleshooting

### Build Failures

**Problem**: `dotnet restore` fails
```bash
# Check network connectivity
curl -s https://api.nuget.org/v3/index.json | head

# Clear NuGet cache
dotnet nuget locals all --clear
```

**Problem**: Docker build fails
```bash
# Check Docker version
docker --version

# Clear build cache
docker builder prune -a
```

### Deployment Failures

**Problem**: SSH connection fails
```bash
# Verify key permissions
chmod 600 ~/.ssh/your_key.pem

# Test SSH manually
ssh -i ~/.ssh/your_key.pem ubuntu@<server-ip>
```

**Problem**: Container won't start
```bash
# Check logs
docker logs menugreen-api

# Check environment variables
docker exec menugreen-api env | sort

# Check port availability
netstat -tlnp | grep 5000
```

**Problem**: Database migration fails
```bash
# Manual migration
docker exec menugreen-api dotnet ef database update \
  --project backend/MenuGreen.DataAccessLayer/MenuGreen.DataAccessLayer.csproj \
  --startup-project backend/MenuGreen.API/MenuGreen.API.csproj

# Check connection
docker exec menugreen-api dotnet ef database check-connection
```

### Monitoring Issues

**Problem**: Prometheus can't scrape API
```bash
# Check if /metrics endpoint exists
curl http://localhost:5000/metrics

# Check Prometheus targets
# Truy cập http://<server>:9090/targets
```

**Problem**: Grafana shows no data
```bash
# Check datasource
curl http://prometheus:9090/api/v1/status/config

# Check metrics storage
curl http://prometheus:9090/api/v1/query?query=up
```

### Common Commands

```bash
# View all containers
docker ps -a

# View logs
docker logs -f menugreen-api
docker logs -f prometheus

# Restart service
docker restart menugreen-api

# Rebuild monitoring stack
docker compose -f docker-compose.monitoring.yml down
docker compose -f docker-compose.monitoring.yml up -d

# Check disk usage
docker system df

# Cleanup unused images
docker image prune -a
```

---

## Liên hệ & Support

- **GitHub Issues**: [Repository Issues](https://github.com/EXE201-MenuGreen/MenuGreenSystem/issues)
- **Documentation**: [MenuGreen Wiki](./)
- **Slack Channel**: `#devops` (nếu có)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-06-29 | Initial CI/CD setup |
