# AWS Lightsail Setup Guide - MenuGreen

## Mục lục

1. [Tạo AWS Account](#1-tạo-aws-account)
2. [Tạo Lightsail Instance](#2-tạo-lightsail-instance)
3. [Cấu hình Firewall](#3-cấu-hình-firewall)
4. [Kết nối SSH](#4-kết-nối-ssh)
5. [Cài đặt Docker](#5-cài-đặt-docker)
6. [Deploy MenuGreen](#6-deploy-menugreen)
7. [Cấu hình Domain (Optional)](#7-cấu-hình-domain-optional)
8. [Setup SSL (Optional)](#8-setup-ssl-optional)

---

## 1. Tạo AWS Account

### Bước 1.1: Đăng ký AWS

1. Truy cập: https://aws.amazon.com
2. Click **"Create an AWS Account"**
3. Điền thông tin:
   - Email address
   - Password
   - AWS account name
4. Chọn **"Personal"** account type
5. Điền thông tin cá nhân
6. Thêm thông tin thanh toán (Credit card)
   - **Lưu ý**: Cần có thẻ tín dụng/ghi nợ quốc tế (Visa, Mastercard)
   - AWS sẽ charge $1 để verify thẻ (sẽ hoàn lại)
7. Xác minh danh tính qua phone
8. Chọn Support plan: **Basic (Free)**

### Bước 1.2: Mặc định có gì miễn phí?

| Service        | Free Tier                                   |
| -------------- | ------------------------------------------- |
| Lightsail      | 3 tháng đầu ($3.50-$10/month instance free) |
| RDS PostgreSQL | 750 giờ/tháng (db.t3.micro)                 |
| S3             | 5GB storage                                 |
| CloudWatch     | 10 metrics                                  |

---

## 2. Tạo Lightsail Instance

### Bước 2.1: Truy cập Lightsail Console

1. Login AWS Console: https://console.aws.amazon.com
2. Search "Lightsail" hoặc truy cập: https://lightsail.aws.amazon.com
3. Click **"Create instance"**

### Bước 2.2: Cấu hình Instance

```
┌─────────────────────────────────────────────────────────────────────────┐
│  CREATE AN INSTANCE                                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Location:                                                             │
│  ├─ Region: Asia Pacific (Singapore) hoặc Asia Pacific (Tokyo)        │
│  └─ Availability Zone: Any (single zone OK for now)                   │
│                                                                         │
│  Instance image:                                                       │
│  └─ Platform: Linux/Unix                                               │
│  └─ Blueprint: Ubuntu 22.04 LTS                                        │
│     └─ [✅] Include launch scripts (optional - skip for now)           │
│                                                                          │
│  Instance plan:                                                        │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  $3.50/mo - Nano                          [CURRENTLY FREE 3 MO] │  │
│  │  ├─ 512 MB RAM, 1 vCPU, 20 GB SSD                               │  │
│  │  └─ 1 TB Transfer                                              │  │
│  ├─────────────────────────────────────────────────────────────────┤  │
│  │  $5/mo - Micro                             [CURRENTLY FREE 3 MO] │  │
│  │  ├─ 1 GB RAM, 1 vCPU, 40 GB SSD                                │  │
│  │  └─ 2 TB Transfer                                              │  │
│  ├─────────────────────────────────────────────────────────────────┤  │
│  │  $10/mo - Small  ★ RECOMMENDED          [CURRENTLY FREE 3 MO] │  │
│  │  ├─ 2 GB RAM, 1 vCPU, 60 GB SSD                                │  │
│  │  └─ 3 TB Transfer                                              │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  Identify your instance:                                               │
│  └─ Instance name: menugreen-server                                    │
│                                                                         │
│  [Create instance]                                                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Bước 2.3: Giải thích các Plans

| Plan          | RAM     | vCPU  | SSD      | Transfer | Phù hợp                       |
| ------------- | ------- | ----- | -------- | -------- | ----------------------------- |
| Nano $3.5     | 512MB   | 1     | 20GB     | 1TB      | Demo, test                    |
| Micro $5      | 1GB     | 1     | 40GB     | 2TB      | Light production              |
| **Small $10** | **2GB** | **1** | **60GB** | **3TB**  | **✅ Production (~5k users)** |

**Khuyến nghị**: Chọn **Small $10** (hiện tại free 3 tháng đầu)

### Bước 2.4: Đợi Instance khởi tạo

- Thời gian: ~2-5 phút
- Status sẽ chuyển từ "Pending" → "Running"

---

## 3. Cấu hình Firewall

### Bước 3.1: Mở Firewall Ports

1. Trong Lightsail console, click vào instance vừa tạo
2. Click tab **"Networking"**
3. Firewall hiện tại:

```
┌─────────────────────────────────────────────────────────────────────────┐
│  FIREWALL                                                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  IPv6 Firewall                                                         │
│  ┌─────────────────┬────────────────┬─────────────────────────────────┐ │
│  │ Protocol       │ Port           │ Source                          │ │
│  ├─────────────────┼────────────────┼─────────────────────────────────┤ │
│  │ SSH            │ TCP 22         │ Anywhere (0.0.0.0/0)           │ │
│  │ HTTP           │ TCP 80         │ Anywhere (0.0.0.0/0)           │ │
│  │ HTTPS          │ TCP 443        │ Anywhere (0.0.0.0/0)           │ │
│  └─────────────────┴────────────────┴─────────────────────────────────┘ │
│                                                                         │
│  [ + Add rule ]  [ + Another rule ]                                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Bước 3.2: Thêm Rules cần thiết

Click **"+ Add rule"** và thêm:

| Protocol | Port     | Source                               |
| -------- | -------- | ------------------------------------ |
| Custom   | TCP 3000 | Anywhere                             |
| Custom   | TCP 8080 | Anywhere                             |
| Custom   | TCP 9090 | Anywhere                             |
| Custom   | TCP 2375 | My IP (Docker management - tạm thời) |

**Sau khi setup xong, nên restrict port 2375 về My IP**

---

## 4. Kết nối SSH

### Phương 1: Lightsail Browser SSH (Dễ nhất)

1. Trong Lightsail console, click instance
2. Click **"Connect using SSH"**
3. Terminal sẽ mở trong browser

### Phương 2: PuTTY (Windows)

1. Download PuTTY: https://www.putty.org/
2. Download private key:
   - Click instance → **"Account"** → **"SSH keys"**
   - Download default key hoặc create new
3. Convert .pem to .ppk (nếu cần):
   - Mở PuTTYgen → Load .pem file → Save private key
4. Connect với PuTTY:
   - Host: Public IP của instance
   - Port: 22
   - Connection → SSH → Auth → Browse .ppk file

### Phương 3: Windows Terminal / Git Bash (Khuyến nghị)

1. Download SSH key:
   - Lightsail → Account → SSH keys
   - Download default key (e.g., `LightsailDefaultKey.pem`)

2. Connect:

```bash
# Set permissions cho key file
chmod 400 ~/Downloads/LightsailDefaultKey.pem

# Connect
ssh -i ~/Downloads/LightsailDefaultKey.pem ubuntu@<PUBLIC_IP>
```

### Bước 4.1: Lấy Public IP

1. Trong Lightsail console, click instance
2. Copy **Public IP** (ví dụ: `54.123.45.67`)

### Bước 4.2: Test Connection

```bash
ssh -i ~/Downloads/LightsailDefaultKey.pem ubuntu@54.123.45.67

# Nếu hỏi "Are you sure you want to continue connecting?"
# Gõ: yes
```

### Bước 4.3: Verify Connection

```
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-1051-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

  System information as of Mon Jun 29 10:00:00 UTC 2026

  0 updates can be applied immediately.

Last login: Mon Jun 29 09:00:00 2026 from 203.0.113.1
ubuntu@menugreen-server:~$
```

---

## 5. Cài đặt Docker

### Bước 5.1: Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### Bước 5.2: Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group (không cần sudo cho docker)
sudo usermod -aG docker ubuntu

# Verify Docker installation
docker --version
# Output: Docker version 26.x.x
```

### Bước 5.3: Install Docker Compose

```bash
# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker-compose --version
# Output: Docker Compose version v2.x.x
```

### Bước 5.4: Logout và Login lại

```bash
# Thoát SSH
exit

# Login lại để áp dụng docker group
ssh -i ~/Downloads/LightsailDefaultKey.pem ubuntu@54.123.45.67

# Verify không cần sudo
docker ps
# Output: CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES
```

---

## 6. Deploy MenuGreen

### Bước 6.1: Cài đặt Git

```bash
sudo apt install -y git
```

### Bước 6.2: Clone Project

```bash
# Tạo directory cho app
mkdir -p apps && cd apps

# Clone project (thay URL bằng repo của bạn)
git clone https://github.com/your-username/MenuGreenSystem.git

# Vào directory
cd MenuGreenSystem
```

### Bước 6.3: Tạo Docker Network

```bash
docker network create menugreen-net
```

### Bước 6.4: Configure Environment Variables

```bash
# Copy template .env.example
cp .env.example .env

# Edit .env với giá trị của bạn
nano .env

# Hoặc generate htpasswd password cho monitoring
cd monitoring/scripts
chmod +x generate-password.sh
./generate-password.sh admin
# Nhập password mới khi được yêu cầu

# Copy output vào monitoring/nginx/.htpasswd
cd ../nginx
nano .htpasswd
# Paste nội dung đã generate

# Quay lại root directory
cd ~/apps/MenuGreenSystem
```

**Lưu ý quan trọng:**
- File `.env` KHÔNG được commit lên Git (đã có trong `.gitignore`)
- Chỉ cần điền các biến trong `.env`, `docker-compose.yml` đã dùng `${VAR}` rồi
- Grafana password được lấy từ `GF_SECURITY_ADMIN_PASSWORD` trong `.env`
- Nginx basic auth password được lấy từ `NGINX_BASIC_AUTH_PASSWORD` trong `.env`

### Bước 6.5: Sử dụng Docker Compose Production (Khuyến nghị)

Dự án đã cung cấp file `docker-compose.prod.yml` để deploy production:

**Tại sao dùng `docker-compose.prod.yml`?**
- Chỉ deploy services cần thiết (API + DB + Redis)
- Port DB/Redis chỉ bind localhost (`127.0.0.1`) để tăng security
- Không bao gồm monitoring stack trong deploy chính (monitoring sẽ setup sau)
- Giảm attack surface và tài nguyên server

```bash
# Build image
docker-compose -f docker-compose.prod.yml build --no-cache

# Start services
docker-compose -f docker-compose.prod.yml up -d

# Xem logs
docker-compose -f docker-compose.prod.yml logs -f
```

### Bước 6.6: Deploy bằng Script (Tự động hóa)

```bash
# Download deploy script (hoặc đã có sẵn trong repo)
cd ~/apps/MenuGreenSystem/scripts

# Chmod +x
chmod +x deploy.sh

# Chạy deploy (cần sudo)
sudo ./deploy.sh
```

Script sẽ tự động:
- Kiểm tra Docker + Docker Compose
- Tạo Docker network nếu chưa có
- Build images
- Start DB/Redis, chờ DB sẵn sàng
- Chạy EF migrations (nếu dotnet CLI có sẵn)
- Start API
- Chạy health check

### Bước 6.7: Deploy thủ công (nếu cần)

```bash
cd ~/apps/MenuGreenSystem

# Build image
docker-compose -f docker-compose.prod.yml build

# Start services theo thứ tự
docker-compose -f docker-compose.prod.yml up -d db redis

# Chờ DB ready (kiểm tra)
docker-compose -f docker-compose.prod.yml exec db pg_isready -U postgres

# Chạy EF migrations (nếu cần)
cd backend/MenuGreen.API
dotnet ef database update --no-build
cd ~/apps/MenuGreenSystem

# Start API
docker-compose -f docker-compose.prod.yml up -d api
```

### Bước 6.8: Verify Services

```bash
# Kiểm tra container status
docker-compose -f docker-compose.prod.yml ps

# Output mong đợi:
# NAME                IMAGE               COMMAND              SERVICE
# menugreen_db        postgres:15-alpine  "docker-entrypoint..." db
# menugreen_api       menugreen_api       "dotnet ..."        api
# menugreen_redis     redis:7-alpine      "redis-server ..."   redis

# Test API
curl http://localhost:5000/health

# Test qua Nginx (nếu đã setup domain)
curl http://your-domain.com/health
```

---

## 7. Cấu hình Domain (Optional)

### Bước 7.1: Mua Domain (nếu chưa có)

Mua domain tại:

- Namecheap (~$10/năm)
- GoDaddy (~$12/năm)
- Google Domains (~$12/năm)
- Cloudflare Registrar (~$9/năm)

### Bước 7.2: Tạo Static IP tĩnh

1. Trong Lightsail console → **"Networking"**
2. Click **"Create static IP"**
3. Attach vào instance của bạn
4. **Quan trọng**: Ghi nhớ Static IP

### Bước 7.3: Point DNS về Lightsail

1. Vào domain registrar (nơi bạn mua domain)
2. Tìm DNS settings
3. Thêm records:

| Type  | Name | Value                                      |
| ----- | ---- | ------------------------------------------ |
| A     | @    | `<STATIC_IP>`                              |
| A     | www  | `<STATIC_IP>`                              |
| CNAME | @    | `<STATIC_IP>.singapore.cloudapp.azure.com` |

**Ví dụ với Cloudflare:**

```
┌─────────────────────────────────────────────────────────────────────────┐
│  DNS Settings - yourdomain.com                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Type    Name    Content                    Proxy status   TTL         │
│  ─────   ────   ──────────────────────     ────────────   ────         │
│  A       @       54.123.45.67              DNS only       Auto        │
│  A       www     54.123.45.67              DNS only       Auto        │
│                                                                         │
│  [ + Add record ]                                                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

4. Đợi 5-30 phút để DNS propagate

### Bước 7.4: Test Domain

```bash
# Thay your-domain.com bằng domain thật
curl http://your-domain.com/health
```

---

## 8. Setup SSL (Let's Encrypt)

### Bước 8.1: Cài đặt Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### Bước 8.2: Lấy SSL Certificate

```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Làm theo prompts:
# Enter email: your-email@example.com
# Accept terms: A
# Share email: N
# Redirect HTTP to HTTPS: 2 (Redirect)
```

### Bước 8.3: Verify SSL

```bash
# Test SSL certificate
curl https://your-domain.com/health

# Check certificate expiration
sudo certbot certificates

# Output:
# Certificate name: your-domain.com
# Valid from: Mon Jun 29 10:00:00 2026
# Valid until: Sun Sep 27 10:00:00 2026
# SSL Grade: A+
```

### Bước 8.4: Auto-renewal (Certbot tự làm)

```bash
# Test renewal
sudo certbot renew --dry-run

# Kiểm tra cron job đã được tạo
sudo systemctl status certbot.timer
```

---

## 9. Setup Alerts (Cuối cùng)

### Bước 9.1: Cài đặt Alert Script Dependencies

```bash
sudo apt install -y bc mailutils curl
```

### Bước 9.2: Configure Alerts

```bash
cd ~/apps/MenuGreenSystem/monitoring/scripts
nano alert.sh

# Sửa các dòng sau:
ALERT_EMAIL="your-email@example.com"
```

### Bước 9.3: Setup Cron Job

```bash
# Edit crontab
crontab -e

# Thêm dòng này (every 5 minutes):
*/5 * * * * /home/ubuntu/apps/MenuGreenSystem/monitoring/scripts/alert.sh >> /var/log/menugreen-alert.log 2>&1

# Save và exit
```

---

## Checklist Setup Hoàn chỉnh

```
┌─────────────────────────────────────────────────────────────────────────┐
│  MENUGREEN SETUP CHECKLIST                                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  AWS Account:                                                           │
│  [ ] Đăng ký AWS account                                              │
│  [ ] Verify credit card                                                │
│                                                                         │
│  Lightsail Instance:                                                   │
│  [ ] Tạo instance (Ubuntu 22.04, Small $10)                           │
│  [ ] Mở firewall ports (80, 443, 3000, 8080, 9090)                   │
│  [ ] Tạo static IP (optional nhưng khuyến nghị)                       │
│                                                                         │
│  SSH Connection:                                                        │
│  [ ] Download SSH key                                                  │
│  [ ] Connect thành công                                                │
│                                                                         │
│  Docker:                                                                │
│  [ ] Cài Docker                                                         │
│  [ ] Cài Docker Compose                                                │
│  [ ] Test docker ps                                                    │
│                                                                         │
│  MenuGreen Deployment:                                                 │
│  [ ] Clone project                                                     │
│  [ ] Tạo Docker network                                               │
│  [ ] docker-compose up -d                                             │
│  [ ] Verify tất cả containers running                                  │
│  [ ] Test /health endpoint                                             │
│                                                                         │
│  Domain & SSL:                                                          │
│  [ ] Point DNS về Lightsail IP                                        │
│  [ ] Setup SSL với Let's Encrypt                                       │
│  [ ] Test HTTPS                                                        │
│                                                                         │
│  Monitoring:                                                            │
│  [ ] Setup monitoring sau khi deploy production thành công              │
│                                                                         │
│  Security:                                                              │
│  [ ] Đổi all default passwords                                         │
│  [ ] Close port 2375 (Docker)                                         │
│  [ ] Setup firewall rules restrictively                                │
│  [ ] Backup credentials                                                │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Chi phí

| Item                          | Cost                            |
| ----------------------------- | ------------------------------- |
| AWS Lightsail Small (2GB RAM) | **$0** (Free 3 tháng đầu)       |
| Sau 3 tháng                   | $10/tháng                       |
| Domain                        | ~$10-15/năm                     |
| SSL                           | Miễn phí (Let's Encrypt)        |
| **Total Year 1**              | **~$20-30** (chủ yếu là domain) |

---

## Troubleshooting

### Không kết nối được SSH?

```bash
# Kiểm tra Security Groups
Lightsail → Instance → Networking → Firewall

# Kiểm tra instance status
Lightsail → Instances → Kiểm tra status (Running?)

# Reset SSH keys
Lightsail → Account → SSH keys → Reset
```

### Docker containers không start?

```bash
# Xem logs
docker-compose logs -f

# Restart
docker-compose restart

# Rebuild nếu cần
docker-compose down
docker-compose up -d --build
```

### Health check fails?

```bash
# Check container status
docker-compose ps

# Check logs của API
docker-compose logs api

# Kiểm tra port đang listen
curl http://localhost:5000/health
```

### DNS không hoạt động?

```bash
# Flush DNS cache (local)
# Windows: ipconfig /flushdns
# Mac: sudo dscacheutil -flushcache

# Verify DNS propagation
dig your-domain.com
# hoặc
nslookup your-domain.com
```

---

## Support Links

- AWS Lightsail Documentation: https://docs.aws.amazon.com/lightsail/
- Docker Documentation: https://docs.docker.com/
- Let's Encrypt: https://letsencrypt.org/docs/
- UptimeRobot: https://uptimerobot.com/dashboard

---

**Tiếp theo**: [Sau khi deploy xong, setup Monitoring](./monitoring/README.md)
