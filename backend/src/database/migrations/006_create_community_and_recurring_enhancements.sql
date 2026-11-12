-- Migration 006: Community Savings Groups & Recurring Enhancements
-- Strictly informational/organizational, zero private transaction leaks

-- 1. Recurring Transaction Enhancements
ALTER TABLE recurring_transactions ADD COLUMN IF NOT EXISTS account VARCHAR(100) NOT NULL DEFAULT 'Cash Wallet';
ALTER TABLE recurring_transactions ADD COLUMN IF NOT EXISTS last_executed_date DATE;
ALTER TABLE recurring_transactions ADD COLUMN IF NOT EXISTS requires_review BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS ai_consent_enabled BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. Community Groups Table
CREATE TABLE IF NOT EXISTS community_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    currency VARCHAR(10) NOT NULL DEFAULT 'ETB',
    target_amount_cents BIGINT NOT NULL DEFAULT 0,
    contribution_frequency VARCHAR(30) NOT NULL DEFAULT 'monthly', -- 'daily', 'weekly', 'monthly', 'custom'
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_comm_groups_creator ON community_groups(creator_id);

-- 3. Community Group Members Table (Role-based access)
CREATE TABLE IF NOT EXISTS community_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES community_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'member', -- 'creator', 'admin', 'treasurer', 'member'
    joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_group_user UNIQUE(group_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_comm_members_group ON community_members(group_id);
CREATE INDEX IF NOT EXISTS idx_comm_members_user ON community_members(user_id);

-- 4. Community Group Collective Contributions
CREATE TABLE IF NOT EXISTS community_contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES community_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_comm_contrib_group ON community_contributions(group_id);
CREATE INDEX IF NOT EXISTS idx_comm_contrib_user ON community_contributions(user_id);

-- 5. Community Group Shared Expenses
CREATE TABLE IF NOT EXISTS community_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES community_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    category VARCHAR(100) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_comm_expenses_group ON community_expenses(group_id);
