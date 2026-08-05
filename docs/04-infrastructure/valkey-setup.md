# Valkey Cache Setup - MenuGreen

## Endpoint

```
menugreen-redis-p9zkb6.serverless.apse1.cache.amazonaws.com:6379
```

## Các bước tiếp theo

### 1. Setup VPC Peering

**Tạo VPC Peering Connection:**

1. AWS Console → **VPC** → **Peering Connections** → **Create peering connection**

2. Điền thông tin:
   ```
   Name: menugreen-lightsail-to-default
   
   Requester VPC:
     Account: Your account
     Region: Asia Pacific (Singapore)
     VPC: <Lightsail VPC ID>  ← Cần tìm (CIDR: 172.26.0.0/20)
   
   Select another VPC to peer with:
     Account: Your account
     Region: Same region
     VPC: vpc-027fe1936a9691968
   ```

3. Click **"Create peering connection"**

4. **Accept request:**
   - VPC → Peering Connections
   - Chọn connection vừa tạo
   - Actions → **Accept request** → **Accept**

---

### 2. Update Route Tables

**2a. Lightsail VPC Route Table:**
- VPC → Route Tables → tìm route table của Lightsail VPC (CIDR `172.26.0.0/20`)
- Edit routes → Add:
  ```
  Destination: 172.31.0.0/20
  Target: pcx-xxxxxxxx (peering connection vừa tạo)
  ```

**2b. Default VPC Route Table:**
- VPC → Route Tables → tìm route table của Default VPC (`vpc-027fe1936a9691968`)
- Edit routes → Add:
  ```
  Destination: 172.26.0.0/20
  Target: pcx-xxxxxxxx (peering connection vừa tạo)
  ```

---

### 3. Update Doppler Secrets

Thêm/Update secrets trong Doppler:

| Secret | Value |
|--------|-------|
| `REDIS_HOST` | `menugreen-redis-p9zkb6.serverless.apse1.cache.amazonaws.com` |
| `REDIS_PORT` | `6379` |

---

### 4. Trigger Deploy lại API

```bash
# SSH vào Lightsail
ssh -i ~/.ssh/LightsailDefaultKey-ap-southeast-1.pem ubuntu@menugreen-api

# Trigger deploy
cd /home/ubuntu/menugreen
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

---

### 5. Test kết nối

```bash
# SSH vào Lightsail
ssh -i ~/.ssh/LightsailDefaultKey-ap-southeast-1.pem ubuntu@menugreen-api

# Test kết nối Redis
telnet menugreen-redis-p9zkb6.serverless.apse1.cache.amazonaws.com 6379

# Hoặc dùng redis-cli
docker exec -it <container_name> redis-cli -h menugreen-redis-p9zkb6.serverless.apse1.cache.amazonaws.com -p 6379 PING
```

Kết quả mong đợi: `PONG`

---

## Thông tin AWS Resources

| Resource | ID | VPC | CIDR |
|----------|-----|-----|------|
| Valkey Cache | menugreen-redis | vpc-027fe1936a9691968 | 172.31.0.0/20 |
| Security Group | sg-0dc90180317672e2a | vpc-027fe1936a9691968 | - |
| Lightsail Instance | menugreen-api | (Lightsail VPC) | 172.26.0.0/20 |

## Inbound Rules của Security Group

| Port | Source | Description |
|------|--------|-------------|
| 6379 | 172.31.0.0/16 | Valkey access from MenuGreen VPC |
| 6379 | 172.26.0.0/20 | Valkey access from Lightsail VPC |

## Status Checklist

- [x] Valkey Cache đã tạo
- [ ] VPC Peering Connection đã tạo
- [ ] VPC Peering đã Accept
- [ ] Route Table Lightsail VPC đã update
- [ ] Route Table Default VPC đã update
- [ ] Doppler secrets đã update
- [ ] API đã deploy lại
- [ ] Test kết nối thành công
