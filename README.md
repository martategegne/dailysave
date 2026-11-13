# DailySave (የዕለት ቁጠባ)

> **Tagline:** Track Every Birr. Understand Your Money. Build Your Future.

**DailySave** is an accessible, secure, offline-first personal financial management application built with Flutter, Dart, BLoC, Clean Architecture, Node.js, and PostgreSQL.

---

## 🌟 Key Features

1. **Authoritative Financial Money Engine:**
   - Integer minor currency units (`amount_cents` in ETB cents, e.g. 1,000 ETB = `100000`). Zero floating-point arithmetic.
   - Core Formula: `Daily Savings = Daily Income - Daily Expenses`.
   - Distinguishes calculated net savings from actual money deposited into savings reserves.
   - Isolated loan repayments (debts borrowed vs. lent) preventing corruption of operational income/expenses.

2. **Offline-First Persistence & Cloud Synchronization:**
   - Local persistence via **Drift** (SQLite on native platforms, IndexedDB on Flutter Web).
   - Bi-directional synchronization engine (`/sync/push` & `/sync/pull`) with unique client mutation IDs, idempotency protection, soft-deletion tombstones, and Last-Write-Wins (LWW) conflict resolution.

3. **Pure Native Node.js & PostgreSQL Backend:**
   - Web server powered strictly by native Node.js `node:http` (**zero Express**).
   - PostgreSQL 18 with 6 versioned migrations managing 16 domain tables.
   - **Argon2id** password hashing and short-lived JWT access tokens (15m) with refresh token rotation (30d) and reuse theft detection.
   - Sliding-window rate limiting token bucket.

4. **Advanced Financial Modules:**
   - **Recurring Transactions:** Daily, weekly, monthly, and annual schedules with review-before-apply and duplicate prevention.
   - **Community Savings Groups:** Equb and savings circles with role permissions (`creator`, `admin`, `treasurer`, `member`) and strict member financial privacy.
   - **Visual-First Notifications:** Budget alert thresholds (75% warning, 90% danger, 100% critical), goal milestones, and bill reminders.
   - **Privacy-Gated AI Financial Assistant:** Grounded spending pattern analyzer requiring explicit user opt-in consent with clear informational disclaimers.

---

## 🧠 AI Financial Assistant: Models, Technical Rationale & Roadmap

DailySave integrates an intelligent financial diagnostic assistant designed under strict **financial safety, privacy-first, and zero-hallucination** principles.

### 1. Active Production Model: Deterministic Statistical & Heuristic Expert Model

Rather than deploying an ungrounded black-box neural network that can fabricate numbers, DailySave uses a **Deterministic Statistical Anomaly & Rule-Based Expert Model** for core financial intelligence:

- **Mathematical Foundations:**
  - **Rolling-Window Velocity & $\Delta\%$ Trend Analysis:** Compares current spending velocity against previous period baselines ($M_0$ vs $M_{-1}$) to detect spending acceleration ($>15\%$ escalation triggers).
  - **Pareto Category Concentration Analysis:** Computes category expenditure distribution ($C_i / E_{total}$) to detect budget leaks where a single non-essential category consumes $>40\%$ of outflows.
  - **Savings Ratio Classification ($R_{savings} = \frac{Income - Expenses}{Income}$):**
    - $R < 0\% \implies$ **Deficit Alert** (spending exceeds income, negative cashflow warning).
    - $0\% \le R < 20\% \implies$ **Growth Opportunity** (sustainable, but below recommended 20% cushion).
    - $R \ge 20\% \implies$ **Strong Savings Habit** (reinforces positive financial behavior).
  - **Integer Minor-Unit Grounding:** Every calculation operates strictly on 64-bit integer cents (`BIGINT` in PostgreSQL, `IntColumn` in Drift). Floating-point arithmetic is strictly forbidden.

### 2. Design Rationale: Why This Model Was Chosen

| Criteria | Deterministic Statistical Model (DailySave) | Pure Generative LLM (e.g., ChatGPT / Raw Prompts) |
| :--- | :--- | :--- |
| **Numerical Accuracy** | **100% Exact:** Grounded directly in PostgreSQL ACID ledger. Zero rounding error. | **Prone to Hallucination:** Struggles with arithmetic and balance consistency. |
| **Data Privacy** | **Zero Data Leakage:** Operates locally on device or private server. No external network transmission. | **Privacy Risk:** Financial transaction history and PII sent to third-party cloud APIs. |
| **Execution Latency** | **Sub-millisecond (< 5 ms):** Instantaneous execution on edge or backend. | **High Latency (1.5s - 5s):** Dependent on network connectivity and token streaming. |
| **Offline Resilience** | **100% Offline Capable:** Runs seamlessly in intermittent Ethiopian network conditions. | **Zero Offline Functionality:** Completely fails without high-speed Internet access. |
| **Auditability & Explainability**| **Deterministic Audit Trail:** Every insight points to exact ledger records and explicit mathematical formulas. | **Black-Box:** Unpredictable responses that cannot be legally or financially audited. |
| **Operational Cost** | **\$0.00:** Zero per-token API charges or subscription fees. | **Recurring Token Costs:** Becomes expensive as transaction history grows. |

### 3. AI Safety & Privacy Guardrails

1. **Explicit User Consent Gate:** The AI engine is disabled by default. No data analysis executes until the user explicitly toggles `ai_consent_enabled = true` in their settings (`POST /api/v1/ai/consent`).
2. **Never Invents Records:** The assistant has read-only access to aggregated metrics and cannot create, modify, or delete ledger transactions.
3. **Mandatory Informational Disclaimers:** Every insight returned explicitly states: *"AI-generated recommendations are informational suggestions and do not replace professional financial advice."*

### 4. Advanced Machine Learning Roadmap (Local & Edge)

- **Time-Series Predictive Forecasting (ML):**
  - **Facebook Prophet / Holt-Winters Exponential Smoothing:** Integration for predictive cashflow forecasting, seasonal Ethiopian holiday expense projections (e.g., Enkutatash, Ganna, Fasika, Eid), and end-of-month balance depletion warnings.
  - **Isolation Forest / Local Outlier Factor (LOF):** Multi-dimensional anomaly detection identifying atypical transaction amounts or unusual spending velocity on-device and on-premise without reliance on external cloud AI providers.

5. **Localization & Ethiopian Calendar:**
   - Trilingual support: English (`en`), Amharic (`am` - አማርኛ), and Afaan Oromo (`om`).
   - Bidirectional Ethiopian Ge'ez calendar converter (13 months with Pagume leap year logic) and Ge'ez numerals (፩, ፪, ፫, ..., ፻).
   - Localized Ethiopian Birr currency formatter.

6. **WCAG 2.2 AA Accessibility:**
   - Screen-reader semantics (`formatCurrencyForScreenReader`, `announce`).
   - Minimum 48x48 dp interactive touch targets.
   - Color contrast ratio compliance (>4.5:1 for body text, >3.0:1 for large text/icons).
   - Accessible keyboard focus order and non-audio-only visual alerts.

---

## 🏗 System Architecture

The application enforces **feature-based Clean Architecture** across both frontend and backend:

```
dailysave/
├── backend/                        # Pure Node.js & PostgreSQL Backend (No Express)
│   ├── src/
│   │   ├── config/                 # Env validation & PG Connection Pool (ACID)
│   │   ├── core/                   # Router, Body Parser, Response Envelope, Validator
│   │   ├── middlewares/            # Auth JWT, CORS, Sliding-window Rate Limiter
│   │   ├── controllers/            # REST API Controllers (Auth, Tx, Budget, Sync, etc.)
│   │   ├── repositories/           # PostgreSQL Data Access (Multi-tenant scoped)
│   │   ├── services/               # Argon2id, JWT Rotation, AI Assistant
│   │   ├── database/migrations/    # Versioned SQL DDL Migrations (001 to 006)
│   │   └── server.js               # Native http.createServer Entrypoint
│   └── test/                       # 48 Automated Node.js Tests (100% Passing)
├── website/                        # SEO-Friendly Multilingual Public Website (14 Pages)
│   ├── blog/                       # Financial Literacy & Educational Guides
│   ├── css/styles.css              # Accessible WCAG 2.2 AA Stylesheet
│   ├── js/site.js                  # Accessible Language Switcher & FAQ Accordion
│   ├── sitemap.xml                 # Search Engine XML Sitemap with Hreflang
│   └── robots.txt                  # Public Web Crawling Directives
├── lib/                            # Flutter Client (Web, Android, iOS)
│   ├── app/                        # App root & GoRouter Navigation
│   ├── core/                       # Database (Drift), Theme, Accessibility, L10n, Sync
│   └── features/                   # Feature-based Clean Architecture Modules
├── scripts/                        # Production Verification & Backup Utilities
└── test/                           # 34 Automated Flutter Tests (100% Passing)
```

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.x
- Node.js v20+ (v24 recommended)
- PostgreSQL 18 running on `localhost:5432`

### 1. Database Setup
```powershell
Set-Location backend
npm install
node src/database/migrate.js
```

### 2. Start Backend Server
```powershell
node src/server.js
# Backend runs on http://localhost:4000
```

### 3. Run Flutter Application
```powershell
Set-Location ..
flutter pub get
flutter run -d chrome
```

---

## 🧪 Testing

### Backend Test Suite (58 Tests Passing)
```powershell
Set-Location backend
node --test
```

### Flutter Test Suite (35 Tests Passing)
```powershell
Set-Location ..
flutter test
flutter analyze
```

### Production Verification Suite (6/6 Checks Passing)
```powershell
node scripts/verify-production.js
```

---

## 📚 Detailed Documentation & V1.0 Deliverables

### Production Release & Audits
- [Comprehensive Final Delivery Report](docs/final-delivery-report.md)
- [Version 1.0 Release Documentation & Runbook](docs/release-v1.0.md)
- [Product Feature Verification Matrix](docs/feature-audit-matrix.md)
- [Beta Testing Program & Feedback Pipeline](docs/beta-testing-program.md)
- [WCAG 2.2 AA Accessibility Compliance Evaluation](docs/accessibility-audit-wcag22.md)
- [Security Audit, Threat Model & Disaster Recovery](docs/security-audit-and-reliability.md)
- [Ethiopian Market Launch Strategy & Marketing Kit](docs/launch-strategy.md)

### Technical Architecture & Operations
- [System Architecture](docs/architecture.md)
- [Database Schema & Migrations](docs/database-schema.md)
- [REST API Contract](docs/api-contract.md)
- [Security & Privacy Review](docs/security.md)
- [Accessibility Guide (WCAG 2.2 AA)](docs/accessibility.md)
- [Production Operations & Deployment Manual](docs/production-deployment.md)
- [Cloud Hosting & Free-Tier Provider Matrix](docs/hosting-comparison.md)
- [Domain Architecture & DNS Configuration](docs/dns-and-domains.md)
- [Google Search Console & Privacy Analytics](docs/search-console-and-analytics.md)
- [Content Strategy & Ethiopian Financial Literacy](docs/content-strategy.md)
- [Role-Based Access Control & Permission Matrix](docs/roles-and-permissions.md)
- [Workspace Architecture & Multi-Tenant Isolation](docs/workspace-architecture.md)
- [Business Model & Monetization Strategy](docs/business-model.md)
- [Subscription System & Feature Entitlements](docs/subscription-system.md)
- [Payment Gateway Integration & Ethiopian Provider Evaluation](docs/billing-integration.md)

---

## ⚖️ License
Proprietary & Confidential - DailySave Project.
