-- Migration 007: Workspaces, Multi-Tenant RBAC, Subscriptions & Entitlements
-- Enables 8 discrete role categories, multi-workspace isolation, and configurable subscriptions

-- 1. Workspaces Table
CREATE TABLE IF NOT EXISTS workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    type VARCHAR(30) NOT NULL DEFAULT 'personal', -- 'personal', 'family', 'business', 'community'
    currency VARCHAR(10) NOT NULL DEFAULT 'ETB',
    description TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_workspaces_owner ON workspaces(owner_id);
CREATE INDEX IF NOT EXISTS idx_workspaces_type ON workspaces(type);

-- 2. Workspace Members Table (Multi-User RBAC)
CREATE TABLE IF NOT EXISTS workspace_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'individual_user', 
    -- Roles: 'individual_user', 'family_owner', 'family_member', 'business_owner', 
    --        'business_accountant', 'business_staff', 'community_treasurer', 'community_member'
    permissions JSONB NOT NULL DEFAULT '[]'::jsonb,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_workspace_member UNIQUE(workspace_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_workspace_members_ws ON workspace_members(workspace_id);
CREATE INDEX IF NOT EXISTS idx_workspace_members_user ON workspace_members(user_id);
CREATE INDEX IF NOT EXISTS idx_workspace_members_role ON workspace_members(role);

-- 3. Workspace Invitations Table
CREATE TABLE IF NOT EXISTS workspace_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    invited_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'family_member',
    token VARCHAR(120) UNIQUE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'rejected', 'expired'
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_workspace_invitations_ws ON workspace_invitations(workspace_id);
CREATE INDEX IF NOT EXISTS idx_workspace_invitations_email ON workspace_invitations(email);
CREATE INDEX IF NOT EXISTS idx_workspace_invitations_token ON workspace_invitations(token);

-- 4. Subscriptions & Entitlements Table
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    plan VARCHAR(30) NOT NULL DEFAULT 'FREE', -- 'FREE', 'PLUS', 'FAMILY', 'BUSINESS', 'COMMUNITY'
    status VARCHAR(30) NOT NULL DEFAULT 'active', -- 'active', 'trialing', 'past_due', 'canceled', 'expired'
    billing_cycle VARCHAR(20) NOT NULL DEFAULT 'monthly', -- 'monthly', 'annual'
    current_period_start TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    current_period_end TIMESTAMPTZ NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 days'),
    cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
    grace_period_end TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_workspace_sub UNIQUE(user_id, workspace_id)
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_ws ON subscriptions(workspace_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan ON subscriptions(plan);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);

-- 5. Billing Invoices Table
CREATE TABLE IF NOT EXISTS billing_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount_cents BIGINT NOT NULL DEFAULT 0,
    currency VARCHAR(10) NOT NULL DEFAULT 'ETB',
    status VARCHAR(30) NOT NULL DEFAULT 'paid', -- 'paid', 'pending', 'failed', 'refunded'
    payment_provider VARCHAR(50) NOT NULL DEFAULT 'manual_eval', -- 'telebirr', 'chapa', 'cbe_birr', 'manual_eval'
    provider_transaction_id VARCHAR(150),
    invoice_pdf_url TEXT,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_invoices_user ON billing_invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_sub ON billing_invoices(subscription_id);

-- 6. Link Workspace to Existing Financial Ledger Tables
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE;
ALTER TABLE budgets ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE;
ALTER TABLE savings_goals ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE;
ALTER TABLE debts ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE;
ALTER TABLE recurring_transactions ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES workspaces(id) ON DELETE SET NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS platform_role VARCHAR(50) DEFAULT NULL; -- 'platform_admin', 'platform_support'

CREATE INDEX IF NOT EXISTS idx_transactions_ws ON transactions(workspace_id);
CREATE INDEX IF NOT EXISTS idx_accounts_ws ON accounts(workspace_id);
CREATE INDEX IF NOT EXISTS idx_budgets_ws ON budgets(workspace_id);
CREATE INDEX IF NOT EXISTS idx_goals_ws ON savings_goals(workspace_id);
CREATE INDEX IF NOT EXISTS idx_debts_ws ON debts(workspace_id);
CREATE INDEX IF NOT EXISTS idx_recurring_ws ON recurring_transactions(workspace_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_ws ON audit_logs(workspace_id);

-- 7. Backfill: Seed Default Personal Workspaces for Existing Users
DO $$
DECLARE
    u_record RECORD;
    ws_id UUID;
BEGIN
    FOR u_record IN SELECT id, email FROM users LOOP
        -- Check if user already has a personal workspace
        SELECT id INTO ws_id FROM workspaces WHERE owner_id = u_record.id AND type = 'personal' LIMIT 1;
        
        IF ws_id IS NULL THEN
            INSERT INTO workspaces (owner_id, name, type, currency, description)
            VALUES (u_record.id, 'Personal Workspace', 'personal', 'ETB', 'Default personal finance workspace')
            RETURNING id INTO ws_id;

            INSERT INTO workspace_members (workspace_id, user_id, role)
            VALUES (ws_id, u_record.id, 'individual_user')
            ON CONFLICT (workspace_id, user_id) DO NOTHING;

            INSERT INTO subscriptions (user_id, workspace_id, plan, status)
            VALUES (u_record.id, ws_id, 'FREE', 'active')
            ON CONFLICT (user_id, workspace_id) DO NOTHING;
        END IF;

        -- Attach legacy orphaned financial records to the user's default workspace
        UPDATE transactions SET workspace_id = ws_id WHERE user_id = u_record.id AND workspace_id IS NULL;
        UPDATE accounts SET workspace_id = ws_id WHERE user_id = u_record.id AND workspace_id IS NULL;
        UPDATE budgets SET workspace_id = ws_id WHERE user_id = u_record.id AND workspace_id IS NULL;
        UPDATE savings_goals SET workspace_id = ws_id WHERE user_id = u_record.id AND workspace_id IS NULL;
        UPDATE debts SET workspace_id = ws_id WHERE user_id = u_record.id AND workspace_id IS NULL;
        UPDATE recurring_transactions SET workspace_id = ws_id WHERE user_id = u_record.id AND workspace_id IS NULL;
    END LOOP;
END $$;
