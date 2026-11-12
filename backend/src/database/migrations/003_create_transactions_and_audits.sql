-- Migration 003: Authoritative Financial Transactions, Recurring Transactions, and Audit Logs
-- Enforces integer minor currency units (cents), idempotency keys, and synchronization flags

-- 7. Authoritative Financial Transactions Table
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    type VARCHAR(30) NOT NULL, -- 'income', 'expense', 'transfer', 'savingsDeposit', 'savingsWithdrawal'
    currency VARCHAR(10) NOT NULL DEFAULT 'ETB',
    category VARCHAR(100) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    date TIMESTAMPTZ NOT NULL,
    payment_method VARCHAR(50) NOT NULL DEFAULT 'Cash',
    account VARCHAR(100) NOT NULL DEFAULT 'Cash Wallet',
    notes TEXT NOT NULL DEFAULT '',
    receipt_path TEXT,
    sync_status VARCHAR(20) NOT NULL DEFAULT 'synced', -- 'pending', 'synced', 'conflict'
    idempotency_key VARCHAR(120) UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ -- Soft deletion tombstone for conflict resolution
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category);
CREATE INDEX IF NOT EXISTS idx_transactions_updated_at ON transactions(updated_at);
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, date);

-- 8. Recurring Transactions Table
CREATE TABLE IF NOT EXISTS recurring_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    type VARCHAR(30) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'ETB',
    category VARCHAR(100) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    recurrence_interval VARCHAR(20) NOT NULL, -- 'daily', 'weekly', 'monthly', 'annual'
    next_execution_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_recurring_user_id ON recurring_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_recurring_next_exec ON recurring_transactions(next_execution_date);

-- 9. Security & Compliance Audit Logs Table
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL, -- 'LOGIN', 'LOGOUT', 'TRANSACTION_CREATE', 'TRANSACTION_DELETE', etc.
    entity_type VARCHAR(50),
    entity_id VARCHAR(100),
    payload_json JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);
