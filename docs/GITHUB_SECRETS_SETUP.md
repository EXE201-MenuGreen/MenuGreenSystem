# GitHub Secrets Setup Guide

## Tổng quan

GitHub Secrets cần thiết để CI/CD pipeline có thể:
- SSH vào server Lightsail
- Kết nối database AWS RDS
- Truy cập Redis

---

## Danh sách Secrets cần tạo

### 1. SSH & Server

| Secret Name | Mô tả | Ví dụ |
|-------------|--------|-------|
| `LIGHTSAIL_HOST` | IP public của Lightsail | `54.123.45.67` |
| `LIGHTSAIL_SSH_KEY` | Private key SSH (PEM format) | `-----BEGIN RSA PRIVATE KEY-----\n...` |
| `LIGHTSAIL_USER` | SSH username | `ubuntu` |

### 2. Database (AWS RDS)

| Secret Name | Mô tả | Ví dụ |
|-------------|--------|-------|
| `DB_HOST` | RDS endpoint | `menugreen-db.xxxxx.us-east-1.rds.amazonaws.com` |
| `DB_PORT` | Database port | `5432` |
| `DB_NAME` | Database name | `menugreen` |
| `DB_USER` | Database username | `postgres` |
| `DB_PASSWORD` | Database password | `your_secure_password` |
| `DB_SSL_MODE` | SSL mode | `Require` |

### 3. Redis

| Secret Name | Mô tả | Ví dụ |
|-------------|--------|-------|
| `REDIS_HOST` | Redis host | `localhost` hoặc `redis` (trong Docker) |
| `REDIS_PASSWORD` | Redis password | `your_redis_password` |
| `REDIS_PORT` | Redis port | `6379` |

### 4. Grafana

| Secret Name | Mô tả | Ví dụ |
|-------------|--------|-------|
| `GF_SECURITY_ADMIN_PASSWORD` | Grafana admin password | `grafana_admin_password` |

---

## Cách thêm Secrets

### Cách 1: Qua GitHub Web UI (Đơn giản nhất)

#### Bước 1: Truy cập Settings

1. Mở GitHub repo của bạn
2. Click **Settings** (tab trên menu)
3. Ở sidebar bên trái, click **Secrets and variables** → **Actions**

#### Bước 2: Tạo từng Secret

1. Click **New repository secret**
2. Điền thông tin:

   ```
   Name: LIGHTSAIL_HOST
   Secret: 54.123.45.67
   ```
3. Click **Add secret**

#### Bước 3: Thêm tất cả secrets

Lặp lại cho các secrets còn lại.

---

### Cách 2: Qua GitHub CLI

```bash
# Cài đặt gh nếu chưa có
# (Windows PowerShell)
winget install GitHub.cli

# Login
gh auth login

# Thêm secrets
gh secret set LIGHTSAIL_HOST --body "54.123.45.67"
gh secret set LIGHTSAIL_SSH_KEY --body "$(cat ~/.ssh/id_rsa)"
gh secret set DB_HOST --body "menugreen-db.xxxxx.us-east-1.rds.amazonaws.com"
gh secret set DB_PASSWORD --body "your_db_password"
gh secret set REDIS_PASSWORD --body "your_redis_password"
```

---

## Chi tiết từng Secret

### LIGHTSAIL_HOST

```bash
# Lấy IP từ AWS Console
# AWS Console → Lightsail → Instances → <your-instance> → Public IP
```

### LIGHTSAIL_SSH_KEY

```bash
# Tạo SSH key mới (nếu chưa có)
ssh-keygen -t rsa -b 4096 -C "github-actions@menugreen" -f ~/.ssh/lightsail_deploy

# Đọc private key
cat ~/.ssh/lightsail_deploy
```

**Quan trọng:** Copy toàn bộ output bao gồm `-----BEGIN RSA PRIVATE KEY-----` và `-----END RSA PRIVATE KEY-----`

### Database Connection String (trong .env production)

```bash
# Ví dụ
DB_CONNECTION_STRING="Host=menugreen-db.xxxxx.us-east-1.rds.amazonaws.com;Port=5432;Database=menugreen;Username=postgres;Password=your_password;SSL Mode=Require"
```

---

## Cấu hình SSH Key trên Lightsail

### Bước 1: Lấy Public Key

```bash
cat ~/.ssh/lightsail_deploy.pub
# Output: ssh-rsa AAAA... github-actions@menugreen
```

### Bước 2: Thêm vào Lightsail

1. AWS Console → Lightsail → Instances
2. Click vào instance của bạn
3. Tab **Connect** → **Connect using SSH**
4. Sau khi login, chạy:

```bash
# Tạo thư mục .ssh nếu chưa có
mkdir -p ~/.ssh

# Thêm public key vào authorized_keys
echo "ssh-rsa AAAA..." >> ~/.ssh/authorized_keys

# Set quyền
chmod 600 ~/.ssh/authorized_keys
```

### Bước 3: Verify SSH Access

```bash
ssh -i ~/.ssh/lightsail_deploy ubuntu@54.123.45.67
```

---

## Kiểm tra Secrets đã hoạt động

### Cách 1: Chạy workflow thủ công

1. GitHub → **Actions** tab
2. Chọn workflow (e.g., "CI/CD Pipeline")
3. Click **Run workflow** → **Run workflow**
4. Theo dõi logs để xem có lỗi SSH/DB connection không

### Cách 2: Kiểm tra logs

```bash
# GitHub CLI
gh run list --limit 1
gh run view <run-id> --log
```

---

## Troubleshooting

### Lỗi "Permission denied (publickey)"

**Nguyên nhân:** SSH key không đúng hoặc chưa được thêm vào server.

**Fix:**
```bash
# Kiểm tra key format trong GitHub secret
# Phải là multi-line với \n

# Test SSH thủ công
ssh -vvv -i ~/.ssh/lightsail_deploy ubuntu@54.123.45.67
```

### Lỗi "Connection refused" database

**Nguyên nhân:** Security group chưa mở port hoặc sai endpoint.

**Fix:**
1. Kiểm tra RDS endpoint đúng
2. Kiểm tra Security Group → Inbound rules:
   ```
   Type: PostgreSQL
   Protocol: TCP
   Port: 5432
   Source: <Lightsail IP>/32
   ```

### Lỗi "ECONNREFUSED" Redis

**Nguyên nhân:** Redis chưa chạy hoặc sai password.

**Fix:**
```bash
# Test Redis connection từ server
redis-cli -h localhost -p 6379 -a your_password ping
```

---

## Security Best Practices

### ✅ Nên làm

1. **Sử dụng IAM Role** thay vì hardcode credentials (nếu có thể)
2. **Rotate passwords** định kỳ (3-6 tháng)
3. **Sử dụng SSL/TLS** cho tất cả connections
4. **Giới hạn IP** trong Security Groups
5. **Sử dụng Secrets** thay vì environment variables trong code

### ❌ Không nên

1. Commit credentials vào code
2. Share secrets qua email/chat
3. Sử dụng password yếu
4. Mở port 22 (SSH) cho all IPs

---

## Quick Setup Checklist

```
□ Tạo SSH key cho deployment
□ Thêm public key vào Lightsail
□ Test SSH login thành công
□ Tạo RDS instance (hoặc dùng existing)
□ Tạo secrets trên GitHub:
  □ LIGHTSAIL_HOST
  □ LIGHTSAIL_SSH_KEY
  □ DB_HOST
  □ DB_PORT
  □ DB_NAME
  □ DB_USER
  □ DB_PASSWORD
  □ REDIS_PASSWORD
  □ GF_SECURITY_ADMIN_PASSWORD
□ Test CI/CD workflow
□ Xác minh deployment thành công
```
