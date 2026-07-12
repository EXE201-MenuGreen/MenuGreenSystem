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

Trạng thái chi tiết theo từng tính năng: xem bảng canonical tại **[03-features-overview/README.md](./03-features-overview/README.md)** (19 file `01-19` theo nhóm nghiệp vụ).

Tóm tắt nhanh:

| Feature | API | UI Flutter | Canonical |
|---------|-----|-----------|-----------|
| **Auth** (Register/Login/OTP/Google) | ✅ | ✅ | [01-auth-and-account](./features/01-auth-and-account.md) |
| **Onboarding** (5 bước) | ✅ | ✅ | [01-auth-and-account](./features/01-auth-and-account.md) |
| **Profile & Health** | ✅ | ✅ | [01-auth-and-account](./features/01-auth-and-account.md) |
| **Nutrition Tracking** | ✅ | ✅ | [02-nutrition-tracking](./features/02-nutrition-tracking.md) |
| **Meal Plan** | ✅ | ✅ | [03-meal-plan](./features/03-meal-plan.md) |
| **Discover/Khám phá** + Allergy + Portion | ✅ | ✅ | [04-discover-and-allergy](./features/04-discover-and-allergy.md) |
| **Recommendation** | ✅ | ✅ | [05-recommendation-engine](./features/05-recommendation-engine.md) |
| **AI Assistant & Coach** | ✅ | ⏳ Placeholder | [06-ai-assistant-and-coach](./features/06-ai-assistant-and-coach.md) |
| **Notification** | ✅ | ✅ | [07-notification](./features/07-notification.md) |
| **Subscription/SePay** | ✅ | ✅ | [08-subscription-and-payment](./features/08-subscription-and-payment.md) |
| **Analytics** | ✅ | ❌ Admin only | [09-analytics](./features/09-analytics.md) |
| **Vietnam Local Features** (Daily Starter, Gym/PT, Safety, Food Capture, Allergy Badge, Planned vs Actual) | ✅ | 🟡 Partial | [10-vietnam-local-features](./features/10-vietnam-local-features.md) |

> **Note:** Bảng tóm tắt ở đây mang tính overview. Trạng thái chi tiết (số endpoint, UI components, navigation flow, business rules) xem tại file canonical tương ứng.

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
├── 00-overview/                      # SPEC, README, PROJECT_STATUS
│   ├── SPEC.md
│   ├── README.md
│   └── PROJECT_STATUS.md
├── 01-deployment/                    # Deployment guides (ARCHITECTURE, CI_CD, NGINX_AND_CORS, SECRETS_MANAGEMENT, SERVER_SETUP)
├── 02-backend/                       # Backend models documentation, BE overview
├── 03-features-overview/                      # features/README, AI report
│   ├── README.md
│   └── AI_YELLOW_ITEMS_IMPLEMENTATION_REPORT.md
├── GITHUB_SECRETS_SETUP.md           # GitHub secrets (root-level)
├── features/                        # 19 canonical feature specs (01-19)
│   ├── 01-auth-and-account.md         # Auth + Onboarding + Profile + Health
│   ├── 02-nutrition-tracking.md       # Meal log + Weight + Dashboard
│   ├── 03-meal-plan.md                # Meal planning + reminders
│   ├── 04-discover-and-allergy.md     # Discover + Allergy + Portion
│   ├── 05-recommendation-engine.md    # Recommendation
│   ├── 06-ai-assistant-and-coach.md   # AI Assistant + AI Coach
│   ├── 07-notification.md             # Notification
│   ├── 08-subscription-and-payment.md # Subscription + SePay
│   ├── 09-analytics.md                # Analytics (Admin)
│   ├── 10-vietnam-local-features.md   # Vietnam features + Nutrition Formulas
│   ├── 11-premium-programs.md        # Premium Programs
│   ├── 12-meal-templates.md           # Meal Templates
│   ├── 13-micro-learning.md           # Micro-Learning
│   ├── 14-adaptive-reminders.md      # Adaptive Reminders
│   ├── 15-pt-review.md               # PT Review
│   ├── 16-budget-management.md        # Budget Management
│   ├── 17-coaches.md                 # Coaches Ecosystem
│   ├── 18-ingredient-catalog.md      # Ingredient Catalog
│   └── 19-user-management.md          # User Management
├── 00-overview/                      # SPEC, README, PROJECT_STATUS
│   ├── SPEC.md
│   ├── README.md
│   └── PROJECT_STATUS.md
├── 01-deployment/                    # Deployment guides (ARCHITECTURE, CI_CD, NGINX_AND_CORS, SECRETS_MANAGEMENT, SERVER_SETUP)
├── 02-backend/                       # Backend models documentation, BE overview
├── 03-features-overview/                      # features/README, AI report
│   ├── README.md
│   └── AI_YELLOW_ITEMS_IMPLEMENTATION_REPORT.md
├── GITHUB_SECRETS_SETUP.md           # GitHub secrets (root-level)
├── features/                         # 19 canonical feature specs (01-19)
└── issues.md                         # Issue tracker
```

> **Note:** Features 01-19 la canonical docs. Cac file cu da duoc xoa (2026-07-09).
>
> **System Specification:** [SPEC.md](./SPEC.md) — System-wide reference: kiến trúc, module, API, DB schema, deployment, Flutter app structure, Open Issues.

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

*Last updated: 2026-07-08*
