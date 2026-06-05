ALTER TABLE public.device_tokens
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id);

UPDATE public.device_tokens
SET created_by = COALESCE(created_by, user_id),
    updated_by = COALESCE(updated_by, user_id)
WHERE created_by IS NULL
   OR updated_by IS NULL;

CREATE INDEX IF NOT EXISTS idx_device_tokens_active_user
  ON public.device_tokens (user_id)
  WHERE is_active = true;
