-- Shopping Mode Sessions Migration
-- Creates shopping_mode_sessions table with RLS policies

-- ============================================================
-- 1. shopping_mode_sessions table
-- ============================================================

CREATE TABLE IF NOT EXISTS shopping_mode_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shopping_list_id UUID NOT NULL REFERENCES shopping_lists(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
  started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  items_purchased_count INT NOT NULL DEFAULT 0,
  items_total_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_shopping_mode_sessions_list ON shopping_mode_sessions(shopping_list_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_shopping_mode_sessions_user ON shopping_mode_sessions(user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_shopping_mode_sessions_active ON shopping_mode_sessions(user_id, ended_at) WHERE ended_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_shopping_mode_sessions_home ON shopping_mode_sessions(home_id, started_at DESC);

-- RLS
ALTER TABLE shopping_mode_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view sessions in their home"
ON shopping_mode_sessions FOR SELECT
USING (home_id IN (SELECT home_id FROM home_members WHERE user_id = auth.uid()));

CREATE POLICY "Users can create sessions in their home"
ON shopping_mode_sessions FOR INSERT
WITH CHECK (
  home_id IN (SELECT home_id FROM home_members WHERE user_id = auth.uid())
  AND user_id = auth.uid()
);

CREATE POLICY "Users can update own sessions"
ON shopping_mode_sessions FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Trigger for updated_at
CREATE TRIGGER set_shopping_mode_sessions_updated_at
BEFORE UPDATE ON shopping_mode_sessions
FOR EACH ROW
EXECUTE FUNCTION moddatetime(updated_at);
