# MenuGreen Monitoring

Monitoring stack documentation for MenuGreen System.

## Overview

The monitoring stack provides comprehensive observability for the MenuGreen API and infrastructure.

```
┌─────────────────────────────────────────────────────────────┐
│                      Grafana UI                             │
│                   http://localhost:3000                     │
└─────────────────────────┬───────────────────────────────────┘
                          │ Queries
┌─────────────────────────▼───────────────────────────────────┐
│                       Prometheus                            │
│                   http://localhost:9090                      │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │  .NET API   │  │   Node      │  │   cAdvisor  │       │
│  │  /metrics   │  │   Exporter  │  │   /metrics  │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

## Components

| Component | Image | Purpose |
|-----------|-------|---------|
| Prometheus | prom/prometheus:v2.48.0 | Metrics collection & storage |
| Grafana | grafana/grafana:10.2.2 | Visualization & dashboards |
| Node Exporter | prom/node-exporter:v1.6.1 | Host metrics |
| cAdvisor | gcr.io/cadvisor/cadvisor:v0.47.2 | Container metrics |
| Alertmanager | prom/alertmanager:v0.26.0 | Alert routing |
| Redis Exporter | oliver006/redis_exporter:v1.55.0 | Redis metrics |
| Nginx | nginx:1.25.3-alpine | Reverse proxy |
| Redis | redis:7.2-alpine | Caching |

## Quick Start

### Start Monitoring Stack

```bash
docker compose -f docker-compose.monitoring.yml up -d
```

### Access Services

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Grafana | http://localhost:3000 | admin / admin123 |
| Prometheus | http://localhost:9090 | - |
| cAdvisor | http://localhost:8080 | - |
| Node Exporter | http://localhost:9100 | - |
| Alertmanager | http://localhost:9093 | - |

### Stop Monitoring Stack

```bash
docker compose -f docker-compose.monitoring.yml down
```

## Metrics

### .NET Application Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `dotnet_total_memory_bytes` | Gauge | Total managed memory |
| `dotnet_gc_collection_total` | Counter | GC collections by generation |
| `dotnet_thread_pool_num_threads` | Gauge | Thread pool size |
| `http_request_duration_seconds` | Histogram | Request latency |
| `http_requests_total` | Counter | Total requests |
| `api_requests_active` | Gauge | Active requests |

### Host Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `node_cpu_seconds_total` | Counter | CPU time |
| `node_memory_MemTotal_bytes` | Gauge | Total memory |
| `node_memory_MemAvailable_bytes` | Gauge | Available memory |
| `node_filesystem_size_bytes` | Gauge | Filesystem size |
| `node_disk_read_bytes_total` | Counter | Disk reads |
| `node_disk_writes_bytes_total` | Counter | Disk writes |
| `node_network_receive_bytes_total` | Counter | Network received |
| `node_network_transmit_bytes_total` | Counter | Network transmitted |

### Container Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `container_cpu_usage_seconds_total` | Counter | CPU usage |
| `container_memory_usage_bytes` | Gauge | Memory usage |
| `container_network_receive_bytes_total` | Counter | Network received |
| `container_network_transmit_bytes_total` | Counter | Network transmitted |
| `container_fs_reads_bytes_total` | Counter | Filesystem reads |
| `container_fs_writes_bytes_total` | Counter | Filesystem writes |

## Dashboards

### Recommended Grafana Dashboards

1. **Node Exporter Full** (ID: 1860)
   - CPU, Memory, Disk, Network
   - Import from Grafana.com

2. **Docker and System Monitoring** (ID: 179)
   - Container metrics
   - System overview

3. **Prometheus 2.0 Overview** (ID: 3662)
   - Prometheus health
   - Query performance

4. **API Monitoring Dashboard** (Custom)
   - Request rate
   - Error rate
   - Latency percentiles

### Create Custom Dashboard

```json
{
  "dashboard": {
    "title": "MenuGreen API",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{path}}"
          }
        ]
      }
    ]
  }
}
```

## Alerting

### Alert Rules

Create file: `monitoring/prometheus/rules/alerts.yml`

```yaml
groups:
  - name: menugreen
    rules:
      - alert: APIDown
        expr: up{job="menugreen-api"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "API is down"

      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.01
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
```

### Alertmanager Integration

Configure receivers in `monitoring/alertmanager/alertmanager.yml`:

- Email notifications
- Slack webhooks
- PagerDuty integration
- Webhook for custom integrations

## Health Checks

### Manual Health Check

```bash
./monitoring/scripts/health-check.sh
```

### Setup Cron Job

```bash
# Edit crontab
crontab -e

# Add health check every 5 minutes
*/5 * * * * /home/ubuntu/apps/MenuGreenSystem/monitoring/scripts/health-check.sh >> /home/ubuntu/logs/health-check.log 2>&1
```

### Health Check Metrics

| Check | Threshold | Action |
|-------|-----------|--------|
| API Health | HTTP 200 | - |
| API Latency | > 2s | Warning |
| Disk Usage | > 85% | Warning |
| Memory Usage | > 85% | Warning |
| CPU Usage | > 80% | Warning |
| Redis | PONG | - |
| Database | SELECT 1 | - |

## Troubleshooting

### Prometheus Not Scraping

```bash
# Check targets
curl http://localhost:9090/api/v1/targets

# Check metrics endpoint
curl http://localhost:5000/metrics | head
```

### Grafana No Data

```bash
# Check datasource
curl http://prometheus:9090/api/v1/query?query=up

# Check Prometheus logs
docker logs prometheus
```

### High Memory Usage

```bash
# Check container memory
docker stats

# Limit container memory
docker update -m 512m menugreen-api
```

## Maintenance

### Cleanup Old Metrics

```bash
# Prometheus retention (default 15 days)
# Edit prometheus.yml:
#   storage.tsdb.retention.time: 15d

# Cleanup Docker volumes
docker volume prune
```

### Backup Dashboards

```bash
# Export all dashboards
curl -s -u admin:admin123 http://localhost:3000/api/search | jq -r '.[].uri' | while read uri; do
  name=$(basename $uri)
  curl -s -u admin:admin123 "http://localhost:3000/api/dashboards/$uri" | \
    jq '.dashboard' > "dashboards/$name.json"
done
```

## Security

### Firewall Ports

```bash
# Allow monitoring ports
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 9090/tcp  # Prometheus
sudo ufw allow 8080/tcp  # cAdvisor
sudo ufw allow 9100/tcp  # Node Exporter
sudo ufw allow 9093/tcp  # Alertmanager
```

### Grafana Authentication

```bash
# Change default password
curl -X PUT -H "Content-Type: application/json" \
  -d '{"password": "your-new-password"}' \
  http://admin:admin123@localhost:3000/api/user/password
```

### Nginx Auth (Optional)

```bash
# Install htpasswd
sudo apt install apache2-utils

# Create password file
sudo htpasswd -c /etc/nginx/.htpasswd admin

# Restart nginx
docker restart nginx-monitoring
```
