-- Keep the repo migration history aligned with the live notification schema,
-- and tighten preference access so users can only touch homes they belong to.

ALTER TABLE public.notification_preferences
  ADD COLUMN IF NOT EXISTS task_assigned boolean DEFAULT true;

UPDATE public.notification_preferences
SET task_assigned = true
WHERE task_assigned IS NULL;

ALTER TABLE public.notification_preferences
  ALTER COLUMN task_assigned SET DEFAULT true,
  ALTER COLUMN task_assigned SET NOT NULL;

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS locale text DEFAULT 'ar';

ALTER TABLE public.users
  ALTER COLUMN locale SET DEFAULT 'ar';

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

ALTER TABLE public.notifications
  ALTER COLUMN updated_at SET DEFAULT now();

DROP TRIGGER IF EXISTS set_notifications_updated_at ON public.notifications;
CREATE TRIGGER set_notifications_updated_at
BEFORE UPDATE ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION extensions.moddatetime('updated_at');

DROP POLICY IF EXISTS "Users can delete own notification preferences" ON public.notification_preferences;
DROP POLICY IF EXISTS "Users can insert own notification preferences" ON public.notification_preferences;
DROP POLICY IF EXISTS "Users can update own notification preferences" ON public.notification_preferences;
DROP POLICY IF EXISTS "Users can view own notification preferences" ON public.notification_preferences;

CREATE POLICY "Users can delete own notification preferences"
ON public.notification_preferences
FOR DELETE
USING (
  user_id = auth.uid()
  AND public.is_home_member(home_id)
);

CREATE POLICY "Users can insert own notification preferences"
ON public.notification_preferences
FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND public.is_home_member(home_id)
);

CREATE POLICY "Users can update own notification preferences"
ON public.notification_preferences
FOR UPDATE
USING (
  user_id = auth.uid()
  AND public.is_home_member(home_id)
)
WITH CHECK (
  user_id = auth.uid()
  AND public.is_home_member(home_id)
);

CREATE POLICY "Users can view own notification preferences"
ON public.notification_preferences
FOR SELECT
USING (
  user_id = auth.uid()
  AND public.is_home_member(home_id)
);
