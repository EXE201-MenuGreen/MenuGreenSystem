# AWS Lightsail Setup Guide — MenuGreen

> **Last updated:** 2026-07-12 — Phản ánh server production hiện tại.
>
> **Đã sửa:** Bổ sung thông tin về self-signed catch-all cert, bỏ bước cài Doppler CLI thủ công (CD tự install).

## Mục lục

1. [Tạo AWS Account](#1-tạo-aws-account)
2. [Tạo Lightsail Instance](#2-tạo-lightsail-instance)
3. [Cấu hình Firewall](#3-cấu-hình-firewall)
4. [Kết nối SSH](#4-kết-nối-ssh)
5. [Cài đặt Docker](#5-cài-đặt-docker)
6. [Cài đặt Nginx](#6-cài-đặt-nginx)
7. [Cấu hình Server](#7-cấu-hình-server)
8. [Cấu hình Domain (Optional)](#8-cấu-hình-domain-optional)
9. [Setup SSL (Optional)](#9-setup-ssl-optional)

---

## 1. Tạo AWS Account

### Bước 1.1: Đăng ký AWS

1. Truy cập: https://aws.amazon.com
2. Click **"Create an AWS Account"**
3. Điền thông tin: email, password, AWS account name
4. Chọn **"Personal"** account type
5. Điền thông tin cá nhân
6. Thêm thông tin thanh toán (Visa/Mastercard quốc tế)
   - AWS charge $1 để verify thẻ (sẽ hoàn lại)
7. Xác minh danh tính qua phone
8. Chọn Support plan: **Basic (Free)**

### Free Tier (3 tháng đầu)

| Service        | Free Tier                                   |
| -------------- | ------------------------------------------- |
| Lightsail      | 3 tháng đầu ($3.50-$10/month instance free) |
| RDS PostgreSQL | 750 giờ/tháng (db.t3.micro)                 |
| S3             | 5GB storage                                 |

---

## 2. Tạo Lightsail Instance

### Bước 2.1: Truy cập Lightsail Console

1. Login AWS Console: https://console.aws.amazon.com
2. Search "Lightsail" hoặc truy cập: https://lightsail.aws.amazon.com
3. Click **"Create instance"**

### Bước 2.2: Cấu hình Instance (đang dùng)

```
Region:           Asia Pacific (Singapore) - ap-southeast-1
Blueprint:        Ubuntu 22.04 LTS
Instance plan:    $10/mo - Small
                  ├─ 2 GB RAM, 1 vCPU, 60 GB SSD
                  └─ 3 TB Transfer
Instance name:    menugreen-server
```

### Bước 2.3: Đợi Instance khởi tạo (~2-5 phút)

Status chuyển từ **Pending** → **Running**.

### Thông tin server hiện tại

| Property          | Value                                  |
|-------------------|----------------------------------------|
| **Public IP**     | `52.77.218.100`                        |
| **Domain**        | `api.menugreen.food` (A record → IP)   |
| **OS**            | Ubuntu 22.04 LTS                       |
| **RAM**           | 2 GB                                   |
| **Disk**          | 60 GB SSD                              |
| **App directory** | `/home/ubuntu/apps/menugreen`          |

---

## 3. Cấu hình Firewall

### Mở ports qua Lightsail Console

Vào instance → tab **"Networking"** → **IPv4 Firewall** → **+ Add rule**:

| Protocol | Port | Source             | Mục đích             |
|----------|------|--------------------|----------------------|
| SSH      | 22   | My IP / 0.0.0.0/0  | SSH                  |
| HTTP     | 80   | Anywhere           | Nginx (redirect HTTPS) |
| HTTPS    | 443  | Anywhere           | Nginx SSL            |

> **Không cần mở port 5000** ở firewall — Nginx reverse proxy từ 80/443 → localhost:5000 (API trong Docker).

> **Không cần mở port 5432** ở firewall — RDS ở AWS bên ngoài, kết nối qua internal network.

### Lightsail Firewall mặc định (sau khi setup)

```
┌─────────────────────────────────────────────┐
│  FIREWALL                                   │
├─────────────────────────────────────────────┤
│  Protocol   Port   Source                    │
│  ────────   ────   ──────                    │
│  SSH        TCP 22  Anywhere (0.0.0.0/0)    │
│  HTTP       TCP 80  Anywhere (0.0.0.0/0)    │
│  HTTPS      TCP 443 Anywhere (0.0.0.0/0)    │
└─────────────────────────────────────────────┘
```

---

## 4. Kết nối SSH

### Phương pháp khuyến nghị: Git Bash / Windows Terminal

1. Download SSH key từ Lightsail:
   - Lightsail → Account → SSH keys
   - Download default key `LightsailDefaultKey.pem`

2. Set permissions (Git Bash):
   ```bash
   chmod 400 ~/Downloads/LightsailDefaultKey.pem
   ```

3. Connect:
   ```bash
   ssh -i ~/Downloads/LightsailDefaultKey.pem ubuntu@52.77.218.100
   ```

> **Lưu ý:** Key có thể tên khác (`LightsailDefaultKeyPair.pem`). Cần thêm nội dung file này vào GitHub Secret `LIGHTSAIL_SSH_KEY`.

### Verify connection thành công

```
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-1051-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

Last login: ...
ubuntu@menugreen-server:~$
```

---

## 5. Cài đặt Docker

```bash
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user ubuntu to docker group (không cần sudo cho docker)
sudo usermod -aG docker ubuntu

# Logout và login lại để áp dụng group
exit

# Re-login
ssh -i ~/Downloads/LightsailDefaultKey.pem ubuntu@52.77.218.100

# Verify
docker --version        # Docker version 26.x.x
docker compose version  # Docker Compose version v2.x.x
docker ps               # Không cần sudo
```

---

## 6. Cài đặt Nginx

> Nginx chạy **trực tiếp trên host** (không phải Docker container) để tiết kiệm RAM.

```bash
# Cài Nginx
sudo apt install -y nginx certbot python3-certbot-nginx

# Tạo folder snippets
sudo mkdir -p /etc/nginx/snippets
sudo mkdir -p /etc/nginx/sites-enabled
```

### Self-signed cert cho catch-all HTTPS server

Deploy script cần một self-signed cert để Nginx có thể reject các request HTTPS với SNI không xác định (chỉ domain `api.menugreen.food` mới được route tới API). Cert này sẽ được `deploy-server.sh` **tự generate** nếu chưa có:

```
/etc/ssl/certs/menugreen-catchall.pem
/etc/ssl/private/menugreen-catchall.key
```

Bạn **không cần tạo thủ công** — chỉ cần đảm bảo `/etc/ssl/private/` tồn tại. User `ubuntu` mặc định có quyền `sudo` trên Ubuntu 22.04 nên có thể chạy `sudo openssl req -x509 ...` để generate cert.

> **Cấu hình chi tiết Nginx (CORS, proxy, SSL):** xem [NGINX_AND_CORS.md](./NGINX_AND_CORS.md) và `MenuGreenSystem/backend/nginx/deploy/README.md`.

---

## 7. Cấu hình Server

### 7.1 App directory

CD workflow tự tạo folder này. Không cần clone repo trên server.

```bash
sudo mkdir -p /home/ubuntu/apps/menugreen
sudo chown ubuntu:ubuntu /home/ubuntu/apps/menugreen
```

### 7.2 GitHub Actions SSH access

Thêm public key của GitHub Actions runner vào `~/.ssh/authorized_keys`:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Hoặc dùng Lightsail default key + paste vào GitHub Secret LIGHTSAIL_SSH_KEY
```

### 7.3 Doppler CLI

**KHÔNG cần cài thủ công** — `deploy-server.sh` tự download Doppler CLI ở lần deploy đầu tiên nếu chưa có:

```bash
# Tự động chạy bởi CD (chỉ khi command -v doppler fail):
mkdir -p ~/.local/bin
DOPPLER_VERSION="$(curl -fsSL https://api.github.com/repos/DopplerHQ/cli/releases/latest | jq -r .tag_name)"
curl -fsSL "https://github.com/DopplerHQ/cli/releases/download/${DOPPLER_VERSION}/doppler_${DOPPLER_VERSION#v}_linux_amd64.tar.gz" -o /tmp/doppler.tar.gz
tar -xzf /tmp/doppler.tar.gz -C ~/.local/bin doppler
```

Yêu cầu: `jq` phải có sẵn (Ubuntu 22.04 mặc định có).

### 7.4 Outbound connections cần thiết

Server cần kết nối ra ngoài đến:

| Destination                    | Port | Mục đích             |
|--------------------------------|------|----------------------|
| `registry-1.docker.io`         | 443  | Pull Docker image    |
| `api.doppler.com`              | 443  | Download secrets     |
| `<RDS_ENDPOINT>.rds.amazonaws.com` | 5432 | Kết nối PostgreSQL |
| `<REDIS_HOST>`                 | 6379 | Kết nối Redis (nếu managed) |

Không cần mở ports cho outbound — Lightsail mặc định cho phép tất cả outbound.

### 7.5 RDS Security Group

Vào **AWS Console → RDS → menugreen-db → Connectivity & security → Security group** → Edit inbound rules:

| Type            | Protocol | Port | Source            |
|-----------------|----------|------|-------------------|
| PostgreSQL      | TCP      | 5432 | `52.77.218.100/32` (IP Lightsail) |

### 7.6 Verify server

```bash
# Docker OK?
docker ps

# Network outbound
curl -fsSL https://api.doppler.com > /dev/null && echo "Doppler OK"
nc -zv <RDS_ENDPOINT> 5432

# Disk space
df -h
```

---

## 8. Cấu hình Domain (Optional - đã có api.menugreen.food)

### Bước 8.1: Tạo Static IP

1. Lightsail → **"Networking"** → **"Create static IP"**
2. Attach vào instance `menugreen-server`
3. Ghi nhớ Static IP

### Bước 8.2: Point DNS về Lightsail

Vào domain registrar (Namecheap/Cloudflare/GoDaddy), thêm A record:

```
api.menugreen.food  →  A  →  52.77.218.100
```

Đợi 5-30 phút để DNS propagate.

---

## 9. Setup SSL (Let's Encrypt)

```bash
# Lấy SSL certificate cho domain
sudo certbot --nginx -d api.menugreen.food

# Làm theo prompts:
# - Enter email: your-email@example.com
# - Accept terms: A
# - Share email: N
# - Redirect HTTP to HTTPS: 2 (Redirect)
```

### Verify SSL

```bash
sudo certbot certificates

# Test renewal
sudo certbot renew --dry-run

# Auto-renewal đã setup sẵn bởi certbot
sudo systemctl status certbot.timer
```

---

## Checklist Setup Hoàn chỉnh

```
┌──────────────────────────────────────────────────────┐
│  MENUGREEN SERVER SETUP CHECKLIST                    │
├──────────────────────────────────────────────────────┤
│                                                      │
│  AWS Account:                                         │
│  [✅] Đăng ký AWS account                            │
│  [✅] Verify credit card                              │
│                                                      │
│  Lightsail Instance:                                  │
│  [✅] Tạo instance Ubuntu 22.04, Small $10            │
│  [✅] Mở firewall: 22, 80, 443                       │
│  [✅] Static IP: 52.77.218.100                        │
│                                                      │
│  SSH:                                                 │
│  [✅] Download SSH key                               │
│  [✅] Test connect thành công                         │
│  [✅] LIGHTSAIL_SSH_KEY paste vào GitHub Secrets      │
│                                                      │
│  Software:                                            │
│  [✅] Docker installed                                │
│  [✅] Docker Compose plugin                           │
│  [✅] Nginx installed                                 │
│  [✅] Certbot installed                               │
│                                                      │
│  Database (RDS):                                      │
│  [✅] PostgreSQL RDS created                          │
│  [✅] Security group allow IP Lightsail               │
│  [✅] Database `menugreendb` exists                   │
│                                                      │
│  App directory:                                       │
│  [✅] /home/ubuntu/apps/menugreen exists              │
│  [✅] Owned by ubuntu:ubuntu                          │
│                                                      │
│  GitHub Secrets:                                      │
│  [✅] DOPPLER_TOKEN                                   │
│  [✅] LIGHTSAIL_HOST, USER, SSH_KEY                   │
│  [✅] DOCKERHUB_USERNAME, TOKEN                       │
│                                                      │
│  Domain & SSL:                                        │
│  [✅] api.menugreen.food A record → 52.77.218.100     │
│  [✅] SSL Let's Encrypt (auto-renew)                  │
│                                                      │
│  First deploy:                                        │
│  [✅] GitHub Actions backend-ci + backend-cd pass     │
│  [✅] Container `menugreen_api` running               │
│  [✅] Health check OK                                 │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## Chi phí

| Item                            | Cost                            |
|---------------------------------|---------------------------------|
| AWS Lightsail Small (2GB)       | $10/tháng                       |
| AWS RDS db.t3.micro             | ~$15/tháng (free tier hết)      |
| Domain `menugreen.food`         | ~$10/năm                        |
| SSL Let's Encrypt               | Miễn phí                        |
| **Total Month**                 | **~$25-30/tháng**               |

---

## Troubleshooting

### Không SSH được?

```bash
# Kiểm tra Security Group Lightsail
Lightsail → Instance → Networking → Firewall (đảm bảo có port 22)

# Reset SSH keys
Lightsail → Account → SSH keys → Reset
```

### Docker pull fail?

```bash
# Test outbound
curl -fsSL https://registry-1.docker.io/v2/ > /dev/null && echo "OK"

# Login Docker Hub (nếu image private)
sudo docker login -u anhtuan21112004
```

### Nginx không start?

```bash
sudo nginx -t           # Check syntax
sudo systemctl status nginx
sudo tail -50 /var/log/nginx/error.log
```

### RDS không kết nối?

```bash
# Test từ server
nc -zv <RDS_ENDPOINT> 5432
PGPASSWORD=xxx psql -h <RDS_ENDPOINT> -U postgres -d menugreendb
```

### Disk đầy?

```bash
# Cleanup Docker
sudo docker system prune -af --volumes

# Xem dung lượng lớn
sudo du -sh /var/log/*
sudo du -sh /tmp/*
```

---

## Support Links

- AWS Lightsail Docs: https://docs.aws.amazon.com/lightsail/
- Docker Docs: https://docs.docker.com/
- Let's Encrypt: https://letsencrypt.org/docs/
- Ubuntu Server Guide: https://ubuntu.com/server/docs

---

**Tiếp theo:** Sau khi setup xong, xem [ARCHITECTURE.md](./ARCHITECTURE.md) để hiểu kiến trúc và [CI_CD.md](./CI_CD.md) để hiểu flow deploy.
