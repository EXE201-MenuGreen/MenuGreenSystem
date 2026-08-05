# MenuGreen Documentation

## Overview Structure

```
docs/
├── 00-overview/          # Project overview, status, specifications
├── 01-deployment/        # Deployment guides (VPS, Docker, CI/CD)
├── 02-backend/          # Backend architecture & models
├── 02-playstore/        # Play Store submission checklist
├── 03-features-overview/ # Feature overview & implementation reports
├── 04-infrastructure/   # Infrastructure docs (Redis, Performance)
├── 05-reports/          # Implementation reports & activity logs
├── 06-plans/            # Feature implementation plans
├── 07-issues/           # Issues tracking & changelog
├── 08-guides/           # Setup & configuration guides
├── features/            # Individual feature documentation
└── workflow/            # Workflow diagrams & user flows
```

## Quick Links

### Getting Started
- [Project Status](00-overview/PROJECT_STATUS.md)
- [Architecture Overview](01-deployment/ARCHITECTURE.md)
- [Backend Overview](02-backend/README_BACKEND_OVERVIEW.md)

### Deployment
- [Server Setup](01-deployment/SERVER_SETUP.md)
- [CI/CD Pipeline](01-deployment/CI_CD.md)
- [Secrets Management](01-deployment/SECRETS_MANAGEMENT.md)

### Infrastructure
- [Redis Cache Implementation](04-infrastructure/redis-cache-implementation.md)
- [Valkey Setup](04-infrastructure/valkey-setup.md)
- [Performance Analysis](04-infrastructure/performance-analysis-report.md)

### Features
- [Feature Index](features/)
- [Meal Plan](features/03-meal-plan.md)
- [Nutrition Tracking](features/02-nutrition-tracking.md)
- [Subscription & Payment](features/08-subscription-and-payment.md)
- [AI Assistant & Coach](features/06-ai-assistant-and-coach.md)

### Workflows
- [Workflow Index](workflow/)
- [User Workflow](workflow/user_workflow.md)
- [Gymer Workflow](workflow/gymer_workflow.md)
- [Coach Workflow](workflow/coach_workflow.md)

### Issues & Reports
- [Issue Tracker](07-issues/issues.md)
- [Changelog](07-issues/changes-2026-07-24.md)

## Folder Descriptions

### 00-overview/
- **PROJECT_STATUS.md** - Current project status, team, milestones
- **SPEC.md** - Technical specifications
- **README.md** - Overview index

### 01-deployment/
- **SERVER_SETUP.md** - VPS/Server setup guide
- **ARCHITECTURE.md** - System architecture diagram
- **CI_CD.md** - CI/CD pipeline configuration
- **NGINX_AND_CORS.md** - Nginx & CORS configuration
- **SECRETS_MANAGEMENT.md** - Secrets management guide
- **README.md** - Deployment index

### 02-backend/
- **README_BACKEND_OVERVIEW.md** - Backend architecture overview
- **backend_models_documentation.md** - Database models documentation

### 02-playstore/
- **PLAY_STORE_SUBMISSION_CHECKLIST.md** - Play Store submission checklist

### 03-features-overview/
- **README.md** - Features overview index
- **AI_YELLOW_ITEMS_IMPLEMENTATION_REPORT.md** - AI items implementation report

### 04-infrastructure/
- **redis-cache-implementation.md** - Redis/Valkey caching implementation
- **valkey-setup.md** - Valkey setup guide
- **performance-analysis-report.md** - Performance analysis report

### 05-reports/
- Implementation reports and activity logs

### 06-plans/
- Feature implementation plans

### 07-issues/
- **issues.md** - Issue tracker
- **changes-YYYY-MM-DD.md** - Changelog entries

### 08-guides/
- Setup and configuration guides

### features/
Individual feature documentation files (01-auth-and-account.md through 20-lucky-wheel.md)

### workflow/
- Workflow diagrams and user flow documentation

## Contributing

When adding new documentation:
1. Place in appropriate folder based on category
2. Use clear, descriptive filenames
3. Add entry to relevant README.md index
4. Use markdown formatting consistently
