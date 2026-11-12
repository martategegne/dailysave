# DailySave System Architecture

DailySave is designed as an **offline-first, highly accessible, secure financial platform** adhering to **Clean Architecture** and **Domain-Driven Design (DDD)**.

---

## 1. Architectural Layers

### A. Flutter Presentation Layer
- **State Management:** BLoC (`flutter_bloc`) strictly separates business logic from UI rendering.
- **Routing:** Declarative, deep-linkable navigation powered by `go_router`.
- **UI System:** Material 3 with adaptive layouts across Mobile, Tablet, and Desktop Web.
- **Design Tokens:**
  - Primary Green: `#16865B`
  - Dark Navy: `#172554`
  - Soft Background: `#F7F9F8`
  - Warning Red: `#DC2626`
  - Success Green: `#16A34A`

### B. Flutter Domain & Data Layer
- **Domain:** Pure Dart entities (`FinancialTransaction`, `Budget`, `FinancialGoal`, `Debt`, `CommunityGroup`) and repository contracts. Free from framework dependencies.
- **Data:**
  - Local DataSource: **Drift** (SQLite with reactive streams on native, IndexedDB on Web).
  - Remote DataSource: `ApiClient` and `SyncService` connecting to the native Node.js backend.

### C. Backend Engine (Zero Express)
- **Runtime:** Node.js (ES Modules).
- **HTTP Server:** Pure `node:http` with custom asynchronous routing engine and chunked JSON body streaming.
- **Controller Layer:** Validates HTTP payloads, orchestrates service logic, and responds with standardized JSON envelopes.
- **Service Layer:** Houses security logic, cryptographic hashing (Argon2id), JWT rotation, and deterministic AI pattern analysis.
- **Repository Layer:** Encapsulates raw SQL queries strictly scoped to the authenticated user (`WHERE user_id = $1`).

---

## 2. Offline-First Cloud Synchronization Model

```
+-------------------------------------------------------------+
|                     Flutter Drift Storage                   |
| (Local source of truth for offline creation, edit, deletion)|
+------------------------------+------------------------------+
                               |
                   [SyncService.syncAll()]
                               |
                               v
+-------------------------------------------------------------+
|                       POST /sync/push                       |
|   - Unique Client Mutation IDs (Idempotent replay safe)     |
|   - Soft-deletion tombstones (deleted_at IS NOT NULL)       |
|   - Last-Write-Wins (LWW) conflict detection                |
+------------------------------+------------------------------+
                               |
                               v
+-------------------------------------------------------------+
|                       GET /sync/pull                        |
|   - Retrieves mutations where updated_at > lastSyncTimestamp|
|   - Updates Drift tables locally and stores new timestamp   |
+-------------------------------------------------------------+
```

---

## 3. Financial Money Rules

1. **Integer Minor Units:** All monetary amounts are recorded in minor currency units (cents, `BIGINT` in PostgreSQL, `IntColumn` in Drift). Floating-point arithmetic is forbidden in financial ledgers.
2. **Formula Integrity:** `Daily Savings = Daily Income - Daily Expenses`.
3. **Reserves Distinction:** Net calculated savings are strictly distinguished from actual savings deposits into designated reserve accounts.
4. **Loan Repayments Isolation:** Debt payments are recorded exclusively in `debt_payments` and reduce outstanding debt principal without inflating operational income or expenses.

---

## 4. AI Financial Assistant Architecture & Models

The AI diagnostic engine in DailySave provides spending pattern analysis, anomaly detection, and savings guidance while prioritizing **financial accuracy, privacy, and zero hallucination**.

### A. Core Architecture: Deterministic Statistical Intelligence
- **Implementation:** `backend/src/services/ai_assistant.service.js` and `backend/src/controllers/ai.controller.js`.
- **Algorithms:**
  1. **Rolling-Window Velocity & $\Delta\%$ Trend Detection:** Evaluates 30-day month-over-month rate of change to flag acceleration in total expenditure ($> 15\%$).
  2. **Pareto Category Concentration:** Analyzes category distribution to identify expenditure concentration (e.g., when a single discretionary category exceeds $40\%$ of monthly outflow).
  3. **Savings Ratio Classification:** Computes $R_{savings} = (Income - Expense) / Income$ into discrete financial health tiers (Deficit, Opportunity, Healthy).
- **Authoritative Data Grounding:** All metrics originate from ACID PostgreSQL aggregations using integer `amount_cents` (`BIGINT`).

### B. Technical Rationale
1. **Zero Hallucination:** Eliminates arithmetic errors and hallucinated transactions common in generative token predictors.
2. **Privacy & Data Sovereignty:** Prevents transmission of sensitive financial history to external third parties without user opt-in (`ai_consent_enabled`).
3. **Low-Resource & Offline Capability:** Runs in $<5\text{ ms}$ on local devices or resource-constrained servers.

### C. Advanced Local Machine Learning Roadmap
- **Time-Series Forecasting:** Facebook Prophet / Holt-Winters for predictive cashflow forecasting and seasonal Ethiopian holiday expenditure trends.
- **Unsupervised Anomaly Detection:** Isolation Forest and Local Outlier Factor (LOF) executed locally or on-premise without reliance on external cloud AI providers.
