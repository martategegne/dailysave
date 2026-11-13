# Workspace Architecture & Multi-Tenant Data Isolation

DailySave organizes all financial entities within an isolated **Workspace Container Model**. Workspaces establish boundaries for transactions, accounts, budgets, goals, and membership permissions.

---

## 1. Workspace Types

```
                                  +---------------------------+
                                  |     Authenticated User    |
                                  +-------------+-------------+
                                                |
                 +-------------------+----------+----------+-------------------+
                 |                   |                     |                   |
                 v                   v                     v                   v
        +-----------------+ +-----------------+   +-----------------+ +-----------------+
        |    Personal     | |     Family      |   |    Business     | |    Community    |
        |    Workspace    | |    Workspace    |   |    Workspace    | | (Equb Circle)   |
        +-----------------+ +-----------------+   +-----------------+ +-----------------+
        | Single User     | | Household Pool  |   | Merchant Ops    | | Rotating ROSCA  |
        | 100% Private    | | Shared Budgets  |   | Staff / Cashier | | Contribution Log|
        +-----------------+ +-----------------+   +-----------------+ +-----------------+
```

1. **Personal Workspace (`personal`):** Default private ledger for individual financial tracking. Cannot be deleted.
2. **Family Workspace (`family`):** Shared household environment where parents manage shared category allocations while children or extended family track expenses.
3. **Business Workspace (`business`):** Merchant accounting environment separating operational sales turnover from personal savings, granting staff cashier roles and external accountants audit access.
4. **Community Workspace (`community`):** Rotating Equb circle coordinating contribution turns, payouts, and communal meeting expenses.

---

## 2. Database Schema & Relational Integrity

Every financial record links directly to `workspace_id`:

```sql
-- Workspaces Table
CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    type VARCHAR(30) NOT NULL DEFAULT 'personal',
    currency VARCHAR(10) NOT NULL DEFAULT 'ETB',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

-- Workspace Membership Table
CREATE TABLE workspace_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'individual_user',
    permissions JSONB NOT NULL DEFAULT '[]'::jsonb,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_workspace_member UNIQUE(workspace_id, user_id)
);
```

### Foreign Key Cascades:
* `transactions.workspace_id REFERENCES workspaces(id) ON DELETE CASCADE`
* `accounts.workspace_id REFERENCES workspaces(id) ON DELETE CASCADE`
* `budgets.workspace_id REFERENCES workspaces(id) ON DELETE CASCADE`
* `savings_goals.workspace_id REFERENCES workspaces(id) ON DELETE CASCADE`

---

## 3. Membership & Invitation Lifecycle

1. **Invitation Generation:** An authorized member with `invite_members` permission submits an email and role. A cryptographically random token (`inv_<hash>_<timestamp>`) is generated with a 72-hour expiration.
2. **Token Acceptance:** When the recipient accepts (`POST /workspaces/invitations/:token/accept`), the user is bound to the workspace with the specified role.
3. **Role Updates:** Workspace owners or admins with `manage_roles` can change member roles. Self-privilege escalation is strictly forbidden.
4. **Ownership Transfer:** A workspace owner can explicitly transfer workspace ownership to another active member.
5. **Soft Deletion:** Deleting a workspace sets `deleted_at`, removing it from active queries while preserving audit integrity.
