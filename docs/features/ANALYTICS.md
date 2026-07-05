# Analytics APIs

**Status:** ✅ API Complete | ⏸️ UI Out of Scope (Admin only)

---

## Overview

Analytics APIs cung cấp dữ liệu thống kê cho admin dashboard:
- Activity logs
- Funnel analysis
- Cohort analysis
- Churn & retention
- Export data

> **Note:** UI cho analytics là Admin panel, không nằm trong mobile app scope.

---

## Activity Log

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Analytics/activity-log` | Ghi log hoạt động |
| `POST` | `/api/Analytics/activity-log/bulk` | Ghi nhiều logs |
| `GET` | `/api/Analytics/activity-log` | Lấy danh sách logs |
| `GET` | `/api/Analytics/activity-log/{id}` | Chi tiết log |

---

## Dashboard & Metrics

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Analytics/dashboard` | Dashboard tổng quan |
| `GET` | `/api/Analytics/summary` | Summary metrics |
| `GET` | `/api/Analytics/metrics` | Key metrics |
| `GET` | `/api/Analytics/top-events` | Top events |

---

## Funnel Analysis

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Analytics/funnel` | Funnel analysis |
| `POST` | `/api/Analytics/funnel/preview` | Preview funnel |
| `GET` | `/api/Analytics/funnel/meal-onboarding` | Meal onboarding funnel |
| `GET` | `/api/Analytics/funnel/subscription` | Subscription funnel |

---

## Cohort Analysis

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Analytics/cohort` | Cohort data |
| `GET` | `/api/Analytics/cohort/retention` | Retention rates |
| `GET` | `/api/Analytics/cohort/by-signup-date` | Cohorts by signup |
| `GET` | `/api/Analytics/cohort/by-first-meal-log` | Cohorts by first log |
| `GET` | `/api/Analytics/cohort/by-subscription` | Cohorts by subscription |

---

## Churn & Retention

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Analytics/drop-off` | Drop-off analysis |
| `GET` | `/api/Analytics/churn-risk` | Users at churn risk |
| `GET` | `/api/Analytics/inactive-users` | Inactive users |
| `GET` | `/api/Analytics/reactivation-opportunities` | Reactivation chances |

---

## Export

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Analytics/export/activity-log` | Export activity logs |
| `GET` | `/api/Analytics/export/funnel` | Export funnel data |
| `GET` | `/api/Analytics/export/cohort` | Export cohort data |

---

## Related Documents

- [User Workflow - Tracking](../README_USER_WORKFLOW.md)
- [System Workflows Overview](../README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md)

---

*Last updated: 2026-07-05*
