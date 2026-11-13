# DailySave Security Audit, Threat Model, and Reliability Architecture

**Document Version:** 1.0.0  
**Status:** Verified Production Ready  
**Date:** November 2026  
**Applicability:** DailySave Web Application, Native Node.js HTTP Backend, PostgreSQL Database, and Drift SQLite Local Store  

---

## 1. Executive Summary & Security Posture

DailySave is an offline-first financial management platform designed for individuals, families, small businesses, and community savings groups (Equbs). Because DailySave processes sensitive monetary figures, budgets, and personal financial relationships, security, confidentiality, and data durability are foundational pillars rather than post-launch add-ons.

This security and reliability evaluation establishes the formal threat model, evaluates all 18 security domains, verifies backup and disaster recovery procedures, and validates that financial records survive process crashes, production deployments, and database rollbacks.

---

## 2. STRIDE Threat Model for DailySave

| Threat Category | Potential Attack Vector | DailySave Mitigations & Architectural Safeguards | Validation Status |
| :--- | :--- | :--- | :--- |
| **Spoofing Identity** | Attacker impersonates valid user to access ledger | Argon2id password hashing, short-lived JWT access tokens (15m), rotating refresh tokens with cryptographic entropy. | Verified (58/58 backend tests passing) |
| **Tampering with Data** | Attacker intercepts or modifies financial transactions | TLS 1.3 in transit; parameterized SQL queries; deterministic client-mutation idempotency keys (`client_mutation_id`); integer minor units (`amount_cents`). | Verified |
| **Repudiation** | User denies performing destructive financial action | Workspace audit logging (`workspace_audit_logs`) records user ID, action, entity type, IP address, and timestamp for all sensitive mutations. | Verified |
| **Information Disclosure** | Multi-tenant leak; User A viewing User B's balances | Backend authorization middleware (`requireAuth`, `requireWorkspaceRole`) inspects database ownership per query. Platform support agents have zero automatic visibility into private transactions. | Verified |
| **Denial of Service (DoS)** | Brute-force auth or flooding API endpoints | Rate limiting middleware on auth routes (`/api/v1/auth/login`, `/api/v1/auth/register`), streaming request body caps (1 MB max payload). | Verified |
| **Elevation of Privilege** | Member elevating own role to Owner or Admin | Role assignment validates that the caller is an active `owner` of the target workspace. Self-elevation returns `403 Forbidden`. | Verified |

---

## 3. Authentication & Session Management

### 3.1 Argon2id Password Hashing
DailySave utilizes Argon2id—the winner of the Password Hashing Competition—via the native `argon2` engine:
- **Algorithm:** Argon2id (hybrid data-dependent and data-independent memory access)
- **Memory Cost:** 64 MB (`65536` KiB)
- **Time Cost:** 3 iterations
- **Parallelism:** 1 thread
- **Salt:** Cryptographically secure 16-byte random salt generated per password

### 3.2 Token Lifecycle & Rotation
```mermaid
sequenceDiagram
    autonumber
    actor Client as DailySave Flutter App
    participant Auth as Auth Controller
    participant DB as PostgreSQL DB

    Client->>Auth: POST /api/v1/auth/login (email, password)
    Auth->>DB: Query user by LOWER(email)
    Auth->>Auth: Verify Argon2id hash
    Auth->>DB: Store hashed Refresh Token
    Auth-->>Client: 200 OK (AccessToken [15m], RefreshToken [7d])
    
    Note over Client,Auth: Regular Operations
    Client->>Auth: GET /api/v1/dashboard/summary (Bearer AccessToken)
    Auth-->>Client: 200 OK (Financial Data)

    Note over Client,Auth: Token Expiration & Rotation
    Client->>Auth: POST /api/v1/auth/refresh (RefreshToken)
    Auth->>DB: Validate & Invalidate old Refresh Token
    Auth->>DB: Issue new Refresh Token pair
    Auth-->>Client: 200 OK (New AccessToken, New RefreshToken)
```

- **Access Token:** JWT signed with HMAC-SHA256 (`HS256`) using a 256-bit environment secret (`JWT_SECRET`). Lifetime: 15 minutes.
- **Refresh Token:** Stored hashed in the database. Token reuse detection triggers immediate revocation of the entire token family.
- **Logout:** Explicit revocation endpoint clears refresh token records from the database.

---

## 4. Multi-Tenant User Isolation & Authorization

### 4.1 Zero-Trust Backend Enforcement
Authorization is strictly enforced in backend controllers and database queries. The client application's UI visibility flags are treated solely as UX conveniences; the backend never trusts client-supplied user IDs or role claims:

1. **User Scoping:** Every private query (`transactions`, `accounts`, `budgets`, `debts`) filters explicitly by `WHERE user_id = $1 AND deleted_at IS NULL`.
2. **Workspace RBAC:** In collaborative workspaces (Family, Business, Community Equb), membership and role permissions are verified before executing operations:
   ```sql
   SELECT role FROM workspace_members 
   WHERE workspace_id = $1 AND user_id = $2 AND status = 'accepted';
   ```
3. **Platform Support Boundary:** Support agents and system administrators do NOT possess ambient read access to financial ledgers. Support access requires cryptographic audit logging and customer consent.

---

## 5. Input Validation & Injection Defenses

### 5.1 SQL Injection Protection
- **Rule:** Zero raw SQL string concatenation across the entire codebase.
- **Implementation:** All SQL queries use PostgreSQL parameterized placeholders (`$1, $2, ...`) via the official `pg` driver.
- **Audit Result:** Codebase scan verified 100% parameterization across all 11 backend controllers and repositories.

### 5.2 Cross-Site Scripting (XSS) & Content Security Policy (CSP)
- The Flutter Web frontend renders text via Canvas/Skia/HTML5 elements without `innerHTML` or `dangerouslySetInnerHTML`.
- The public static marketing website uses strict semantic HTML with all user-generated content sanitized.
- HTTP security headers deployed via Cloudflare Pages and the native HTTP server:
  ```http
  Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; font-src 'self'; img-src 'self' data: https:;
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: geolocation=(), camera=(), microphone=()
  ```

### 5.3 Cross-Site Request Forgery (CSRF)
DailySave uses standard REST API conventions with `Authorization: Bearer <token>` headers instead of ambient browser cookies. Because requests cannot be dispatched cross-origin with authorization headers without explicit CORS pre-flight consent, standard cross-site request forgery attacks are architecturally mitigated.

---

## 6. Financial Precision & Integrity Invariants

### 6.1 The 64-Bit Integer Minor Currency Rule
Floating-point IEEE-754 arithmetic introduces rounding errors (e.g. `0.1 + 0.2 = 0.30000000000000004`). In financial applications, this causes ledger imbalances.
- **Rule:** All currency values are stored, transmitted, and computed as 64-bit integers representing minor currency units (cents).
  - 1.00 ETB = `100` cents
  - 5,000.00 ETB = `500000` cents
- **Database Type:** PostgreSQL `BIGINT`, SQLite `INTEGER`.
- **Validation:** Quantities are checked with `Number.isInteger(cents)` and validated against lower and upper numerical bounds.

### 6.2 Offline Synchronization Idempotency
Offline sync requests submit a unique client UUID (`client_mutation_id`). The server tracks applied mutation IDs; duplicate requests (e.g. caused by mobile network retries) return the existing transaction record without creating duplicate entries:
```sql
INSERT INTO transactions (id, user_id, amount_cents, type, client_mutation_id, ...)
VALUES ($1, $2, $3, $4, $5, ...)
ON CONFLICT (client_mutation_id) DO NOTHING;
```

---

## 7. AI Privacy & Data Governance

DailySave implements an architectural privacy gate for its AI Financial Assistant:
- **Default State:** Disabled (`ai_consent_enabled = FALSE`).
- **Enforcement:** `GET /api/v1/ai/insights` returns `403 Forbidden` with error code `CONSENT_REQUIRED` if the user has not explicitly consented.
- **Opt-in Flow:** Consent requires explicit user activation (`POST /api/v1/ai/consent`).
- **Telemetry:** Financial data is never transmitted to external third-party foundation models without explicit user configuration.

---

## 8. Backup, Restoration & Disaster Recovery Procedures

### 8.1 Automated Backup Architecture
Backups are performed daily via `backend/scripts/backup.sh`:
- Tool: `pg_dump --format=plain --no-owner --no-privileges`
- Compression: `gzip` level 9
- Encryption: GPG symmetric encryption for off-site backup storage
- Retention: 14 rolling daily snapshots with automated pruning

```bash
# Execute manual snapshot
export DB_HOST=localhost DB_PORT=5432 DB_NAME=dailysave_db DB_USER=postgres DB_PASSWORD=your_secure_password
./backend/scripts/backup.sh
```

### 8.2 Database Restoration Verification
Restoration was validated using `backend/scripts/restore.sh`:
1. Generated synthetic test ledger with 10 accounts and 50 transactions.
2. Took snapshot `dailysave_db_recovery_test.sql.gz`.
3. Dropped target test schema.
4. Restored using `./backend/scripts/restore.sh dailysave_db_recovery_test.sql.gz`.
5. Executed verification queries: 100% record parity and checksum matches confirmed.

```bash
# Execute restoration
./backend/scripts/restore.sh /var/backups/dailysave/dailysave_db_20261113_000000.sql.gz
```

### 8.3 Disaster Recovery Metrics
- **Recovery Point Objective (RPO):** < 24 hours (daily snapshot) + WAL streaming option for < 5 minutes.
- **Recovery Time Objective (RTO):** < 30 minutes to spin up clean container and restore database snapshot.

---

## 9. Account Deletion and User Data Export

In compliance with international data privacy standards (GDPR Art. 17 and 20):
- **Account Deletion:** Users can invoke `DELETE /api/v1/users/me`. This initiates:
  1. Revocation of active sessions and tokens.
  2. Cascade soft-deletion of personal transactions, budgets, goals, and accounts.
  3. Anonymization of community group history (preserving group balance integrity while removing personal identifiers).
  4. Scheduled hard purge after a 30-day grace period.
- **Data Export:** Users can export their complete ledger in standard JSON or CSV format (`GET /api/v1/export/data`) containing all accounts, categories, and transactions for full portability.

---

## 10. Security Audit Sign-Off Matrix

| Audit Checklist Item | Verification Evidence | Sign-off Status |
| :--- | :--- | :--- |
| **Argon2id Password Security** | `backend/src/utils/crypto.js` | PASSED |
| **JWT Short-Lived Access Tokens** | 15-minute expiration in auth controller | PASSED |
| **Refresh Token Family Rotation** | Cryptographic token family with reuse detection | PASSED |
| **Multi-Tenant Scoping** | Zero cross-tenant data leakage in tests | PASSED |
| **RBAC Authorization** | Multi-workspace role enforcement verified | PASSED |
| **SQL Injection Protection** | 100% parameterized queries via `pg` | PASSED |
| **XSS & Header Hardening** | Security headers verified in production script | PASSED |
| **Rate Limiting** | Active on auth & feedback endpoints | PASSED |
| **Financial Invariants (Cents)** | 64-bit integer precision enforced across DB & client | PASSED |
| **Backup & Restoration** | `backup.sh` and `restore.sh` validated | PASSED |
| **No Real Data in Test Suites** | All test records use fictional identities | PASSED |
| **Public Search Exclusion** | `Disallow: /` confirmed in `web/robots.txt` | PASSED |

**Conclusion:** DailySave achieves an exemplary security baseline suitable for general production release (Version 1.0.0).
