# Project Status - MenuGreen

**Last updated:** 2026-07-05

---

## ✅ Production Systems

### Backend API
| Property | Value |
|----------|-------|
| **URL** | `https://api.menugreen.food` |
| **Server** | AWS Lightsail (Ubuntu 22.04) |
| **IP** | `52.77.218.100` |
| **Port** | 5000 |
| **Docker Image** | `anhtuan21112004/menugreensystem:latest` |

### Database
| Property | Value |
|----------|-------|
| **Endpoint** | `menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com` |
| **Engine** | PostgreSQL 18.3 |
| **Region** | Singapore (ap-southeast-1) |
| **Database** | `menugreendb` |

### Frontend Web
| Property | Value |
|----------|-------|
| **URL** | `https://www.menugreen.food` |
| **Platform** | Vercel |
| **Repo** | `frontend-web` |

### Mobile App (Flutter)
| Property | Value |
|----------|-------|
| **Package** | `com.menugreen.app` |
| **Platform** | Google Play (CH Play) |

---

## 🔧 Technical Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Cloudflare CDN                          │
│                   (SSL + Proxy + Cache)                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Nginx Reverse Proxy                      │
│               (Port 443 → localhost:5000)                   │
│                   + CORS Headers                            │
│                   + api.menugreen.food                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    .NET 9 API (Docker)                      │
│                 MenuGreen.API v1.0.0                        │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ PostgreSQL  │  │   Redis     │  │   SignalR Hub       │  │
│  │  (AWS RDS)  │  │  (Cache)    │  │   (Notifications)   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 CI/CD Pipeline

```
Git Push → GitHub Actions → Docker Hub → Server Deploy
                                              │
                                              ▼
                                    ┌─────────────────┐
                                    │ 1. SSH to Server│
                                    │ 2. Pull .env    │
                                    │    from Doppler │
                                    └────────┬────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ 3. Backup DB    │ ← pg_dump
                                    └────────┬────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ 4. Pull Image   │
                                    └────────┬────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ 5. EF Migration │
                                    └────────┬────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ 6. Health Check │
                                    └─────────────────┘
```

---

## 🛡️ Security Features

- ✅ JWT Authentication
- ✅ Role-based Access Control (Admin, Coach, User)
- ✅ Rate Limiting (Global, AI, Auth, OTP policies)
- ✅ CORS configured for frontend domains
- ✅ HTTPS via Cloudflare
- ✅ Environment secrets via Doppler
- ✅ Firebase Admin SDK configured

---

## 📋 Feature Status

| Feature | API | UI Flutter | Status |
|---------|-----|-----------|--------|
| **Auth** (Register/Login/OTP/Google) | ✅ | ✅ | Complete |
| **Onboarding** (5 bước) | ✅ | ✅ | Complete |
| **Profile & Health** | ✅ | ✅ | Complete |
| **Allergy Management** | ✅ | ✅ | Complete |
| **Discover/Khám phá** | ✅ | ✅ | Complete |
| **Nutrition Tracking** | ✅ | ✅ | **Core - 100%** |
| **Meal Plan** | ✅ | ✅ | **Complete** |
| **Notification** | ✅ | ✅ | **Complete** |
| **Subscription/SePay** | ✅ | ✅ | **Complete** |
| **Recommendation** | ✅ | 🟡 | Partial |
| **AI Assistant** | ✅ | ⏳ | Placeholder |
| **Analytics** | ✅ | ❌ | Admin only |

---

## 📝 Issues Resolved

| # | Issue | Date | Status |
|---|-------|------|--------|
| 1 | CI/CD không build cho Tuan branch | 2026-07-01 | ✅ Fixed |
| 2 | Duplicate variable name | 2026-07-01 | ✅ Fixed |
| 3 | Environment variable loading | 2026-07-01 | ✅ Fixed |
| 4 | Redis key name mismatch | 2026-07-01 | ✅ Fixed |
| 5 | CI/CD YAML syntax | 2026-07-01 | ✅ Fixed |
| 6 | Docker Compose volumes | 2026-07-01 | ✅ Fixed |
| 7 | **CORS Configuration** | **2026-07-05** | **✅ Fixed** |

---

## 🚀 Quick Commands

```bash
# SSH to server
ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100

# Check containers
docker ps

# View logs
docker logs menugreen_api --tail 50 -f

# Restart API
docker restart menugreen_api

# Manual deploy
docker pull anhtuan21112004/menugreensystem:latest
docker compose -f docker-compose.prod.yml up -d api
```

---

## 📁 Documentation Structure

```
docs/
├── PROJECT_STATUS.md              # This file - Overview
├── README_USER_WORKFLOW.md       # User workflows
├── README_WORKFLOW_API_STATUS.md # API + UI status
├── CI_CD.md                     # CI/CD pipeline guide
├── issues.md                    # Issue tracker
├── cors-config.md               # CORS configuration
├── lightsail-setup.md           # Server setup
├── features/                    # Feature documentation
│   ├── index.md
│   ├── RECOMMENDATION.md
│   ├── AI_ASSISTANT.md
│   ├── ANALYTICS.md
│   └── MEAL_PLAN.md
└── monitoring/
    └── uptimerobot-setup.md
```

---

## ⏭️ Next Steps

### High Priority
- [ ] Test full authentication flow
- [ ] Test meal plan creation
- [ ] Test AI features integration

### Medium Priority
- [ ] Setup monitoring (Prometheus, Grafana)
- [ ] Add automated testing
- [ ] Mobile app submission to Play Store

### Low Priority
- [ ] Performance optimization
- [ ] API documentation (Swagger UI)

---

*Last updated: 2026-07-05*
