# =====================================================
# MenuGreen Monitoring Setup Guide
# =====================================================

## Tổng quan

Monitoring stack bao gồm:
- **Prometheus** (port 9090) - Thu thập metrics
- **Grafana** (port 3000) - Dashboard visualization
- **Node Exporter** (port 9100) - Server hardware metrics
- **cAdvisor** (port 8080) - Container metrics
- **Nginx** (port 8088) - Reverse proxy với basic auth

---

## Cài đặt nhanh

### 1. Tạo Docker network (chỉ cần làm 1 lần)

```bash
cd ~/apps/MenuGreenSystem
docker network create menugreen-mon 2>/dev/null || echo "Network đã tồn tại"
```

### 2. Tạo htpasswd cho Basic Auth

```bash
# Cài đặt apache2-utils (Ubuntu)
sudo apt install -y apache2-utils

# Tạo file htpasswd (user: admin)
htpasswd -bc monitoring/nginx/.htpasswd admin your_secure_password
```

### 3. Start Monitoring Stack

```bash
# Development/Local
docker compose -f docker-compose.monitoring.yml up -d

# Production (với API)
docker compose -f docker-compose.prod.yml -f docker-compose.monitoring.yml up -d
```

### 4. Kiểm tra Services

```bash
docker compose -f docker-compose.monitoring.yml ps
```

---

## Truy cập Dashboard

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://`<IP>`:3000 | admin / `GF_SECURITY_ADMIN_PASSWORD` |
| **Prometheus** | http://`<IP>`:8088/prometheus | admin / htpasswd password |
| **cAdvisor** | http://`<IP>`:8088/cadvisor | admin / htpasswd password |
| **Node Exporter** | http://`<IP>`:9100 | No auth |

---

## Health Check Script

### Cài đặt Cronjob

```bash
# Thêm vào crontab
crontab -e

# Thêm dòng sau:
*/5 * * * * /home/ubuntu/apps/MenuGreenSystem/monitoring/scripts/health-check.sh >> /home/ubuntu/logs/health-check.log 2>&1
```

### Chạy thủ công

```bash
cd ~/apps/MenuGreenSystem/monitoring/scripts
chmod +x health-check.sh
./health-check.sh
```

### Cấu hình Alert

```bash
# Export các biến môi trường
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/XXX/YYY/ZZZ"
export ALERT_EMAIL="your-email@example.com"
export REDIS_PASSWORD="your_redis_password"
export DB_HOST="your-rds-endpoint"
export DB_PORT="5432"

# Chạy health check
./health-check.sh
```

---

## Metrics có sẵn

### API Metrics (cần enable `ASPNETCORE_METRICS=true`)

- HTTP request rate, duration, status codes
- Database query duration
- Cache hit/miss rate
- Custom business metrics

### Node Exporter Metrics

- CPU usage per core
- Memory usage
- Disk I/O and space
- Network traffic
- System load

### cAdvisor Metrics

- Container CPU usage
- Container memory usage
- Container network I/O
- Container disk I/O
- Container restart count

---

## Troubleshooting

### Grafana không load dashboard

```bash
# Kiểm tra datasource
docker compose -f docker-compose.monitoring.yml logs grafana | grep datasource

# Reset Grafana data
docker compose -f docker-compose.monitoring.yml down -v
docker compose -f docker-compose.monitoring.yml up -d
```

### Prometheus không scrape metrics

```bash
# Kiểm tra targets
curl http://localhost:9090/api/v1/targets

# Reload Prometheus config
curl -X POST http://localhost:9090/-/reload
```

### cAdvisor không hoạt động

```bash
# Kiểm tra Docker socket
docker exec menugreen_cadvisor ls /var/run/docker.sock

# Restart cAdvisor
docker compose -f docker-compose.monitoring.yml restart cadvisor
```

---

## Firewall Ports

Đảm bảo các ports sau được mở trên Lightsail:

| Port | Service | Purpose |
|------|---------|---------|
| 3000 | Grafana | Direct access (optional) |
| 8088 | Nginx | Monitoring proxy với auth |
| 8080 | cAdvisor | Direct access (optional) |
| 9090 | Prometheus | Direct access (optional) |
| 9100 | Node Exporter | Direct access (optional) |

---

## Backup Monitoring Data

```bash
# Backup Prometheus data
docker run --rm -v menugreen_prometheus_data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus_backup.tar.gz -C /data .

# Backup Grafana data
docker run --rm -v menugreen_grafana_data:/data -v $(pwd):/backup alpine tar czf /backup/grafana_backup.tar.gz -C /data .
```

---

## Cleanup

```bash
# Stop và remove monitoring
docker compose -f docker-compose.monitoring.yml down

# Remove volumes (mất data!)
docker compose -f docker-compose.monitoring.yml down -v

# Remove network
docker network rm menugreen-mon
```
