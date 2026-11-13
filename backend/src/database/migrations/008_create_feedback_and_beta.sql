-- Migration 008: Beta Feedback, Bug Reports & User Satisfaction Surveys
-- Facilitates structured Alpha/Beta feedback collection without exposing private financial logs

CREATE TABLE IF NOT EXISTS beta_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    type VARCHAR(30) NOT NULL DEFAULT 'feedback', -- 'bug_report', 'feedback', 'satisfaction_survey'
    category VARCHAR(50) NOT NULL DEFAULT 'general', -- 'general', 'accessibility', 'sync', 'equb', 'performance', 'localization'
    rating INT CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5)),
    message TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    status VARCHAR(20) NOT NULL DEFAULT 'new', -- 'new', 'in_review', 'resolved', 'closed'
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_feedback_type ON beta_feedback(type);
CREATE INDEX IF NOT EXISTS idx_feedback_category ON beta_feedback(category);
CREATE INDEX IF NOT EXISTS idx_feedback_status ON beta_feedback(status);
CREATE INDEX IF NOT EXISTS idx_feedback_created_at ON beta_feedback(created_at);
