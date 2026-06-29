# GitHub Secrets Setup Guide

Hướng dẫn chi tiết cách setup GitHub Secrets cho MenuGreen CI/CD pipeline.

## Mục lục

- [Tổng quan](#tổng-quan)
- [Cách thêm Secrets](#cách-thêm-secrets)
- [Danh sách Secrets](#danh-sách-secrets)
- [Cách lấy giá trị](#cách-lấy-giá-trị)
- [Verification](#verification)

---

## Tổng quan

GitHub Secrets được sử dụng để lưu trữ thông tin nhạy cảm trong CI/CD pipeline:
- SSH keys
- Database credentials
- API keys
- Passwords

**Lưu ý bảo mật:**
- Secrets được mã hóa và không hiển thị sau khi lưu
- Không commit credentials vào code
- Rotate secrets định kỳ

---

## Cách thêm Secrets

### Bước 1: Truy cập Repository Settings

1. Mở repository GitHub: `https://github.com/EXE201-MenuGreen/MenuGreenSystem`
2. Click **Settings** (Tab ở menu trên cùng)
3. Trong sidebar, click **Secrets and variables** → **Actions**

### Bước 2: Thêm Secret mới

1. Click **New repository secret**
2. Nhập thông tin:
   - **Name**: Tên secret (theo quy tắc bên dưới)
   - **Secret**: Giá trị secret

### Bước 3: Verify

Sau khi thêm, secret sẽ hiển thị dạng `***` (masked)

---

## Danh sách Secrets

### Bắt buộc

#### 1. `LIGHTSAIL_HOST`

**Mô tả**: Địa chỉ IP hoặc DNS của Lightsail server

**Cách lấy**:
```bash
# Từ AWS Console
# Services → Lightsail → Instances → <instance-name> → Networking

# Hoặc dùng AWS CLI
aws lightsail get-instances --output json | jq -r '.instances[].publicIpAddress'
```

**Ví dụ**:
```
REDACTED_EXAMPLE_IP
```
hoặc
```
ec2-54-123-456-78.compute-1.amazonaws.com
```

---

#### 2. `LIGHTSAIL_USER`

**Mô tả**: SSH username để login vào server

**Giá trị**:
```
ubuntu
```
(mặc định cho Ubuntu instances)

---

#### 3. `LIGHTSAIL_SSH_KEY`

**Mô tả**: Private key SSH để authenticate với Lightsail

**Cách lấy**:

1. **Tạo SSH key pair** (nếu chưa có):
```bash
# Generate new SSH key
ssh-keygen -t rsa -b 4096 -C "menugreen-deploy" -f ~/.ssh/menugreen_deploy

# View private key
cat ~/.ssh/menugreen_deploy
```

2. **Thêm public key vào Lightsail**:
   - AWS Console → Lightsail → Instance → **Connect** → **Reset SSH key**
   - Paste nội dung public key

3. **Copy private key**:
```bash
cat ~/.ssh/menugreen_deploy
```
Copy toàn bộ output bao gồm `-----BEGIN RSA PRIVATE KEY-----` và `-----END RSA PRIVATE KEY-----`

**Lưu ý**:
- Giữ private key an toàn
- Không share hoặc commit vào git
- Đảm bảo permissions: `chmod 600 ~/.ssh/menugreen_deploy`

---

#### 4. `DB_HOST`

**Mô tả**: Hostname của PostgreSQL database

**Cách lấy**:
```bash
# Từ AWS RDS Console
# Services → RDS → Databases → <database> → Connectivity

# Hoặc connection string
psql "postgresql://user:pass@host:5432/dbname" -c "SELECT current_setting('server_version_num');"
```

**Ví dụ**:
```
menugreen-db.xxxxx.us-east-1.rds.amazonaws.com
```

---

#### 5. `DB_PORT`

**Mô tả**: Port của PostgreSQL

**Giá trị mặc định**:
```
5432
```

---

#### 6. `DB_NAME`

**Mô tả**: Tên database

**Ví dụ**:
```
menugreen
```

---

#### 7. `DB_USER`

**Mô tả**: Database username

**Ví dụ**:
```
menugreen_admin
```

---

#### 8. `DB_PASSWORD`

**Mô tả**: Database password

**Lưu ý**:
- Nên dùng strong password
- Rotate định kỳ
- Không dùng password có trong dictionary

---

#### 9. `JWT_SECRET`

**Mô tả**: Secret key để sign JWT tokens

**Cách tạo**:
```bash
# Generate random secret
openssl rand -base64 32

# Hoặc Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# Hoặc Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

**Yêu cầu**:
- Độ dài tối thiểu: 32 characters
- Nên dùng random string

---

### Tùy chọn (Optional)

#### 10. `REDIS_PASSWORD`

**Mô tả**: Password cho Redis cache

**Cách tạo**:
```bash
openssl rand -base64 24
```

---

#### 11. `GF_SECURITY_ADMIN_PASSWORD`

**Mô tả**: Admin password cho Grafana

**Giá trị mặc định**:
```
REDACTED_ADMIN_PASSWORD
```

**Lưu ý**: Nên đổi password này trong production!

---

#### 12. `SLACK_WEBHOOK_URL`

**Mô tả**: Slack webhook để nhận alerts

**Cách lấy**:
1. Slack App → **Incoming Webhooks**
2. Create New Webhook
3. Chọn channel để nhận alerts
4. Copy webhook URL

**Ví dụ**:
```
https://your-slack-webhook.example.com/services/<TEAM_ID>/<WEBHOOK_ID>/<TOKEN>
```

**Lưu ý**: Thay thế bằng webhook URL thực của bạn khi setup.

---

#### 13. `ALERT_EMAIL`

**Mô tả**: Email để nhận alert notifications

**Ví dụ**:
```
devops@menugreen.com
```

---

#### 14. `SMTP_PASSWORD`

**Mô tả**: Password cho SMTP server (Alertmanager)

**Ví dụ** (Gmail SMTP):
```
your-app-specific-password
```

---

## Cách lấy giá trị

### AWS Lightsail

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure
aws configure

# Get instance IP
aws lightsail get-instances --output json | jq -r '.instances[] | "\(.name): \(.publicIpAddress)"'
```

### Database Connection String

```bash
# Format
Host=<DB_HOST>;Port=<DB_PORT>;Database=<DB_NAME>;Username=<DB_USER>;Password=<DB_PASSWORD>;SSL Mode=Require

# Example
Host=menugreen-db.xxxxx.us-east-1.rds.amazonaws.com;Port=5432;Database=menugreen;Username=admin;Password=secret;SSL Mode=Require
```

---

## Verification

### Test Secrets trong GitHub Actions

```yaml
- name: Debug Secrets
  run: |
    echo "DB Host: ${{ secrets.DB_HOST }}"
    echo "DB Port: ${{ secrets.DB_PORT }}"
    echo "DB Name: ${{ secrets.DB_NAME }}"
    # Không echo DB_PASSWORD!
```

### Test SSH Connection

```bash
# Test locally
ssh -i ~/.ssh/menugreen_deploy ubuntu@<LIGHTSAIL_HOST>

# Test from GitHub Actions
- name: Test SSH Connection
  uses: appleboy/ssh-action@v1.0.3
  with:
    host: ${{ secrets.LIGHTSAIL_HOST }}
    username: ${{ secrets.LIGHTSAIL_USER }}
    key: ${{ secrets.LIGHTSAIL_SSH_KEY }}
    script: |
      echo "SSH connection successful!"
      hostname
      uptime
```

### Test Database Connection

```bash
# Test from GitHub Actions
- name: Test DB Connection
  run: |
    PGPASSWORD=${{ secrets.DB_PASSWORD }} psql \
      -h ${{ secrets.DB_HOST }} \
      -p ${{ secrets.DB_PORT }} \
      -U ${{ secrets.DB_USER }} \
      -d ${{ secrets.DB_NAME }} \
      -c "SELECT version();"
```

---

## Best Practices

### 1. Rotate Secrets Regularly

```bash
# Schedule: Monthly
# 1. Generate new secret
openssl rand -base64 32

# 2. Update GitHub Secret
# Settings → Secrets and variables → Actions → <secret> → Update

# 3. Update server .env file
ssh ubuntu@<HOST> "echo 'JWT_SECRET=new_value' >> /home/ubuntu/apps/MenuGreenSystem/.env"

# 4. Restart services
ssh ubuntu@<HOST> "docker restart menugreen-api"
```

### 2. Audit Secret Usage

1. Vào **Settings** → **Audit log**
2. Filter: `secrets`
3. Check ai đã access secrets

### 3. Use Environment-specific Secrets

```yaml
# For staging environment
environment:
  name: staging
  url: https://staging.menugreen.com

# For production
environment:
  name: production
  url: https://api.menugreen.com
```

### 4. Never Log Secrets

```yaml
# SAI ❌
- run: echo "Password: ${{ secrets.DB_PASSWORD }}"

# ĐÚNG ✅
- run: echo "Database configured successfully"
```

---

## Troubleshooting

### Secret not found

```
Error: Input required and not supplied: secrets.SECRET_NAME
```

**Fix**: Kiểm tra secret đã được thêm đúng vào repository chưa

### Invalid SSH Key

```
Permission denied (publickey)
```

**Fix**:
```bash
# Verify key format
cat ~/.ssh/menugreen_deploy | head -1
# Should be: -----BEGIN RSA PRIVATE KEY-----

# Fix permissions
chmod 600 ~/.ssh/menugreen_deploy
```

### Database connection timeout

```
Connection timeout
```

**Fix**:
1. Kiểm tra DB security group allow inbound from GitHub IPs
2. Hoặc whitelist GitHub Actions IPs

---

## Security Checklist

- [ ] Tất cả required secrets đã được thêm
- [ ] SSH key có permissions đúng (600)
- [ ] Database password mạnh (min 16 chars)
- [ ] JWT secret đủ dài (min 32 chars)
- [ ] Không có secrets trong code
- [ ] Secrets đã được test trong CI/CD
- [ ] Backup plan cho secrets đã được tạo

---

## Liên hệ

Nếu cần hỗ trợ:
- GitHub Issues: [Link](https://github.com/EXE201-MenuGreen/MenuGreenSystem/issues)
- Email: devops@menugreen.com
