# MenuGreen System - Production Deployment Plan

**Ngày tạo:** 29/06/2026
**Target:** AWS Lightsail Ubuntu 22.04 + AWS RDS PostgreSQL
**Backend:** .NET 9.0 API + Redis

---

## Mục lục

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Bước 1: Cài đặt Server](#2-bước-1-cài-đặt-server)
3. [Bước 2: Cấu hình AWS](#3-bước-2-cấu-hình-aws)
4. [Bước 3: Database Setup](#4-bước-3-database-setup)
5. [Bước 4: Cấu hình GitHub Actions](#5-bước-4-cấu-hình-github-actions)
6. [Bước 5: Deploy lần đầu](#6-bước-5-deploy-lần-đầu)
7. [Bước 6: Xác minh](#7-bước-6-xác-minh)
8. [Bước 7: CI/CD Pipeline](#8-bước-7-cicd-pipeline)
9. [Bước 8: Monitoring & Alerting](#9-bước-8-monitoring--alerting)
   - [9.2 Cài đặt Monitoring Stack](#92-cài-đặt-monitoring-stack)
   - [9.3 Access Monitoring Dashboards](#93-access-monitoring-dashboards)
   - [9.4 Alerting](#94-alerting)
   - [9.5 Health Check Script](#95-health-check-script)
   - [9.6 Log Rotation](#96-log-rotation)
   - [9.7 Quick Commands](#97-quick-commands)

---

## 1. Tổng quan kiến trúc

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                    │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        AWS Lightsail VPS                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                   │
│  │   Nginx      │  │   API        │  │   Redis      │                   │
│  │   (Proxy)    │──│   (.NET 9)   │  │   (Cache)    │                   │
│  │   :80/:443   │  │   :5000      │  │   :6379      │                   │
│  └──────────────┘  └──────────────┘  └──────────────┘                   │
│         │                  │                                             │
│         │                  │                                             │
│         │                  ▼                                             │
│         │         ┌────────────────┐                                     │
│         │         │  AWS RDS       │                                     │
│         │         │  PostgreSQL    │                                     │
│         │         │  :5432         │                                     │
│         │         └────────────────┘                                     │
└─────────┴─────────────────────────────────────────────────────────────────┘
```

---

## 2. Bước 1: Cài đặt Server

### 2.1 SSH vào Server

```bash
ssh ubuntu@<LIGHTSAIL_IP>
```

### 2.2 Cài Docker

```bash
# Cài Docker
curl -fsSL https://get.docker.com | sh

# Thêm ubuntu user vào docker group
sudo usermod -aG docker ubuntu

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Verify
docker --version
docker compose version
```

### 2.3 Cài .NET 9.0 SDK

```bash
# Thêm Microsoft repository
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update

# Cài .NET 9.0 SDK
sudo apt install -y dotnet-sdk-9.0

# Cài dotnet-ef tool
dotnet tool install --global dotnet-ef

# Thêm vào PATH vĩnh viễn
echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.bashrc
source ~/.bashrc

# Verify
dotnet --version
dotnet ef --version
```

### 2.4 Cài PostgreSQL Client

```bash
sudo apt install -y postgresql-client
psql --version
```

### 2.5 Tạo thư mục ứng dụng

```bash
mkdir -p ~/apps
mkdir -p ~/backups/redis
mkdir -p ~/logs
```

---

## 3. Bước 2: Cấu hình AWS

### 3.1 RDS Security Group

1. AWS Console → **RDS** → **Databases** → `menugreen-db`
2. Click vào **VPC Security Group**
3. **Edit inbound rules**:
   - **Type:** PostgreSQL
   - **Protocol:** TCP
   - **Port:** 5432
   - **Source:** Custom → IP của Lightsail (`<LIGHTSAIL_IP>/32`)

### 3.2 Lightsail Firewall

1. Lightsail Console → **Networking** → chọn instance
2. **Firewall** → **Add rule**:
   - Protocol: TCP
   - Port: 5432
   - Source: Custom IP → IP của bạn (để secure)

---

## 4. Bước 3: Database Setup

### 4.1 Test kết nối RDS

```bash
psql "host=menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com port=5432 dbname=postgres user=postgres sslmode=require"
```

Nhập password: `<RDS_PASSWORD>`

### 4.2 Tạo Database

```sql
CREATE DATABASE "MenuGreenDb";
\l
\q
```

### 4.3 Clone code và chạy Migration

```bash
cd ~/apps
git clone https://github.com/<YOUR_USERNAME>/MenuGreenSystem.git
cd MenuGreenSystem/backend/MenuGreen.API

dotnet ef database update --connection "Host=menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com;Port=5432;Database=MenuGreenDb;Username=postgres;Password=<RDS_PASSWORD>;SSL Mode=Require"
```

### 4.4 Verify Tables

```bash
psql "host=menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com port=5432 dbname=MenuGreenDb user=postgres sslmode=require" -c "\dt"
```

---

## 5. Bước 4: Cấu hình GitHub Actions

### 5.1 Tạo SSH Key cho GitHub Actions

Trên **máy Windows** của bạn (PowerShell):

```powershell
# Tạo SSH key mới
ssh-keygen -t ed25519 -C "github-actions@menugreen" -f ~/menugreen_gh_actions

# Xem public key (sẽ cần thêm vào server)
cat ~/menugreen_gh_actions.pub

# Xem private key (sẽ copy vào GitHub)
cat ~/menugreen_gh_actions
```

Output sẽ có dạng:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... github-actions@menugreen
```

### 5.2 Thêm Public Key vào Server

Trên **Lightsail**:

```bash
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys
```

Paste public key vào, save (Ctrl+X, Y, Enter).

### 5.3 Thêm GitHub Secrets

Trong **GitHub repo** → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:

| Secret Name | Value | Mô tả |
|-------------|-------|--------|
| `LIGHTSAIL_HOST` | `13.229.x.x` | IP Lightsail |
| `LIGHTSAIL_SSH_KEY` | `<private_key_content>` | Private SSH key (toàn bộ nội dung file) |
| `DB_HOST` | `menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com` | RDS endpoint |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `MenuGreenDb` | Database name |
| `DB_USER` | `postgres` | Database user |
| `DB_PASSWORD` | `<RDS_PASSWORD>` | Database password |
| `REDIS_PASSWORD` | `<REDIS_PASSWORD>` | Redis password (tự tạo, VD: `Mg2024!Secure`) |

---

## 6. Bước 5: Deploy lần đầu

### 6.1 Cấu hình .env.production

```bash
cd ~/apps/MenuGreenSystem
cp .env.example .env
nano .env
```

Nội dung `.env`:

```env
# ASP.NET
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_HTTP_PORTS=5000
ASPNETCORE_METRICS=true

# Database
DB_HOST=menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com
DB_PORT=5432
DB_NAME=MenuGreenDb
DB_USER=postgres
DB_PASSWORD=<RDS_PASSWORD>
DB_SSL_MODE=Require
DB_TRUST_SERVER_CERTIFICATE=true

# Redis
REDIS_PASSWORD=<REDIS_PASSWORD>

# CV Service (nếu có)
CV_SERVICE_BASE_URL=https://api.example.com
CV_SERVICE_API_SECRET_KEY=
```

### 6.2 Tạo Docker Network

```bash
cd ~/apps/MenuGreenSystem
docker network create menugreen-net
```

### 6.3 Build và Start

```bash
# Build Docker images
docker compose -f docker-compose.prod.yml build --no-cache

# Start Redis trước
docker compose -f docker-compose.prod.yml up -d redis

# Đợi Redis healthy
sleep 5

# Start API
docker compose -f docker-compose.prod.yml up -d api

# Xem logs
docker compose -f docker-compose.prod.yml logs -f api
```

### 6.4 Test Health Check

```bash
curl http://localhost:5000/health
```

Response mong đợi:
```json
{"status":"Healthy"}
```

---

## 7. Bước 6: Xác minh

### 7.1 Test API Endpoints

```bash
# Test root
curl http://localhost:5000/

# Test swagger
curl http://localhost:5000/swagger/index.html

# Test một số endpoints
curl http://localhost:5000/api/v1/Health
```

### 7.2 Kiểm tra Services

```bash
docker compose -f docker-compose.prod.yml ps
```

Output mong đợi:
```
NAME                IMAGE                    COMMAND                  SERVICE   STATUS
menugreen_api       menugreen-api            "dotnet MenuGreen.API…"   api       Up (healthy)
menugreen_redis     redis:7-alpine           "docker-entrypoint.s…"   redis     Up (healthy)
```

### 7.3 Kiểm tra Logs

```bash
docker compose -f docker-compose.prod.yml logs api --tail=50
```

---

## 8. Bước 7: CI/CD Pipeline

### 8.1 Trigger Pipeline

Push code lên GitHub:

```bash
cd ~/apps/MenuGreenSystem
git add .
git commit -m "feat: initial production deployment"
git push origin main
```

### 8.2 Theo dõi GitHub Actions

1. GitHub repo → **Actions** tab
2. Xem workflow chạy:
   - ✅ Build & Test
   - ✅ Generate Migration Script
   - ✅ Build Docker Image
   - ✅ Deploy to Lightsail

### 8.3 Verify Auto-Deploy

```bash
# Kiểm tra trên server
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs api --tail=20
```

---

## Troubleshooting

### Lỗi: "dotnet: command not found"

```bash
# Kiểm tra .NET installation
which dotnet
dotnet --version

# Nếu không có, thêm vào PATH
export PATH="$PATH:$HOME/.dotnet/tools"
source ~/.bashrc
```

### Lỗi: "psql: could not connect to server"

1. Kiểm tra RDS Security Group cho phép Lightsail IP
2. Test kết nối: `telnet menugreen-db.xxx.rds.amazonaws.com 5432`

### Lỗi: Docker container không start

```bash
# Xem logs
docker compose -f docker-compose.prod.yml logs api

# Rebuild
docker compose -f docker-compose.prod.yml build --no-cache
docker compose -f docker-compose.prod.yml up -d
```

### Lỗi: Migration failed

```bash
# Xem chi tiết lỗi
dotnet ef database update --verbose --connection "..."

# Kiểm tra database connection
psql "host=... port=5432 dbname=MenuGreenDb user=postgres sslmode=require" -c "SELECT 1"
```

---

## Maintenance

### Backup Database (hàng ngày - tùy chọn)

```bash
# Tạo script backup
nano ~/scripts/backup-db.sh
```

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=~/backups/db
PGPASSWORD=<RDS_PASSWORD> pg_dump -h menugreen-db.xxx.rds.amazonaws.com -U postgres -d MenuGreenDb > $BACKUP_DIR/menugreen_backup_$DATE.sql
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
```

### Update Deployment

```bash
cd ~/apps/MenuGreenSystem
git pull origin main
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

### Restart Services

```bash
docker compose -f docker-compose.prod.yml restart
```

---

## 9. Bước 8: Monitoring & Alerting

### 9.1 Tổng quan Monitoring Stack

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           MONITORING STACK                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐              │
│  │   Grafana    │   │  Prometheus  │   │   cAdvisor   │              │
│  │   Dashboard  │◄──│   Metrics    │◄──│  Container   │              │
│  │   :3000      │   │   :9090      │   │   Metrics    │              │
│  └──────────────┘   └──────────────┘   └──────────────┘              │
│         │                  │                  │                         │
│         │                  │                  │                         │
│         │                  ▼                  │                         │
│         │           ┌──────────────┐          │                         │
│         │           │  Node        │          │                         │
│         │           │  Exporter    │──────────┘                         │
│         │           │  :9100       │                                    │
│         │           └──────────────┘                                    │
│         │                  │                                             │
│         │                  ▼                                             │
│         │           ┌──────────────┐                                    │
│         └──────────►│  Redis       │                                    │
│                     │  Exporter    │                                    │
│                     │  :9121       │                                    │
│                     └──────────────┘                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 9.2 Cài đặt Monitoring Stack

#### 9.2.1 Monitoring configs (đã có trong repo)

Tất cả configs đã có sẵn trong `monitoring/`:

```
monitoring/
├── prometheus/
│   ├── prometheus.yml       # Prometheus scrape config
│   ├── alerts.yml          # Alert rules
│   └── data/               # Prometheus data
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/prometheus.yml
│   │   └── dashboards/
│   │       ├── dashboard.yml
│   │       └── menugreen-overview.json
│   └── dashboards/
├── nginx/
│   ├── nginx.conf          # Reverse proxy config
│   └── .htpasswd           # Basic auth (tạo khi deploy)
└── scripts/
    └── health-check.sh     # Health check script
```

#### 9.2.2 Tạo Docker network

```bash
cd ~/apps/MenuGreenSystem
docker network create menugreen-mon 2>/dev/null || echo "Network đã tồn tại"
```

#### 9.2.3 Tạo Basic Auth

```bash
# Cài apache2-utils
sudo apt install -y apache2-utils

# Tạo htpasswd (thay password)
htpasswd -bc monitoring/nginx/.htpasswd admin your_secure_password
```

#### 9.2.4 Start Monitoring

```bash
# Development - chỉ monitoring
docker compose -f docker-compose.monitoring.yml up -d

# Production - monitoring + API
docker compose -f docker-compose.prod.yml -f docker-compose.monitoring.yml up -d
```

#### 9.2.5 Cài Cronjob Health Check

```bash
crontab -e

# Thêm:
*/5 * * * * /home/ubuntu/apps/MenuGreenSystem/monitoring/scripts/health-check.sh >> /home/ubuntu/logs/health-check.log 2>&1
```

#### 9.2.6 Cấu hình Alert Variables

```bash
# Thêm vào ~/.bashrc
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/XXX/YYY/ZZZ"
export ALERT_EMAIL="your-email@example.com"
export REDIS_PASSWORD="your_redis_password"
export DB_HOST="your-rds-endpoint"
export DB_PORT="5432"
```

---

### 9.3 Access Monitoring Dashboards

| Service | URL | Port | Credentials |
|---------|-----|------|-------------|
| Grafana | http://`<LIGHTSAIL_IP>`:3000 | 3000 | admin / `GF_SECURITY_ADMIN_PASSWORD` |
| Prometheus | http://`<LIGHTSAIL_IP>`:8088/prometheus | 8088 | admin / htpasswd password |
| cAdvisor | http://`<LIGHTSAIL_IP>`:8088/cadvisor | 8088 | admin / htpasswd password |
| Node Exporter | http://`<LIGHTSAIL_IP>`:9100 | 9100 | No auth |

**Lưu ý:** Monitoring được access qua Nginx proxy với basic auth. Direct access ports (3000, 9090, 8080) chỉ nên mở cho IP của bạn.

### 9.4 Alerting

Alert rules đã có trong `monitoring/prometheus/alerts.yml`.

#### Prometheus Alert Rules

| Alert | Condition | Severity |
|-------|-----------|----------|
| MenuGreenAPIDown | `up{job="menugreen-api"} == 0` for 1m | Critical |
| HighCPUUsage | CPU > 80% for 5m | Warning |
| HighMemoryUsage | Memory > 85% for 5m | Warning |
| ContainerDown | Container not running | Critical |
| RedisDown | Redis not running | Critical |
| HighDiskUsage | Disk > 85% | Warning |

#### Cấu hình Alert Notifications

Để nhận alerts, cần cấu hình Alertmanager. Hiện tại alerts được monitor qua:

1. **Prometheus UI** - http://`<IP>`:9090/alerts
2. **Grafana Alerting** - Cấu hình trong Grafana dashboard
3. **Health Check Script** - Gửi Slack/Email notifications

### 9.5 Health Check Script

Script đã có tại `monitoring/scripts/health-check.sh`.

#### Tính năng

- ✅ API health check
- ✅ Redis connectivity
- ✅ Docker containers status
- ✅ CPU/Memory/Disk monitoring
- ✅ Database connectivity
- ✅ Slack/Email notifications
- ✅ Automatic retry với exponential backoff

#### Chạy thủ công

```bash
cd ~/apps/MenuGreenSystem
chmod +x monitoring/scripts/health-check.sh

# Export credentials
export REDIS_PASSWORD="your_redis_password"
export DB_HOST="your-rds-endpoint"
export DB_PORT="5432"

# Run
./monitoring/scripts/health-check.sh
```

### 9.6 Log Rotation

```bash
sudo nano /etc/logrotate.d/menugreen
```

```
/home/ubuntu/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0644 ubuntu ubuntu
    sharedscripts
    postrotate
        docker compose -f /home/ubuntu/apps/MenuGreenSystem/docker-compose.prod.yml restart > /dev/null 2>&1 || true
    endscript
}
```

### 9.7 Quick Commands

| Mục đích | Command |
|-----------|---------|
| Xem services | `docker compose -f docker-compose.prod.yml ps` |
| Xem logs API | `docker compose -f docker-compose.prod.yml logs -f api` |
| Xem logs Redis | `docker compose -f docker-compose.prod.yml logs -f redis` |
| Restart services | `docker compose -f docker-compose.prod.yml restart` |
| Xem monitoring | `docker compose -f docker-compose.monitoring.yml ps` |
| API health | `curl http://localhost:5000/health` |
| Prometheus targets | `curl http://localhost:9090/api/v1/targets` |
| Health check | `~/apps/MenuGreenSystem/monitoring/scripts/health-check.sh` |

---

## Security Checklist

- [ ] Đổi RDS password mạnh
- [ ] Sử dụng SSL cho PostgreSQL
- [ ] Firewall chỉ mở port cần thiết
- [ ] Không commit .env file
- [ ] SSH key cho GitHub Actions có passphrase
- [ ] Redis password mạnh
- [ ] HTTPS cho production (sau này thêm Nginx)
- [ ] Đổi default Grafana password
- [ ] Giới hạn access monitoring ports (chỉ mở cho IP của bạn)

---

## Liên hệ & Support

Nếu gặp lỗi, kiểm tra:
1. Logs: `docker compose -f docker-compose.prod.yml logs`
2. GitHub Actions: Tab **Actions** trong repo
3. AWS RDS: CloudWatch logs
4. Monitoring: Grafana dashboards tại port 3000
