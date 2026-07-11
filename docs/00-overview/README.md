# MenuGreen Documentation

## Quick Start

|| Document | Description |
||----------|-------------|
|| **[PROJECT_STATUS.md](./PROJECT_STATUS.md)** | **Start here** - Tong quan trang thai project |
|| **[SPEC.md](./SPEC.md)** | **System Specification** - Kien truc, module, API, DB, deployment, business rules |
|| **[03-features/README.md](../03-features-overview/README.md)** | **Tai lieu tinh nang canonical** - 19 file theo nhom nghiep vu (01-19) |

---

## Infrastructure & Deployment

|| Document | Description |
||----------|-------------|
|| **[ARCHITECTURE.md](../01-deployment/ARCHITECTURE.md)** | Kiến trúc tổng quan, GitHub Secrets, Server Info |
|| **[CI_CD.md](../01-deployment/CI_CD.md)** | CI/CD pipeline, deploy, rollback |
|| **[SERVER_SETUP.md](../01-deployment/SERVER_SETUP.md)** | Server setup guide |
|| **[SECRETS_MANAGEMENT.md](../01-deployment/SECRETS_MANAGEMENT.md)** | Quản lý secrets (Doppler) |
|| **[NGINX_AND_CORS.md](../01-deployment/NGINX_AND_CORS.md)** | CORS & Nginx configuration |
|| **[GITHUB_SECRETS_SETUP.md](../GITHUB_SECRETS_SETUP.md)** | GitHub secrets configuration |

---

## Features Documentation (canonical tai `features/`)

|| # | File | Mo ta | API | UI |
||---|------|-------|-----|-----|
|| 01 | [Auth & Account](../features/01-auth-and-account.md) | Dang ky/dang nhap, Onboarding, Profile, Health Profile | Done | Done |
|| 02 | [Nutrition Tracking](../features/02-nutrition-tracking.md) | Nhat ky an uong, can nang, dashboard | Done | Done |
|| 03 | [Meal Plan](../features/03-meal-plan.md) | Lap ke hoach bua an, streaks, reminders | Done | Done |
|| 04 | [Discover & Allergy](../features/04-discover-and-allergy.md) | Kham pha mon, allergy profile, portion converter | Done | Done |
|| 05 | [Recommendation Engine](../features/05-recommendation-engine.md) | Goi y ca nhan hoa, feedback, retrain | Done | Done |
|| 06 | [AI Assistant & Coach](../features/06-ai-assistant-and-coach.md) | Chatbot AI, contextual coach, function calling | Done | Placeholder |
|| 07 | [Notification](../features/07-notification.md) | Settings, inbox, tracking | Done | Done |
|| 08 | [Subscription & Payment](../features/08-subscription-and-payment.md) | SubscriptionPlan, UserSubscription, SePay | Done | Done |
|| 09 | [Analytics](../features/09-analytics.md) | Activity log, funnel, cohort, churn (Admin only) | Done | Out of scope |
|| 10 | [Vietnam Local Features](../features/10-vietnam-local-features.md) | Daily Starter, Gym/PT, Food Capture, Safety, Allergy Badge, Planned vs Actual + Nutrition Formulas | Done | Partial |
|| 11 | [Premium Programs](../features/11-premium-programs.md) | Premium Programs: milestone, check-in, graduation | Done | Not Done |
|| 12 | [Meal Templates](../features/12-meal-templates.md) | Luu nhanh bua an lap lai, log tu template | Done | Not Done |
|| 13 | [Micro-Learning](../features/13-micro-learning.md) | The kien thuc dinh duong ngan, quiz | Done | Not Done |
|| 14 | [Adaptive Reminders](../features/14-adaptive-reminders.md) | Optimal meal time, scheduled reminders, snooze | Done | Not Done |
|| 15 | [PT Review](../features/15-pt-review.md) | PT review weekly report, shareable link | Done | Not Done |
|| 16 | [Budget Management](../features/16-budget-management.md) | Cau hinh ngan sach an uong | Done | Not Done |
|| 17 | [Coaches Ecosystem](../features/17-coaches.md) | Coach-Student dai han, PT dashboard | Done | Not Done |
|| 18 | [Ingredient Catalog](../features/18-ingredient-catalog.md) | CRUD nguyen lieu tho, search | Done | Not Done |
|| 19 | [User Management](../features/19-user-management.md) | Doi mat khau, admin user CRUD | Done | Partial |

---

## References

|| Document | Description |
||----------|-------------|
|| **[README_BACKEND_OVERVIEW.md](../02-backend/README_BACKEND_OVERVIEW.md)** | Backend architecture overview |
|| **[AI_YELLOW_ITEMS_IMPLEMENTATION_REPORT.md](../03-features-overview/AI_YELLOW_ITEMS_IMPLEMENTATION_REPORT.md)** | AI implementation report |
|| **[02-backend/](../02-backend/)** | Backend models documentation |

---

## Issue Tracking

|| Document | Description |
||----------|-------------|
|| **[issues.md](../issues.md)** | Issue tracker - bugs, errors, solutions |

---

## Production URLs

|| Service | URL |
||---------|-----|
|| **Backend API** | `https://api.menugreen.food` |
|| **Frontend Web** | `https://www.menugreen.food` |
|| **Swagger** | `https://api.menugreen.food/swagger` |

---

## Server Info

```bash
# SSH
ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100

# App location
cd ~/apps/MenuGreenSystem
```

---

*Last updated: 2026-07-11 — Reorganized 01-deployment/ docs (8 → 6 files, archive removed).*
