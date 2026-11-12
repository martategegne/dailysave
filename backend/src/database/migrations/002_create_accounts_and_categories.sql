-- Migration 002: Accounts and Categories
-- Supports Cash, Bank, Mobile Money, Savings, and Custom accounts
-- Supports System Defaults and User-defined Categories

-- 5. Accounts Table
CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    account_type VARCHAR(30) NOT NULL, -- 'cash', 'bank', 'mobile_money', 'savings', 'custom'
    currency VARCHAR(10) NOT NULL DEFAULT 'ETB',
    initial_balance_cents BIGINT NOT NULL DEFAULT 0,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_account_name UNIQUE(user_id, name)
);

CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);

-- 6. Transaction Categories Table
CREATE TABLE IF NOT EXISTS transaction_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE, -- NULL indicates global system category
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'income' or 'expense'
    color_hex VARCHAR(10) NOT NULL DEFAULT '#16865B',
    is_custom BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_categories_user_id ON transaction_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_type ON transaction_categories(type);

-- Seed System Default Categories if not present
INSERT INTO transaction_categories (name, type, color_hex, is_custom)
VALUES
    ('Salary', 'income', '#16A34A', false),
    ('Freelancing', 'income', '#16A34A', false),
    ('Business', 'income', '#16A34A', false),
    ('Tutoring', 'income', '#16A34A', false),
    ('Allowance', 'income', '#16A34A', false),
    ('Gifts', 'income', '#16A34A', false),
    ('Investments', 'income', '#16A34A', false),
    ('Rental income', 'income', '#16A34A', false),
    ('Other', 'income', '#16A34A', false),
    ('Food', 'expense', '#DC2626', false),
    ('Transportation', 'expense', '#DC2626', false),
    ('Education', 'expense', '#DC2626', false),
    ('Housing', 'expense', '#DC2626', false),
    ('Electricity', 'expense', '#DC2626', false),
    ('Water', 'expense', '#DC2626', false),
    ('Healthcare', 'expense', '#DC2626', false),
    ('Communication', 'expense', '#DC2626', false),
    ('Internet', 'expense', '#DC2626', false),
    ('Entertainment', 'expense', '#DC2626', false),
    ('Clothing', 'expense', '#DC2626', false),
    ('Shopping', 'expense', '#DC2626', false),
    ('Family support', 'expense', '#DC2626', false),
    ('Personal care', 'expense', '#DC2626', false),
    ('Other', 'expense', '#DC2626', false)
ON CONFLICT DO NOTHING;
