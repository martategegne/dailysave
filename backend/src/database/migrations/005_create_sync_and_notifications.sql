-- Migration 005: Notifications and Offline Synchronization Operations
-- Supports conflict detection, idempotency tracking, and mutation logs

-- 15. In-App Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'info', -- 'info', 'budget_warning', 'goal_milestone', 'debt_reminder'
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    metadata_json JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- 16. Synchronization Operations Log Table (Idempotency & Conflict Resolution)
CREATE TABLE IF NOT EXISTS sync_operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    client_mutation_id VARCHAR(120) NOT NULL,
    entity_type VARCHAR(50) NOT NULL, -- 'transaction', 'budget', 'goal', 'debt'
    entity_id VARCHAR(100) NOT NULL,
    operation_type VARCHAR(20) NOT NULL, -- 'insert', 'update', 'delete'
    client_timestamp TIMESTAMPTZ NOT NULL,
    server_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) NOT NULL DEFAULT 'applied', -- 'applied', 'conflict_resolved', 'rejected'
    conflict_resolution_json JSONB,
    CONSTRAINT uq_user_mutation UNIQUE(user_id, client_mutation_id)
);

CREATE INDEX IF NOT EXISTS idx_sync_ops_user_id ON sync_operations(user_id);
CREATE INDEX IF NOT EXISTS idx_sync_ops_entity ON sync_operations(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_sync_ops_server_time ON sync_operations(server_timestamp);
