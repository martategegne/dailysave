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
