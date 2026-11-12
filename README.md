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
├── lib/                            # Flutter Client (Web, Android, iOS)
│   ├── app/                        # App root & GoRouter Navigation
│   ├── core/                       # Database (Drift), Theme, Accessibility, L10n, Sync
│   └── features/                   # Feature-based Clean Architecture Modules
└── test/                           # 30 Automated Flutter Tests (100% Passing)
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

### Backend Test Suite (48 Tests)
```powershell
Set-Location backend
node --test
```

### Flutter Test Suite (30 Tests)
```powershell
Set-Location ..
flutter test
flutter analyze
```

---

## 📚 Detailed Documentation

- [System Architecture](docs/architecture.md)
- [Database Schema & Migrations](docs/database-schema.md)
- [REST API Contract](docs/api-contract.md)
- [Security & Privacy Review](docs/security.md)
- [Accessibility Guide (WCAG 2.2 AA)](docs/accessibility.md)
- [Production Deployment Manual](docs/deployment.md)

---

## ⚖️ License
Proprietary & Confidential - DailySave Project.
