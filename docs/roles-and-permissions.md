# Role-Based Access Control (RBAC) & Permission Matrix

DailySave enforces **workspace-based, multi-tenant Role-Based Access Control (RBAC)** across both its native Node.js backend and local Drift storage layer. Authorization is validated on every API request at the server level, never relying on client UI visibility alone.

---

## 1. The Eight Role Categories

A user can belong to multiple workspaces simultaneously and hold different roles across each workspace:

| # | Role Key | Role Name | Intended Context | Core Authority |
| :- | :--- | :--- | :--- | :--- |
| 1 | `individual_user` | Individual User | Personal Workspace | Complete owner of personal transactions, budgets, accounts, and exports. |
| 2 | `family_owner` | Family Owner | Family Workspace | Administrator of household budgets, accounts, member invitations, and roles. |
| 3 | `family_member` | Family Member | Family Workspace | Records expenses/income, views household budgets and reports. Cannot delete accounts or invite users. |
| 4 | `business_owner` | Business Owner | Business Workspace | Complete commercial authority: merchant accounts, staff roles, billing, and statements. |
| 5 | `business_accountant` | Accountant / Bookkeeper | Business Workspace | Prepares taxes, edits ledgers, views cash flow, exports CSV/PDF. Cannot delete transactions or alter roles. |
| 6 | `business_staff` | Cashier / Sales Staff | Business Workspace | Records daily sales receipts and operational expenses. Cannot view profit/loss reports or export data. |
| 7 | `community_treasurer` | Equb Treasurer / Admin | Community Workspace | Records member contributions, manages communal expenses, audits pool. No access to private personal data. |
| 8 | `community_member` | Equb Participant | Community Workspace | Views communal pool summaries, contribution schedules, and shared expenses. Private ledgers are strictly isolated. |
| - | `platform_admin` | Platform Administrator | Global System | Audits platform health, manages users, views aggregated MRR. **NO automatic ledger access.** |
| - | `platform_support` | Support Agent | Global System | Assists with account recovery and technical support. **STRICTLY FORBIDDEN from viewing customer finances.** |

---

## 2. Authoritative Permission Matrix

The application checks granular permissions using `hasPermission(role, permission)`:

| Permission Key | Description | `individual_user` | `family_owner` | `family_member` | `business_owner` | `business_accountant` | `business_staff` | `community_treasurer` | `community_member` |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `view_financial_info` | View ledger & transactions | ✔ | ✔ | ✔ | ✔ | ✔ | ✖ | ✖ | ✖ |
| `create_transactions` | Record new transactions | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✖ | ✖ |
| `edit_transactions` | Modify existing records | ✔ | ✔ | ✖ | ✔ | ✔ | ✖ | ✖ | ✖ |
| `delete_transactions` | Soft-delete transactions | ✔ | ✔ | ✖ | ✔ | ✖ | ✖ | ✖ | ✖ |
| `manage_accounts` | Add CBE, Telebirr wallets | ✔ | ✔ | ✖ | ✔ | ✖ | ✖ | ✖ | ✖ |
| `manage_budgets` | Set category limits | ✔ | ✔ | ✔ | ✔ | ✔ | ✖ | ✖ | ✖ |
| `manage_goals` | Define savings targets | ✔ | ✔ | ✔ | ✔ | ✖ | ✖ | ✖ | ✖ |
| `view_reports` | Monthly cashflow summaries | ✔ | ✔ | ✔ | ✔ | ✔ | ✖ | ✔ | ✔ |
| `export_data` | Download CSV & PDF ledgers | ✔ | ✔ | ✖ | ✔ | ✔ | ✖ | ✔ | ✖ |
| `invite_members` | Send invitation tokens | ✖ | ✔ | ✖ | ✔ | ✖ | ✖ | ✔ | ✖ |
| `manage_roles` | Modify member role assignments | ✖ | ✔ | ✖ | ✔ | ✖ | ✖ | ✖ | ✖ |
| `manage_group_contributions`| Record Equb deposits | ✖ | ✖ | ✖ | ✖ | ✖ | ✖ | ✔ | ✖ |
| `manage_group_expenses`| Record shared pool expenses | ✖ | ✖ | ✖ | ✖ | ✖ | ✖ | ✔ | ✖ |
| `manage_subscriptions` | Upgrade/downgrade plans | ✔ | ✔ | ✖ | ✔ | ✖ | ✖ | ✖ | ✖ |

---

## 3. Strict Security Guardrails

### A. Platform Support Zero-Snooping Invariant
> [!IMPORTANT]
> Neither `platform_support` nor `platform_admin` agents possess automatic access to inspect private customer transaction records or account balances.
> Attempting to query financial data without explicit workspace membership returns:
> `HTTP 403 Forbidden: Access Denied: Platform support agents are prohibited from viewing private customer financial records.`

### B. Self-Privilege Elevation Defense
Members cannot assign themselves higher roles or modify their own workspace permissions (`adminUserId === memberUserId` returns `HTTP 400`).

### C. Compliance Audit Logging
All sensitive administrative actions are permanently logged in `audit_logs`:
* `WORKSPACE_CREATED` / `WORKSPACE_DELETED`
* `MEMBER_INVITED` / `MEMBER_JOINED` / `MEMBER_REMOVED`
* `MEMBER_ROLE_CHANGED`
* `WORKSPACE_OWNERSHIP_TRANSFERRED`
* `SUBSCRIPTION_PLAN_CHANGED`
