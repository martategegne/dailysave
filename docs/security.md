# DailySave Privacy & Security Review

This document provides a transparent, honest overview of the security architecture, threat mitigations, and known limitations of the DailySave platform.

---

## 1. Authentication & Session Management

- **Password Hashing:** **Argon2id** (`argon2`), memory-hard algorithm resisting ASIC/GPU cracking (time cost: 3 iterations, memory cost: 64MB).
- **Access Tokens:** Short-lived JSON Web Tokens (15-minute validity) signed using high-entropy HMAC-SHA256 secrets.
- **Refresh Token Rotation:** High-entropy random tokens with 30-day validity.
  - Refresh tokens are stored **hashed (SHA-256)** in PostgreSQL; the raw token is never stored in the database.
  - **Theft Detection:** When a refresh token is rotated, it is marked `is_revoked = TRUE`. If a revoked token is presented again, the system detects a token reuse attack and immediately invalidates all active sessions for that user (`revokeAllUserTokens`).

---

## 2. Multi-Tenant Data Isolation

- Every SQL query across the application explicitly scopes operations using the authenticated user identity:
  `WHERE user_id = $1`
- Direct object references (e.g., `/transactions/:id`) always enforce `WHERE user_id = $1 AND id = $2`.
- Attempting to access another user's record returns `404 Not Found` to prevent account ID enumeration.

---

## 3. Web & Browser Security Limitations (Flutter Web)

- **Browser Storage:**
  - Tokens stored in browser `localStorage` or `IndexedDB` on Web are accessible to scripts on the same origin.
  - **Mitigation:**
    1. Zero backend secrets, database passwords, or signing keys are embedded in the Flutter bundle.
    2. Short-lived access tokens limit exposure if an XSS attack occurs.
    3. Production Nginx enforces strict Content Security Policy (`CSP`), `X-Frame-Options: DENY`, and `X-Content-Type-Options: nosniff`.

---

## 4. Community Groups Privacy Protections

- Community savings groups (Equb / savings circles) **never expose individual members' private accounts, personal transactions, or personal balances**.
- Only collective contributions explicitly made to that specific group pool are visible to group members.
- The platform is strictly an **informational and organizational ledger**; it does not hold custodial funds or transfer money.

---

## 5. AI Assistant Privacy Gate

- The AI assistant requires explicit, opt-in user consent (`ai_consent_enabled`).
- No sensitive personal financial data is analyzed or transmitted without user opt-in.
- Recommendations are deterministic, grounded in real calculations, and clearly labeled as informational suggestions.

---

## 6. Audit Logging & Compliance

- Security-sensitive actions (login, password change, account export, account deletion) are recorded in `audit_logs` with timestamps, IP addresses, and user-agent strings.
- Complete data export (`GET /api/v1/auth/export`) and complete data deletion (`DELETE /api/v1/auth/me`) provide GDPR/privacy compliance.
