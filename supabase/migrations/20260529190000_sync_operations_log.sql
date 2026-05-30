-- SQL Migration: Add sync_operations_log table for server-side idempotency
-- Created at: 2026-05-29

CREATE TABLE IF NOT EXISTS public.sync_operations_log (
  idempotency_key UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  operation_type TEXT NOT NULL,
  executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Enable RLS
ALTER TABLE public.sync_operations_log ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to insert/view their own sync logs
CREATE POLICY "Users can insert their own sync logs" ON public.sync_operations_log
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own sync logs" ON public.sync_operations_log
  FOR SELECT USING (auth.uid() = user_id);

-- Grant permissions to authenticated roles
GRANT ALL ON TABLE public.sync_operations_log TO authenticated;
GRANT ALL ON TABLE public.sync_operations_log TO service_role;
