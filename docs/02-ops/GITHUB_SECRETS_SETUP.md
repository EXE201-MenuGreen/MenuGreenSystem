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
- Doppler token
- Passwords

**Lưu ý bảo mật:**
- Secrets được mã hóa và không hiển thị sau khi lưu
- Không commit credentials vào code
- Không commit giá trị thật của secrets vào documentation
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

#### 1. `DOPPLER_TOKEN`

**Mô tả**: Service token để CI đọc secrets từ Doppler `project: menugreen`, `config: prd`

**Lưu ý**:
- Chỉ cấp quyền đọc config `prd` trong Doppler
- Xoay token định kỳ

---

### Tùy chọn (Optional)

#### 2. `LIGHTSAIL_HOST`

**Mô tả**: Địa chỉ IP hoặc DNS của Lightsail server

**Cách lấy**:
```bash
# Từ AWS Console
# Services → Lightsail → Instances → <instance-name> → Networking
```

**Ví dụ**:
```
<LIGHTSAIL_IP>
```

---

#### 3. `LIGHTSAIL_USER`

**Mô tả**: SSH username để login vào server

**Giá trị**:
```
ubuntu
```
(mặc định cho Ubuntu instances)

---

#### 4. `LIGHTSAIL_SSH_KEY`

**Mô tả**: Private key SSH để authenticate với Lightsail

**Lưu ý**:
- Dùng key dạng `BEGIN OPENSSH PRIVATE KEY` hoặc `BEGIN RSA PRIVATE KEY`
- Giữ private key an toàn
- Không share hoặc commit vào git

---

## Verification

### Test Secrets trong GitHub Actions

```yaml
- name: Debug Secrets
  run: |
    echo "Doppler token is set: ${{ secrets.DOPPLER_TOKEN != '' }}"
```

### Test SSH Connection

```bash
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

---

## Best Practices

### 1. Rotate Secrets Regularly

```bash
# Schedule: Monthly
# 1. Generate new secret in Doppler / provider
# 2. Update GitHub Secret
# Settings → Secrets and variables → Actions → <secret> → Update
```

### 2. Audit Secret Usage

1. Vào **Settings** → **Audit log**
2. Filter: `secrets`
3. Check ai đã access secrets

### 3. Never Log Secrets

```yaml
# SAI ❌
- run: echo "Password: ${{ secrets.SECRET_NAME }}"

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
head -1 ~/.ssh/menugreen_deploy
# Should start with: -----BEGIN ...

# Fix permissions
chmod 600 ~/.ssh/menugreen_deploy
```

---

## Security Checklist

- [ ] Tất cả required secrets đã được thêm
- [ ] SSH key có permissions đúng (600)
- [ ] Secrets đã được test trong CI/CD
- [ ] Không có secrets trong code hoặc docs

---

## Liên hệ

Nếu cần hỗ trợ:
- GitHub Issues: [Link](https://github.com/EXE201-MenuGreen/MenuGreenSystem/issues)
- Email: devops@menugreen.com
