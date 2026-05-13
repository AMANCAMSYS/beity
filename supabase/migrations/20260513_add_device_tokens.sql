-- Device Tokens Migration
-- Stores FCM tokens for push notifications

CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform VARCHAR(20) NOT NULL DEFAULT 'flutter',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, token)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_token ON device_tokens(token);

-- RLS
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own device tokens"
ON device_tokens FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert own device tokens"
ON device_tokens FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own device tokens"
ON device_tokens FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own device tokens"
ON device_tokens FOR DELETE
USING (user_id = auth.uid());

-- Service role can read all tokens (for sending notifications)
CREATE POLICY "Service can read all device tokens"
ON device_tokens FOR SELECT
USING (TRUE);

-- Trigger for updated_at
CREATE TRIGGER set_device_tokens_updated_at
BEFORE UPDATE ON device_tokens
FOR EACH ROW
EXECUTE FUNCTION moddatetime(updated_at);
