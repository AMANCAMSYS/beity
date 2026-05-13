-- Create beta_feedback table for user-submitted feedback and satisfaction surveys
CREATE TABLE IF NOT EXISTS public.beta_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  feedback_type text NOT NULL CHECK (feedback_type IN ('bug', 'survey')),
  description text NOT NULL CHECK (char_length(description) >= 1 AND char_length(description) <= 2000),
  star_rating smallint CHECK (star_rating IS NULL OR (star_rating >= 1 AND star_rating <= 5)),
  device_info jsonb NOT NULL DEFAULT '{}',
  screen_route text,
  app_logs text[],
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT survey_requires_rating CHECK (
    feedback_type != 'survey' OR star_rating IS NOT NULL
  ),
  CONSTRAINT bug_no_rating CHECK (
    feedback_type != 'bug' OR star_rating IS NULL
  )
);

-- Enable RLS
ALTER TABLE public.beta_feedback ENABLE ROW LEVEL SECURITY;

-- Index for team dashboard queries
CREATE INDEX idx_beta_feedback_created_at ON public.beta_feedback (created_at DESC);

-- RLS Policies
-- Authenticated users can insert their own feedback
CREATE POLICY "Users can insert own feedback"
  ON public.beta_feedback
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Only service role can read (team access via dashboard)
CREATE POLICY "Service role can read feedback"
  ON public.beta_feedback
  FOR SELECT
  TO service_role
  USING (true);

-- Grant access to authenticated role for insert
GRANT INSERT ON public.beta_feedback TO authenticated;
GRANT SELECT ON public.beta_feedback TO service_role;
