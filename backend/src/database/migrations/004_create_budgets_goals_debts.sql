-- Migration 004: Budgets, Goals, Contributions, Debts, and Debt Payments
-- Enforces integer minor currency units, threshold percentages, and isolation of loan payments

-- 10. Savings Goals Table
CREATE TABLE IF NOT EXISTS savings_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    target_amount_cents BIGINT NOT NULL CHECK (target_amount_cents > 0),
    current_amount_cents BIGINT NOT NULL DEFAULT 0,
    currency VARCHAR(10) NOT NULL DEFAULT 'ETB',
    deadline DATE NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_goals_user_id ON savings_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_deadline ON savings_goals(deadline);

-- 11. Savings Contributions Table
CREATE TABLE IF NOT EXISTS savings_contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID NOT NULL REFERENCES savings_goals(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    date TIMESTAMPTZ NOT NULL,
    notes TEXT NOT NULL DEFAULT '',
    source_account VARCHAR(100) NOT NULL DEFAULT 'Cash Wallet',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_contributions_goal_id ON savings_contributions(goal_id);
CREATE INDEX IF NOT EXISTS idx_contributions_user_id ON savings_contributions(user_id);

-- 12. Budgets Table
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    period VARCHAR(20) NOT NULL, -- 'daily', 'weekly', 'monthly', 'custom'
    category VARCHAR(100), -- NULL indicates an overall budget across all categories
    start_date DATE NOT NULL,
    end_date DATE,
    warning_threshold_percent INT NOT NULL DEFAULT 75,
    danger_threshold_percent INT NOT NULL DEFAULT 90,
    critical_threshold_percent INT NOT NULL DEFAULT 100,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id);
CREATE INDEX IF NOT EXISTS idx_budgets_period ON budgets(period);

-- 13. Debts Table (Money Borrowed vs Money Lent)
CREATE TABLE IF NOT EXISTS debts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    person_name VARCHAR(150) NOT NULL,
    debt_type VARCHAR(20) NOT NULL, -- 'borrowed' or 'lent'
    initial_amount_cents BIGINT NOT NULL CHECK (initial_amount_cents > 0),
    remaining_amount_cents BIGINT NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'ETB',
    due_date DATE,
    description TEXT NOT NULL DEFAULT '',
    is_settled BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_debts_user_id ON debts(user_id);
CREATE INDEX IF NOT EXISTS idx_debts_settled ON debts(is_settled);

-- 14. Debt Payments Table (Repayments isolated from ordinary operational income/expenses)
CREATE TABLE IF NOT EXISTS debt_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    debt_id UUID NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    payment_date TIMESTAMPTZ NOT NULL,
    payment_method VARCHAR(50) NOT NULL DEFAULT 'Cash',
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_debt_payments_debt_id ON debt_payments(debt_id);
CREATE INDEX IF NOT EXISTS idx_debt_payments_user_id ON debt_payments(user_id);
