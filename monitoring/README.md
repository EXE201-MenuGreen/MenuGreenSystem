# MenuGreen Monitoring Stack Setup Guide

## Overview

Monitoring stack cho MenuGreen bao gồm:
- **Prometheus**: Metrics collection
- **Grafana**: Visualization & dashboards
- **cAdvisor**: Container metrics
- **Node Exporter**: Server metrics
- **Nginx**: Reverse proxy với basic auth
- **UptimeRobot**: External uptime monitoring

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER ACCESS                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │  Flutter    │  │   Browser   │  │   Uptime    │           │
│  │    App      │  │  (Grafana)  │  │   Robot     │           │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘           │
└─────────┼────────────────┼─────────────────┼────────────────────┘
          │                │                 │
          ▼                ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      NGINX (Port 80/443)                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  /              → API (public)                          │   │
│  │  /health        → API health (public)                   │   │
│  │  /grafana       → Grafana (basic auth)                   │   │
│  │  /prometheus    → Prometheus (basic auth)              │   │
│  │  /cadvisor      → cAdvisor (basic auth)                 │   │
│  │  /metrics       → API metrics (basic auth)              │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│     API       │   │   Prometheus  │   │    Grafana    │
│  (metrics)    │   │  (scrape)     │   │  (dashboard)  │
│   Port 5000   │   │   Port 9090   │   │   Port 3000   │
└───────────────┘   └───────────────┘   └───────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │   Node Exporter   │
                    │   Port 9100       │
                    │   cAdvisor 8080   │
                    └───────────────────┘
```

---

## Quick Start

### 1. Setup trên Lightsail Instance

SSH vào Lightsail instance:

```bash
ssh -i your-key.pem ubuntu@your-instance-ip
```

### 2. Cài đặt Docker & Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again, or:
newgrp docker
```

### 3. Clone project

```bash
git clone https://github.com/your-repo/MenuGreenSystem.git
cd MenuGreenSystem
```

### 4. Setup Environment Variables

```bash
# Copy template
cp .env.example .env

# Edit .env với password của bạn
nano .env

# Hoặc generate htpasswd password
cd monitoring/scripts
chmod +x generate-password.sh
./generate-password.sh admin
# Nhập password mới khi được yêu cầu
# Copy output vào monitoring/nginx/.htpasswd

# Quay lại thư mục root
cd ../../
```

### 5. Tạo Docker Network

```bash
docker network create menugreen-net
```

### 6. Build và Start

```bash
# Build và start tất cả services
docker-compose up -d --build

# Kiểm tra status
docker-compose ps

# Xem logs nếu có lỗi
docker-compose logs -f
```

### 7. Verify Services

```bash
# API Health
curl http://localhost/health

# Prometheus
curl http://localhost:9090

# Grafana
http://your-ip:3000

# cAdvisor
http://your-ip:8080
```

---

## Access Credentials

Credentials được cấu hình trong file `.env` trên server.

| Service | URL | Auth |
|---------|-----|------|
| API | `http://your-ip/` | None |
| Health | `http://your-ip/health` | None |
| Grafana | `http://your-ip/grafana` | ${GF_SECURITY_ADMIN_USER}/${GF_SECURITY_ADMIN_PASSWORD} |
| Prometheus | `http://your-ip/prometheus` | ${NGINX_BASIC_AUTH_USER}/${NGINX_BASIC_AUTH_PASSWORD} |
| cAdvisor | `http://your-ip/cadvisor` | ${NGINX_BASIC_AUTH_USER}/${NGINX_BASIC_AUTH_PASSWORD} |
| Metrics | `http://your-ip/metrics` | ${NGINX_BASIC_AUTH_USER}/${NGINX_BASIC_AUTH_PASSWORD} |

**Lưu ý:** 
- ${GF_SECURITY_ADMIN_USER} và ${GF_SECURITY_ADMIN_PASSWORD} là giá trị trong file `.env`
- ${NGINX_BASIC_AUTH_USER} và ${NGINX_BASIC_AUTH_PASSWORD} là giá trị trong file `.env`
- Trên production, **đỔI TẤT CẢ PASSWORDS** sang giá trị mạnh hơn

---

## Grafana Setup

### 1. Login

Truy cập: `http://your-ip:3000`
- Username: giá trị `GF_SECURITY_ADMIN_USER` trong `.env`
- Password: giá trị `GF_SECURITY_ADMIN_PASSWORD` trong `.env`

### 2. Change Password

Đổi password ngay sau khi login:
1. Click avatar (góc trái dưới)
2. Chọn "Change password"
3. Đặt password mới mạnh hơn

### 3. Dashboard

Dashboard "MenuGreen System Overview" đã được auto-provisioned.

Truy cập: Menu (hamburger) → Dashboards → MenuGreen System Overview

**Panels bao gồm:**
- System Status (API, Redis, PostgreSQL)
- CPU & Memory Usage
- Disk Space
- API Request Rate
- API Response Time
- Container Metrics

---

## Prometheus Setup

### 1. Access

Truy cập: `http://your-ip/prometheus`
- Sẽ được hỏi basic auth
- Username: giá trị `NGINX_BASIC_AUTH_USER` trong `.env`
- Password: giá trị `NGINX_BASIC_AUTH_PASSWORD` trong `.env`

### 2. Check Targets

1. Status → Targets
2. Verify all targets are UP:
   - menugreen-api
   - node-exporter
   - cadvisor

### 3. Example Queries

```promql
# CPU Usage
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory Usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# API Response Time (p95)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="menugreen-api"}[5m]))

# Request Rate
rate(http_requests_total{job="menugreen-api"}[5m])
```

---

## Alert Script Setup

### 1. Install Dependencies

```bash
sudo apt install -y bc mailutils curl
```

### 2. Configure Alert Settings

Edit `monitoring/scripts/alert.sh`:

```bash
# Email alerts
ALERT_EMAIL="your-email@example.com"

# Slack webhook (optional)
SLACK_WEBHOOK="https://hooks.slack.com/services/xxx/yyy/zzz"

# Pushbullet (optional)
PUSHBULLET_TOKEN="o.xxx"

# Thresholds
CPU_WARNING=70
CPU_CRITICAL=85
MEMORY_WARNING=80
MEMORY_CRITICAL=90
```

### 3. Setup Cron Job

```bash
# Edit crontab
crontab -e

# Add this line (every 5 minutes)
*/5 * * * * /path/to/MenuGreenSystem/monitoring/scripts/alert.sh >> /var/log/menugreen-alert.log 2>&1
```

### 4. Test Alert

```bash
# Chạy thủ công để test
./monitoring/scripts/alert.sh
```

---

## SSL Setup (Recommended)

### Using Let's Encrypt

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal (certbot tự thêm vào cron)
sudo certbot renew --dry-run
```

### Update Nginx Config

Uncomment HTTPS server block trong `monitoring/nginx/nginx.conf`:

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ...
}
```

---

## Troubleshooting

### Services không start?

```bash
# Xem logs
docker-compose logs -f

# Restart services
docker-compose restart

# Rebuild
docker-compose down
docker-compose up -d --build
```

### Prometheus không scrape metrics?

```bash
# Check Prometheus logs
docker-compose logs prometheus

# Verify target trong Prometheus UI
# Status → Targets → kiểm tra menugreen-api
```

### Grafana dashboard trống?

```bash
# Kiểm tra Prometheus datasource
# Configuration → Data Sources → Prometheus
# URL: http://prometheus:9090
```

### Alert không gửi?

```bash
# Check log file
cat /var/log/menugreen-alert.log

# Verify mail service
sudo apt install -y mailutils
echo "test" | mail -s "Test" your-email@example.com
```

---

## Maintenance

### Update Images

```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d
```

### Backup Grafana Data

```bash
# Backup dashboards
docker cp menugreen_grafana:/var/lib/grafana/dashboards.json ./backup/

# Backup dashboards (provisioned - automatic)
ls monitoring/grafana/dashboards/
```

### Backup Prometheus Data

```bash
# Prometheus data nằm trong volume prometheus_data
# Tự động persist bởi Docker volume
docker volume inspect menugreen_prometheus_data
```

---

## Security Checklist

- [ ] Đổi Grafana password (admin/changeme123)
- [ ] Đổi htpasswd cho Nginx
- [ ] Cập nhật ALERT_EMAIL trong alert.sh
- [ ] Setup SSL với Let's Encrypt
- [ ] Firewall: chỉ mở port 80, 443
- [ ] Đổi default database passwords
- [ ] Backup credentials an toàn

---

## Cost Summary

| Service | Monthly Cost |
|---------|-------------|
| Lightsail 2GB | $10 |
| Data transfer | ~$5 |
| **Total** | **~$15/month** |

Không tốn thêm chi phí cho monitoring stack (self-hosted).

---

## Support

- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/
- Docker Docs: https://docs.docker.com/
