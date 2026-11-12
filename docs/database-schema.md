# DailySave Database Schema & Data Dictionary

DailySave utilizes **PostgreSQL 18** on the cloud backend and **Drift (SQLite / IndexedDB)** on the Flutter client.

---

## 1. Domain Tables Overview

| Table Name | Description | Constraints & Key Columns |
| :--- | :--- | :--- |
| `users` | Primary user identity records | `id UUID PK`, `email VARCHAR UNIQUE`, `password_hash TEXT` |
| `user_profiles` | Personal details | `user_id UUID FK`, `full_name VARCHAR(150)`, `phone_number` |
| `user_preferences` | User settings | `user_id UUID FK UNIQUE`, `default_currency`, `language`, `theme_mode`, `ai_consent_enabled` |
| `refresh_tokens` | Rotating token records | `user_id UUID FK`, `token_hash VARCHAR UNIQUE`, `expires_at`, `is_revoked` |
| `accounts` | Wallets and bank accounts | `user_id UUID FK`, `name`, `account_type`, `initial_balance_cents`, `currency` |
| `transaction_categories` | Income & expense categories | `user_id UUID FK NULL` (NULL = global system category), `name`, `type`, `color_hex` |
| `transactions` | Authoritative financial ledger | `user_id UUID FK`, `amount_cents BIGINT > 0`, `type`, `category`, `date`, `idempotency_key`, `deleted_at` |
| `recurring_transactions`| Automated scheduled bills | `user_id UUID FK`, `amount_cents`, `recurrence_interval`, `next_execution_date`, `requires_review` |
| `savings_goals` | Financial targets | `user_id UUID FK`, `target_amount_cents`, `current_amount_cents`, `deadline`, `is_completed` |
| `savings_contributions`| Goal deposits history | `goal_id UUID FK`, `user_id UUID FK`, `amount_cents`, `date`, `source_account` |
| `budgets` | Budget spending caps | `user_id UUID FK`, `amount_cents`, `period`, `warning_threshold_percent`, `danger_threshold_percent` |
| `debts` | Loans borrowed vs lent | `user_id UUID FK`, `person_name`, `debt_type`, `initial_amount_cents`, `remaining_amount_cents`, `is_settled` |
| `debt_payments` | Isolated repayments | `debt_id UUID FK`, `user_id UUID FK`, `amount_cents`, `payment_date` |
| `community_groups` | Equb / savings circles | `creator_id UUID FK`, `name`, `target_amount_cents`, `contribution_frequency` |
| `community_members` | Group member roles | `group_id UUID FK`, `user_id UUID FK`, `role ('creator', 'admin', 'treasurer', 'member')` |
| `community_contributions` | Shared pool deposits | `group_id UUID FK`, `user_id UUID FK`, `amount_cents`, `date` |
| `community_expenses` | Shared pool expenditures | `group_id UUID FK`, `user_id UUID FK`, `amount_cents`, `category` |
| `notifications` | In-app alerts | `user_id UUID FK`, `title`, `message`, `type`, `is_read`, `metadata_json` |
| `sync_operations` | Offline sync idempotency | `user_id UUID FK`, `client_mutation_id VARCHAR UNIQUE`, `entity_type`, `status` |
| `audit_logs` | Security activity logs | `user_id UUID FK`, `action`, `ip_address`, `user_agent`, `created_at` |

---

## 2. Versioned Migration History

1. **`001_create_users_and_auth.sql`**: Core user accounts, profiles, preferences, and refresh token rotation table.
2. **`002_create_accounts_and_categories.sql`**: Wallets, bank accounts, and default income/expense taxonomy.
3. **`003_create_transactions_and_audits.sql`**: Authoritative minor-unit financial ledger, recurring schedule base, and audit trails.
4. **`004_create_budgets_goals_debts.sql`**: Budgets with thresholds, goals with atomic contributions, and debts with isolated repayments.
5. **`005_create_sync_and_notifications.sql`**: In-app notifications table and sync operations idempotency logs.
6. **`006_create_community_and_recurring_enhancements.sql`**: Community savings groups, members, contributions, and recurring transaction review flags.
