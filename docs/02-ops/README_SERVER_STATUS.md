# Server Status Overview

Đây là trạng thái tổng hợp của server Lightsail và Docker stack của MenuGreen System.

---

## 1. Infra

| Item | Value |
|------|-------|
| OS | Ubuntu 22.04.5 LTS |
| CPU | 2 cores |
| RAM | 1.9 GB |
| Disk | 58 GB (17% used, 49 GB available) |
| Docker | 29.6.1 |
| Docker Compose | v5.2.0 |
| App path | `/home/ubuntu/apps/MenuGreenSystem` |
| Remote repo | `https://github.com/EXE201-MenuGreen/MenuGreenSystem.git` |
| Deploy branch | `main`, fallback `Tuan` |
| Image registry | GHCR `ghcr.io/EXE201-MenuGreen/MenuGreenSystem/menugreen-api:latest` |
| UFW Firewall | `inactive` |
| Docker disk | Images 3.125 GB, Build Cache 1.783 GB, 25 caches |

### Lưu ý resource

- RAM `~1.9 GB` (không tới 2 GB), disk `< 60 GB` nên cần giám sát log và dung lượng container image/volume.
- Monitoring stack đã có sẵn trong repo (`docker-compose.monitoring.yml`), đang chuẩn bị khởi chạy.

---

## 2. RDS / Database

| Item | Value |
|------|-------|
| Provider | AWS RDS |
| Engine | PostgreSQL |
| Host | `<RDS_ENDPOINT>` |
| Port | `5432` |
| Database | `MenuGreenDb` |
| Master username | `postgres` |
| Master password | Đã lưu trong Doppler / `.env` |
| Region | `ap-southeast-1b` |
| Security group | `<SECURITY_GROUP_ID>` |
| Lightsail → RDS | Đã kiểm tra connect thành công |
| Database status | Đã tồn tại và truy cập được từ Lightsail |

### Backup

- Môi trường production nên backup RDS trước mỗi deploy.
- Hiện chưa cấu hình backup tự động.
- `pg_stat_database` cho thấy `MenuGreenDb` đang hoạt động bình thường (`xact_commit` cao, không có `deadlocks`).

---

## 3. Nginx / SSL

| Item | Value |
|------|-------|
| Nginx host | Không cài trên Lightsail host |
| SSL (Let's Encrypt) | Chưa cấu hình |
| Monitoring reverse proxy | Có sẵn trong `docker-compose.monitoring.yml` (container `nginx-monitoring`) nhưng chưa chạy |

Lưu ý: Nếu dùng domain production, cần cấu hình reverse proxy hoặc load balancer phù hợp.

---

## 4. Monitoring Stack

| Item | Value |
|------|-------|
| Compose file | `docker-compose.monitoring.yml` |
| Status | Chưa khởi chạy |
| Stack | Prometheus, Grafana, Node Exporter, cAdvisor, Alertmanager, Redis Exporter, Nginx reverse proxy |

### Ports (khi chạy)

- Prometheus: `9090`
- Grafana: `3000`
- Node Exporter: `9100`
- cAdvisor: `8080`
- Alertmanager: `9093`
- Redis Exporter: `9121`
- Nginx monitoring: `80`, `443`

---

## 5. Redis

| Item | Value |
|------|-------|
| Container | `menugreen_redis` (`redis:7-alpine`) |
| State | `healthy` |
| Auth password | Đã cấu hình qua `.env` / Doppler |
| Test auth | Đang kiểm tra với mật khẩu hiện tại |

Lưu ý: `menugreen_redis` đang chạy với xác thực Redis đã được cấu hình trong `docker-compose.prod.yml`.

---

## 6. Production Environment Variables

Các biến môi trường production hiện được quản lý chính bằng **Doppler** (`project: menugreen`, `config: prd`). CI/CD sẽ lấy secrets từ Doppler, build `.env`, rồi upload lên Lightsail trước mỗi deploy.

- Source of truth: Doppler `prd`
- `.env` trên Lightsail hiện là file do CI/CD sinh ra
- Lưu ý: nếu `.env` trên server khác Doppler, có thể do chưa chạy lại deploy sau khi đổi Doppler config

### Trạng thái hiện tại

- `JwtSettings__SecretKey`: **trống** trên `.env` server
- `JwtSettings__Issuer`: **trống** trên `.env` server
- `JwtSettings__Audience`: **trống** trên `.env` server
- `ConnectionStrings__Redis`: đang là `:,password=` trên `.env` server

### Một số biến then chốt

- `DB_HOST`: RDS endpoint
- `DB_PORT`: `5432`
- `DB_NAME`: `MenuGreenDb`
- `DB_USER`: `postgres`
- `DB_PASSWORD`: đã lưu trong Doppler
- `ASPNETCORE_URLS`: `http://+:5000`
- `ASPNETCORE_HTTP_PORTS`: `5000`
- `REDIS_PASSWORD`: đã lưu trong Doppler
- `JWT`, `SePay`, `Firebase`, `AI` configs: quản lý trong Doppler `prd`

---

## 7. Docker Status

### Containers

| Name | Image | State | Ports |
|------|-------|-------|-------|
| `menugreen_api` | `menugreensystem-api` | `unhealthy` | `0.0.0.0:5000->5000/tcp`, `10000/tcp` |
| `menugreen_redis` | `redis:7-alpine` | `healthy` | `6379/tcp` |

### Networks

| Name | Driver |
|------|--------|
| `menugreen-net` | `bridge` |

### Volumes

| Name | Ghi chú |
|------|---------|
| `menugreensystem_redis_data` | Đang dùng |
| `menugreensystem_postgres_data` | Đã xóa |
| `menugreensystem_grafana_data` | Đã xóa |
| `menugreensystem_prometheus_data` | Đã xóa |

### Lưu ý

- `menugreen_api` đang `unhealthy`, nên kiểm tra log container và health endpoint `/health`.
- Stack hiện đang chạy bằng Docker Compose theo `docker-compose.prod.yml`.

---

## 8. Deployment

| Item | Trạng thái |
|------|-----------|
| Script deploy | `scripts/deploy.sh` |
| Compose prod | `docker-compose.prod.yml` |
| Env file | `.env` |
| Monitoring compose | `docker-compose.monitoring.yml` |

### Hướng dẫn deploy nhanh

```bash
cd ~/apps/MenuGreenSystem
chmod +x scripts/deploy.sh
./scripts/deploy.sh production
```

### Kiểm tra sau deploy

```bash
# Health API
curl -sf http://localhost:5000/health

# Container status
docker compose -f docker-compose.prod.yml ps

# Log API
docker compose -f docker-compose.prod.yml logs -f api

# Log Redis
docker compose -f docker-compose.prod.yml logs -f redis
```

---

## 9. Cần làm tiếp

- [x] Xác định nguyên nhân `menugreen_api` unhealthy: `.env` trên Lightsail đang thiếu JWT values.
- [ ] Trigger lại CI/CD trên branch `Tuan` để CI lấy secrets từ Doppler `prd`, build `.env` mới và deploy.
- [ ] Sau deploy, xác minh `/health` trở về `200` và `menugreen_api` chuyển sang `healthy`.
- [ ] Kiểm tra Redis auth/config nếu cần bật xác thực.
- [ ] Bật/tắt monitoring stack tùy mục tiêu vận hành.
- [ ] Đặt backup RDS + retention policy.
- [ ] Xác nhận CORS, SSL và domain production.
